#!/usr/bin/env julia

"""
Build a combined Julia sysimage with both execution and LSP functionality.

This script builds a single sysimage that includes:
- Execution functionality: Plots.jl + GR backend for code execution
- LSP functionality: LanguageServer.jl for LSP functionality

The script creates a clean Julia environment and installs PackageCompiler.jl
before building the sysimage to ensure isolation and reproducibility.

Usage: 
  julia build_all_sysimages.jl [output_dir] [--keep-env]
  
Arguments:
  output_dir: directory for output files (default: sysimages)
  --keep-env: keep the temporary environment for debugging
  
Examples:
  julia build_all_sysimages.jl
  julia build_all_sysimages.jl sysimages/
  julia build_all_sysimages.jl custom_output/ --keep-env
"""

# Load Pkg at top level
using Pkg

function setup_environment()
    println("🔧 Setting up Julia environment for sysimage building...")
    
    # Create a new environment
    env_dir = "sysimage_build_env"
    mkpath(env_dir)
    
    println("✅ Created environment in: $env_dir")
    
    # Activate the environment and install PackageCompiler
    println("📦 Installing PackageCompiler.jl...")
    
    # Use Pkg to activate environment and add PackageCompiler
    Pkg.activate(env_dir)
    Pkg.add("PackageCompiler")
    Pkg.instantiate()
    
    println("✅ PackageCompiler.jl installed successfully!")
    println()
    
    return env_dir
end

# Load PackageCompiler after environment setup
using PackageCompiler

function get_sysimage_extension()
    """Get the correct sysimage extension for the current platform."""
    if Sys.iswindows()
        return ".dll"
    elseif Sys.islinux()
        return ".so"
    elseif Sys.isapple()
        return ".dylib"
    else
        return ".so"  # Default fallback
    end
end

function main()
    # Parse command line arguments
    output_dir = length(ARGS) > 0 ? ARGS[1] : "sysimages"
    keep_env = "--keep-env" in ARGS
    
    # Setup environment and install PackageCompiler
    env_dir = setup_environment()
    
    # Create output directory
    mkpath(output_dir)
    
    println("Building combined Julia sysimage...")
    println("Output directory: $output_dir")
    println()
    
    # Get platform-specific extension
    ext = get_sysimage_extension()
    
    # Build combined sysimage
    println("🔨 Building combined sysimage...")
    build_combined_sysimage(joinpath(output_dir, "julia_combined_sysimage$ext"))
    println()
    
    println("✅ Combined sysimage built successfully!")
    println()
    println("Generated files:")
    println("  - $(joinpath(output_dir, "julia_combined_sysimage$ext"))")
    
    # Clean up temporary environment (unless --keep-env flag is used)
    if !keep_env
        cleanup_environment(env_dir)
    else
        println("🔧 Keeping environment for debugging: $env_dir")
    end
end

function cleanup_environment(env_dir)
    println("🧹 Cleaning up temporary environment...")
    try
        rm(env_dir, recursive=true, force=true)
        println("✅ Cleaned up environment: $env_dir")
    catch e
        println("⚠️  Warning: Could not clean up environment $env_dir: $e")
    end
end



function build_combined_sysimage(output_path)
    println("Building combined Julia sysimage...")
    println("Output path: $output_path")
    
    # Define packages to include in the sysimage (both execution and LSP)
    packages = [
        # Execution functionality (plotting)
        "Plots",
        "GR",
        "PlotUtils",
        "RecipesBase",
        "RecipesPipeline",
        "PlotThemes",
        "StatsBase",
        "StatsPlots",
        "DataFrames",
        "CSV",
        
        # LSP functionality
        "LanguageServer",
        "SymbolServer",
        "StaticLint",
        
        # Parsing and analysis
        "CSTParser",
        "Tokenize",
        "JuliaFormatter",
        
        # JSON handling for LSP protocol
        "JSON3",
        "JSONRPC",
        
        # File system and utilities
        "URIs",
        "FilePathsBase",
        "FileWatching",
        
        # Additional utilities often used
        "Markdown",
        "REPL",
    ]
    
    # Add packages to the environment
    println("📦 Adding packages to environment...")
    for pkg in packages
        Pkg.add(pkg)
    end
    Pkg.instantiate()
    
    # Create precompilation script
    create_combined_precompilation_script()
    
    println("Packages to include:")
    for pkg in packages
        println("  - $pkg")
    end
    
    # Build the sysimage
    try
        create_sysimage(
            packages,
            sysimage_path = output_path,
            precompile_execution_file = ["scripts/precompile_combined.jl"],
            cpu_target = PackageCompiler.default_app_cpu_target(),
            include_transitive_dependencies = true
        )
        println("✅ Combined sysimage built successfully: $output_path")
    catch e
        println("❌ Error building combined sysimage: $e")
        rethrow(e)
    end
end



function create_combined_precompilation_script()
    println("Creating combined precompilation script...")
    
    script_content = """
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
gr()

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
    write(test_file, "println(\\"Hello, World!\\")")
    
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
    source = "function test()\\n    println(\\"Hello\\")\\nend"
    tokens = collect(tokenize(source))
    cst = CSTParser.parse(source, true)
    
    # Test static analysis
    StaticLint.symbols(cst)
    
    # Test JSON handling
    test_json = JSON3.read("{\\"test\\": \\"value\\"}")
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
"""
    
    # Ensure scripts directory exists
    mkpath("scripts")
    
    # Write the script
    write("scripts/precompile_combined.jl", script_content)
    println("✅ Combined precompilation script created: scripts/precompile_combined.jl")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end 