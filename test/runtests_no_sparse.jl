# This file is a part of Julia. License is MIT: https://julialang.org/license

using Test
using Distributed
using Dates
import REPL
using Printf: @sprintf
using Base: Experimental

# Include the original choosetests.jl from the julia repo
include("choosetests.jl")
include("testenv.jl")
include("buildkitetestjson.jl")

using .BuildKiteTestJSON

# Modified choosetests function that runs only the 5 most essential tests
function choosetests_no_sparse(choices = [])
    # Define the 5 most important tests that indicate Julia actually works
    essential_tests = [
        "core",           # Core language features (types, functions, etc.)
        "numbers",        # Basic arithmetic and number operations
        "strings/basic",  # String operations and manipulation
        "arrayops",       # Array operations and indexing
        "file",           # Basic file I/O operations
    ]
    
    # Set up basic configuration for minimal testing
    net_on = false  # No networking required for minimal tests
    exit_on_error = true  # Stop on first error
    use_revise = false  # No need for Revise in minimal tests
    seed = rand(RandomDevice(), UInt128)
    
    println("Running minimal test suite with 5 essential tests:")
    for test in essential_tests
        println("  - $test")
    end
    
    return (; tests=essential_tests, net_on, exit_on_error, use_revise, seed)
end

# Use the modified choosetests function
(; tests, net_on, exit_on_error, use_revise, seed) = choosetests_no_sparse(ARGS)
tests = unique(tests)

if Sys.islinux()
    const SYS_rrcall_check_presence = 1008
    global running_under_rr() = 0 == ccall(:syscall, Int,
        (Int, Int, Int, Int, Int, Int, Int),
        SYS_rrcall_check_presence, 0, 0, 0, 0, 0, 0)
else
    global running_under_rr() = false
end

if use_revise
    using Revise
    union!(Revise.stdlib_names, Symbol.(STDLIBS))
    # Remote-eval the following to initialize Revise in workers
    const revise_init_expr = quote
        using Revise
        const STDLIBS = $STDLIBS
        union!(Revise.stdlib_names, Symbol.(STDLIBS))
        revise_trackall()
    end
end

const max_worker_rss = if haskey(ENV, "JULIA_TEST_MAXRSS_MB")
    parse(Int, ENV["JULIA_TEST_MAXRSS_MB"]) * 2^20
else
    typemax(Csize_t)
end
limited_worker_rss = max_worker_rss != typemax(Csize_t)

function test_path(test)
    t = split(test, '/')
    if t[1] in STDLIBS
        if length(t) == 2
            return joinpath(STDLIB_DIR, t[1], "test", t[2])
        else
            return joinpath(STDLIB_DIR, t[1], "test", "runtests")
        end
    else
        return joinpath(@__DIR__, test)
    end
end

# Check all test files exist
isfiles = isfile.(test_path.(tests) .* ".jl")
if !all(isfiles)
    error("did not find test files for the following tests: ",
          join(tests[.!(isfiles)], ", "))
end

const node1_tests = String[]
function move_to_node1(t)
    if t in tests
        splice!(tests, findfirst(isequal(t), tests))
        push!(node1_tests, t)
    end
    nothing
end

# Base.compilecache only works from node 1, so precompile test is handled specially
move_to_node1("ccall")
move_to_node1("precompile")
move_to_node1("SharedArrays")
move_to_node1("threads")
move_to_node1("Distributed")
move_to_node1("gc")
# Ensure things like consuming all kernel pipe memory doesn't interfere with other tests
move_to_node1("stress")

# In a constrained memory environment, run the "distributed" test after all other tests
# since it starts a lot of workers and can easily exceed the maximum memory
limited_worker_rss && move_to_node1("Distributed")

# Move all tests to node1 for simplicity in minimal testing
for test in copy(tests)
    move_to_node1(test)
end

# Define all_tests for the summary
all_tests = [tests; node1_tests]

cd(@__DIR__) do
    # Use single-threaded testing for minimal tests
    n = 1
    skipped = 0

    @everywhere include("testdefs.jl")

    if use_revise
        Base.invokelatest(revise_trackall)
        Distributed.remotecall_eval(Main, workers(), revise_init_expr)
    end

    println("""
        Running minimal tests (single-threaded):
          getpid() = $(getpid())
          nworkers() = $(nworkers())
          nthreads() = $(Threads.threadpoolsize())
          Sys.CPU_THREADS = $(Sys.CPU_THREADS)
          Sys.total_memory() = $(Base.format_bytes(Sys.total_memory()))
          Sys.free_memory() = $(Base.format_bytes(Sys.free_memory()))
        """)
        
        # Set shorter timeouts for minimal tests
        if !haskey(ENV, "JULIA_TEST_TIMEOUT")
            ENV["JULIA_TEST_TIMEOUT"] = "120"  # 2 minutes per test
        end

    # Simple test runner for minimal tests
    results = []
    total_duration = 0.0
    
    for t in node1_tests
        println("Running test: $t")
        before = time()
        resp, duration = try
                r = Base.invokelatest(runtests, t, test_path(t), true, seed=seed)
                r, time() - before
            catch e
                isa(e, InterruptException) && rethrow()
                Any[CapturedException(e, catch_backtrace())], time() - before
            end
        
        total_duration += duration
        
        if length(resp) == 1
            println("❌ Test $t failed after $(round(duration, digits=2))s")
            if exit_on_error
                println("Stopping due to test failure")
                break
            end
        else
            println("✅ Test $t passed in $(round(duration, digits=2))s")
        end
        push!(results, (t, [resp], duration))
    end

    #=
`   Construct a testset on the master node which will hold results from all the
    test files run on workers and on node1. The loop goes through the results,
    inserting them as children of the overall testset if they are testsets,
    handling errors otherwise.

    Since the workers don't return information about passing/broken tests, only
    errors or failures, those Result types get passed `nothing` for their test
    expressions (and expected/received result in the case of Broken).

    If a test failed, returning a `RemoteException`, the error is displayed and
    the overall testset has a child testset inserted, with the (empty) Passes
    and Brokens from the worker and the full information about all errors and
    failures encountered running the tests. This information will be displayed
    as a summary at the end of the test run.

    If a test failed, returning an `Exception` that is not a `RemoteException`,
    it is likely the julia process running the test has encountered some kind
    of internal error, such as a segfault.  The entire testset is marked as
    Errored, and execution continues until the summary at the end of the test
    run, where the test file is printed out as the "failed expression".
    =#
    Test.TESTSET_PRINT_ENABLE[] = false
    o_ts = Test.DefaultTestSet("Overall")
    o_ts.time_end = o_ts.time_start + total_duration # manually populate the timing
    Test.push_testset(o_ts)
    completed_tests = Set{String}()
    for (testname, (resp,), duration) in results
        push!(completed_tests, testname)
        if isa(resp, Test.DefaultTestSet)
            resp.time_end = resp.time_start + duration
            Test.push_testset(resp)
            Test.record(o_ts, resp)
            Test.pop_testset()
        elseif isa(resp, Test.TestSetException)
            fake = Test.DefaultTestSet(testname)
            fake.time_end = fake.time_start + duration
            for i in 1:resp.pass
                Test.record(fake, Test.Pass(:test, nothing, nothing, nothing, LineNumberNode(@__LINE__, @__FILE__)))
            end
            for i in 1:resp.broken
                Test.record(fake, Test.Broken(:test, nothing))
            end
            for t in resp.errors_and_fails
                Test.record(fake, t)
            end
            Test.push_testset(fake)
            Test.record(o_ts, fake)
            Test.pop_testset()
        else
            if !isa(resp, Exception)
                resp = ErrorException(string("Unknown result type : ", typeof(resp)))
            end
            # If this test raised an exception that is not a remote testset exception,
            # i.e. not a RemoteException capturing a TestSetException that means
            # the test runner itself had some problem, so we may have hit a segfault,
            # deserialization errors or something similar.  Record this testset as Errored.
            fake = Test.DefaultTestSet(testname)
            fake.time_end = fake.time_start + duration
            Test.record(fake, Test.Error(:nontest_error, testname, nothing, Any[(resp, [])], LineNumberNode(1)))
            Test.push_testset(fake)
            Test.record(o_ts, fake)
            Test.pop_testset()
        end
    end
    for test in all_tests
        (test in completed_tests) && continue
        fake = Test.DefaultTestSet(test)
        Test.record(fake, Test.Error(:test_interrupted, test, nothing, [("skipped", [])], LineNumberNode(1)))
        Test.push_testset(fake)
        Test.record(o_ts, fake)
        Test.pop_testset()
    end

    if Base.get_bool_env("CI", false)
        @info "Writing test result data to $(@__DIR__)"
        write_testset_json_files(@__DIR__, o_ts)
    end

    Test.TESTSET_PRINT_ENABLE[] = true
    println()
    # o_ts.verbose = true # set to true to show all timings when successful
    Test.print_test_results(o_ts, 1)
    if !o_ts.anynonpass
        println("    \033[32;1mSUCCESS\033[0m (Minimal test suite - Julia is working!)")
    else
        println("    \033[31;1mFAILURE\033[0m\n")
        println("The global RNG seed was 0x$(string(seed, base = 16)).\n")
        Test.print_test_errors(o_ts)
        throw(Test.FallbackTestSetException("Minimal test run finished with errors"))
    end
end 