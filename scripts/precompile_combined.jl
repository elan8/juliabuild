# Precompilation script for combined Julia sysimage (execution + LSP)

# Load all packages
using Plots
using GR
using PlotUtils
using RecipesBase
using RecipesPipeline
using PlotThemes
using StatsBase
using StatsPlots
using DataFrames
using CSV

using LanguageServer
using SymbolServer
using StaticLint
using CSTParser
using Tokenize
using JuliaFormatter
using JSON3
using JSONRPC
using URIs
using FilePathsBase
using FileWatching
using Markdown
using REPL

println("Precompiling combined functionality...")

# Set up plotting backend
ENV["PLOTS_DEFAULT_BACKEND"] = "GR"
try
    gr()
catch
    println("Warning: Could not initialize GR backend, continuing with default")
end

# Precompile plotting operations
println("Precompiling plotting operations...")

# Basic plotting
x = 1:10
y = rand(10)
Plots.plot(x, y, title="Test Plot", xlabel="X", ylabel="Y")
Plots.scatter(x, y)
line = Plots.plot(x, y, linewidth=2, color=:red)
Plots.bar(x, y)

# Multiple plots
p1 = Plots.plot(x, y, title="Plot 1")
p2 = Plots.scatter(x, y, title="Plot 2")
Plots.plot(p1, p2, layout=(1,2))

# Themes
Plots.plot(x, y, theme=:default)
Plots.plot(x, y, theme=:dark)

# DataFrames plotting
df = DataFrame(x=x, y=y)
Plots.plot(df.x, df.y)

# StatsBase integration
Plots.histogram(randn(1000))
Plots.boxplot([randn(100), randn(100)])

# Complex plots
Plots.contour(rand(10, 10))
Plots.heatmap(rand(10, 10))
Plots.surface(rand(10, 10))

# Precompile LSP functionality
println("Precompiling LSP functionality...")

# Initialize LanguageServer components
try
    # Create a temporary workspace for testing
    temp_dir = mktempdir()
    test_file = joinpath(temp_dir, "test.jl")
    write(test_file, "println(\"Hello, World!\")")
    
    # Initialize LanguageServer
    ls = LanguageServerInstance(
        stdin,
        stdout,
        false,
        joinpath(temp_dir, "workspace")
    )
    
    # Test basic LSP functionality
    println("Testing LSP initialization...")
    
    # Test parsing
    source = "function test()\n    println(\"Hello\")\nend"
    tokens = collect(tokenize(source))
    cst = CSTParser.parse(source, true)
    
    # Test static analysis
    StaticLint.symbols(cst)
    
    # Test JSON handling
    test_json = JSON3.read("{\"test\": \"value\"}")
    JSON3.write(test_json)
    
    # Test URI handling
    uri = URI("file:///test.jl")
    uri.scheme
    uri.path
    
    # Clean up
    rm(temp_dir, recursive=true)
    
    println("LSP precompilation tests completed successfully!")
catch
    println("Warning: Some LSP precompilation tests failed (this is normal for some components)")
end

println("Combined precompilation complete!")
