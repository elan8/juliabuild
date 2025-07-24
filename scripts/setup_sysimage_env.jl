#!/usr/bin/env julia

"""
Setup script for Julia sysimage building environment.

This script creates and configures a Julia environment with all necessary packages
for building a combined sysimage with execution and LSP functionality.

Usage:
  julia setup_sysimage_env.jl
"""

using Pkg

function main()
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
        println("  Adding $pkg...")
        Pkg.add(pkg)
    end
    Pkg.instantiate()
    
    println("✅ All packages installed successfully!")
    println()
    println("Environment setup complete!")
    println("Next step: Run julia --project=sysimage_build_env scripts/build_sysimage.jl")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end 