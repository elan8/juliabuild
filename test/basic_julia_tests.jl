#!/usr/bin/env julia

"""
Basic Julia Functionality Tests

This script provides a comprehensive but simple test suite to verify that
basic Julia functionality works as expected. It covers:

- Core language features (types, variables, control flow)
- Basic arithmetic and mathematical operations
- String operations and manipulation
- Array operations and indexing
- Function definitions and calls
- Basic I/O operations
- Error handling
- Module system
- Type system
- Collections (Dict, Set, Tuple)

Run with: julia basic_julia_tests.jl
"""

using Test
using Random
using LinearAlgebra
using Dates

println("="^60)
println("Basic Julia Functionality Test Suite")
println("="^60)
println()

# Track test results
total_tests = 0
passed_tests = 0
failed_tests = 0

function run_test(test_name, test_func)
    global total_tests, passed_tests, failed_tests
    total_tests += 1
    
    try
        test_func()
        println("✅ $test_name")
        passed_tests += 1
        return true
    catch e
        println("❌ $test_name - Error: $e")
        failed_tests += 1
        return false
    end
end

println("1. Testing Core Language Features")
println("-"^40)

# Basic variable assignment and types
run_test("Variable assignment", () -> begin
    x = 42
    @test x == 42
    @test typeof(x) == Int
end)

run_test("Type system", () -> begin
    @test typeof(1) == Int
    @test typeof(1.0) == Float64
    @test typeof("hello") == String
    @test typeof(true) == Bool
    @test typeof([1,2,3]) == Vector{Int}
end)

run_test("Control flow", () -> begin
    x = 10
    if x > 5
        result = "greater"
    else
        result = "less"
    end
    @test result == "greater"
    
    # For loop
    sum = 0
    for i in 1:5
        sum += i
    end
    @test sum == 15
    
    # While loop
    count = 0
    while count < 3
        count += 1
    end
    @test count == 3
end)

println()
println("2. Testing Arithmetic and Mathematical Operations")
println("-"^40)

run_test("Basic arithmetic", () -> begin
    @test 2 + 3 == 5
    @test 10 - 4 == 6
    @test 6 * 7 == 42
    @test 15 ÷ 3 == 5
    @test 17 % 5 == 2
    @test 2^3 == 8
end)

run_test("Floating point arithmetic", () -> begin
    @test 3.14 + 2.86 ≈ 6.0
    @test 10.0 / 2.0 ≈ 5.0
    @test sqrt(16.0) ≈ 4.0
    @test 2.0^3.0 ≈ 8.0
end)

run_test("Mathematical functions", () -> begin
    @test abs(-5) == 5
    @test abs(3) == 3
    @test round(3.7) == 4.0
    @test floor(3.7) == 3.0
    @test ceil(3.2) == 4.0
    @test max(1, 5, 3) == 5
    @test min(1, 5, 3) == 1
end)

println()
println("3. Testing String Operations")
println("-"^40)

run_test("String creation and concatenation", () -> begin
    s1 = "Hello"
    s2 = "World"
    @test s1 * " " * s2 == "Hello World"
    @test string(s1, " ", s2) == "Hello World"
end)

run_test("String indexing and slicing", () -> begin
    s = "Julia"
    @test s[1] == 'J'
    @test s[end] == 'a'
    @test s[1:3] == "Jul"
    @test length(s) == 5
end)

run_test("String functions", () -> begin
    s = "  hello world  "
    @test strip(s) == "hello world"
    @test uppercase("hello") == "HELLO"
    @test lowercase("WORLD") == "world"
    @test replace("hello", "o" => "0") == "hell0"
end)

println()
println("4. Testing Array Operations")
println("-"^40)

run_test("Array creation and indexing", () -> begin
    arr = [1, 2, 3, 4, 5]
    @test arr[1] == 1
    @test arr[end] == 5
    @test length(arr) == 5
    @test size(arr) == (5,)
end)

run_test("Array operations", () -> begin
    arr = [1, 2, 3]
    @test sum(arr) == 6
    @test maximum(arr) == 3
    @test minimum(arr) == 1
    @test sort([3, 1, 2]) == [1, 2, 3]
end)

run_test("Array comprehension", () -> begin
    squares = [x^2 for x in 1:5]
    @test squares == [1, 4, 9, 16, 25]
    
    evens = [x for x in 1:10 if x % 2 == 0]
    @test evens == [2, 4, 6, 8, 10]
end)

run_test("Matrix operations", () -> begin
    A = [1 2; 3 4]
    @test size(A) == (2, 2)
    @test A[1,1] == 1
    @test A[2,2] == 4
    @test det(A) == -2
end)

println()
println("5. Testing Functions")
println("-"^40)

run_test("Function definition and calls", () -> begin
    function add(x, y)
        return x + y
    end
    
    @test add(3, 4) == 7
    @test add(1.5, 2.5) ≈ 4.0
end)

run_test("Anonymous functions", () -> begin
    f = x -> x^2
    @test f(3) == 9
    @test f(4) == 16
    
    g = (x, y) -> x + y
    @test g(5, 3) == 8
end)

run_test("Function with default arguments", () -> begin
    function greet(name="World")
        return "Hello, " * name * "!"
    end
    
    @test greet() == "Hello, World!"
    @test greet("Julia") == "Hello, Julia!"
end)

println()
println("6. Testing Collections")
println("-"^40)

run_test("Dictionary operations", () -> begin
    d = Dict("a" => 1, "b" => 2, "c" => 3)
    @test d["a"] == 1
    @test haskey(d, "b")
    @test !haskey(d, "d")
    @test length(d) == 3
end)

run_test("Set operations", () -> begin
    s1 = Set([1, 2, 3])
    s2 = Set([2, 3, 4])
    @test 1 in s1
    @test !(4 in s1)
    @test union(s1, s2) == Set([1, 2, 3, 4])
    @test intersect(s1, s2) == Set([2, 3])
end)

run_test("Tuple operations", () -> begin
    t = (1, "hello", 3.14)
    @test t[1] == 1
    @test t[2] == "hello"
    @test length(t) == 3
    @test typeof(t) == Tuple{Int, String, Float64}
end)

println()
println("7. Testing Error Handling")
println("-"^40)

run_test("Try-catch blocks", () -> begin
    result = "success"
    try
        error("test error")
    catch e
        result = "caught"
    end
    @test result == "caught"
end)

run_test("Exception types", () -> begin
    try
        sqrt(-1)
    catch e
        @test e isa DomainError
    end
    
    try
        [1,2,3][10]
    catch e
        @test e isa BoundsError
    end
end)

println()
println("8. Testing Basic I/O")
println("-"^40)

run_test("String I/O", () -> begin
    io = IOBuffer()
    println(io, "Hello")
    println(io, "World")
    seek(io, 0)
    content = read(io, String)
    @test contains(content, "Hello")
    @test contains(content, "World")
    close(io)
end)

run_test("File operations", () -> begin
    test_file = "test_temp.txt"
    test_content = "Hello Julia!"
    
    # Write file
    open(test_file, "w") do io
        println(io, test_content)
    end
    
    # Read file
    content = read(test_file, String)
    @test contains(content, test_content)
    
    # Clean up
    rm(test_file, force=true)
end)

println()
println("9. Testing Module System")
println("-"^40)

run_test("Module loading", () -> begin
    # Test that we can use standard library modules
    @test typeof(rand()) == Float64
    @test typeof(now()) == DateTime
    @test typeof(split("a,b,c", ",")) == Vector{SubString{String}}
end)

println()
println("10. Testing Type System")
println("-"^40)

run_test("Type annotations", () -> begin
    x::Int = 42
    @test typeof(x) == Int
    @test x == 42
end)

run_test("Type conversion", () -> begin
    @test convert(Float64, 5) == 5.0
    @test string(123) == "123"
    @test parse(Int, "42") == 42
end)

run_test("Type promotion", () -> begin
    @test typeof(1 + 1.0) == Float64
    @test typeof(1.0 + 2.0) == Float64
    @test typeof(1 + 2) == Int
end)

println()
println("11. Testing Random Number Generation")
println("-"^40)

run_test("Random number generation", () -> begin
    # Set seed for reproducible results
    Random.seed!(42)
    
    r1 = rand()
    r2 = rand()
    @test typeof(r1) == Float64
    @test typeof(r2) == Float64
    @test 0.0 <= r1 <= 1.0
    @test 0.0 <= r2 <= 1.0
    
    # Test integer random
    ri = rand(1:10)
    @test typeof(ri) == Int
    @test 1 <= ri <= 10
end)

println()
println("12. Testing System Information")
println("-"^40)

run_test("System queries", () -> begin
    @test typeof(Sys.CPU_THREADS) == Int
    @test Sys.CPU_THREADS > 0
    @test typeof(Sys.total_memory()) == UInt64
    @test Sys.total_memory() > 0
    @test typeof(VERSION) == VersionNumber
end)

println()
println("="^60)
println("Test Summary")
println("="^60)
println("Total tests: $total_tests")
println("Passed: $passed_tests")
println("Failed: $failed_tests")
println("Success rate: $(round(passed_tests/total_tests*100, digits=1))%")

if failed_tests == 0
    println()
    println("🎉 ALL TESTS PASSED! Julia is working correctly.")
    println("="^60)
else
    println()
    println("❌ Some tests failed. Please check the output above.")
    println("="^60)
    exit(1)
end 