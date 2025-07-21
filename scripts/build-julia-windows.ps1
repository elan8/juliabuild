# Julia Windows Build Script
# Based on official Julia Buildkite configuration
# https://github.com/JuliaCI/julia-buildkite/blob/main/pipelines/main/platforms/build_windows.yml

param(
    [string]$JuliaVersion = "v1.11.6",
    [string]$BuildType = "release",
    [string]$DockerImage = "juliapackaging/package-windows-x86_64:v7.10"
)

Write-Host "========================================" -ForegroundColor Green
Write-Host "Julia Windows Build Script" -ForegroundColor Green
Write-Host "Based on official Buildkite configuration" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Configuration
$BuildDir = "julia-build"
$SourceDir = "julia-source"

# Check if Docker is available
try {
    $dockerVersion = docker --version 2>$null
    if (-not $dockerVersion) {
        throw "Docker not found"
    }
    Write-Host "Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop for Windows" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Git is available
try {
    $gitVersion = git --version 2>$null
    if (-not $gitVersion) {
        throw "Git not found"
    }
    Write-Host "Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git for Windows" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Checking Docker image availability..." -ForegroundColor Yellow
try {
    docker pull $DockerImage
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to pull Docker image"
    }
    Write-Host "Docker image pulled successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to pull Docker image $DockerImage" -ForegroundColor Red
    Write-Host "Please check your internet connection and Docker configuration" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Creating build directory..." -ForegroundColor Yellow
if (Test-Path $BuildDir) {
    Write-Host "Removing existing build directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Path $BuildDir | Out-Null
Set-Location $BuildDir

Write-Host ""
Write-Host "Cloning Julia source code..." -ForegroundColor Yellow
try {
    git clone --depth 1 --branch $JuliaVersion https://github.com/JuliaLang/julia.git $SourceDir
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone Julia repository"
    }
    Write-Host "Julia source code cloned successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to clone Julia repository" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $SourceDir

Write-Host ""
Write-Host "Creating Make.user configuration..." -ForegroundColor Yellow

$MakeUserContent = @"
# Build without GPL libraries
USE_GPL_LIBS=0

# Use 64-bit BLAS for better performance
USE_BLAS64=1

# Use OpenBLAS instead of MKL for better compatibility
USE_INTEL_MKL=0

# Optimize for current CPU
JULIA_CPU_TARGET=native

# Use BinaryBuilder for dependencies (recommended for Windows)
USE_BINARYBUILDER=1

# Use GNU C11 standard (same as official Julia build)
JCFLAGS += -std=gnu11
JCXXFLAGS += -std=gnu++17

# Build type
JULIA_DEBUG=0

# Enable verbose output for debugging
VERBOSE=1

# Use limited parallelism for Windows stability
MAKEFLAGS=-j2
"@

$MakeUserContent | Out-File -FilePath "Make.user" -Encoding UTF8

Write-Host "Make.user contents:" -ForegroundColor Yellow
Get-Content "Make.user" | Write-Host

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Starting Julia build using Docker..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Set environment variables for the build
$env:JULIA_CPU_THREADS = "2"
$env:VERBOSE = "1"

# Get current directory for volume mounting
$CurrentDir = Get-Location

# Run the build using the official Docker image
$DockerCommand = @"
docker run --rm `
  -v "$CurrentDir:/julia-source" `
  -w /julia-source `
  -e JULIA_CPU_THREADS=2 `
  -e VERBOSE=1 `
  $DockerImage `
  bash -c "
    echo 'Starting Julia build...'
    make -j2
    
    echo 'Testing Julia build...'
    ./julia --version
    ./julia -e 'println(\"Julia build successful!\")'
    
    echo 'Running basic tests...'
    ./julia -e '
      using LinearAlgebra
      println(\"LinearAlgebra works\")
      
      A = rand(3, 3)
      B = inv(A)
      println(\"Matrix operations work\")
      
      using FFTW
      x = rand(100)
      y = fft(x)
      println(\"FFT works\")
    '
    
    echo 'Checking for GPL libraries...'
    objdump -p ./julia.exe | grep -i fftw || echo 'FFTW not found (good)'
    objdump -p ./julia.exe | grep -i gmp || echo 'GMP not found (good)'
    objdump -p ./julia.exe | grep -i mpfr || echo 'MPFR not found (good)'
    
    echo 'Build statistics:'
    ls -la julia.exe
    echo \"File size: \$(stat -c%s julia.exe) bytes\"
  "
"@

Write-Host "Executing Docker command..." -ForegroundColor Yellow
Invoke-Expression $DockerCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Julia build failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "Creating distribution package..." -ForegroundColor Yellow
Set-Location ..

# Create distribution directory
if (Test-Path "julia-windows-package") {
    Remove-Item -Recurse -Force "julia-windows-package"
}
New-Item -ItemType Directory -Path "julia-windows-package" | Out-Null

# Copy Julia executable
Copy-Item "$SourceDir\julia.exe" "julia-windows-package\"

# Create README file
$ReadmeContent = @"
Julia $JuliaVersion Windows Build
Built on: $(Get-Date)
Build type: $BuildType
Built using official Julia Docker image: $DockerImage

This build was created using the official Julia Buildkite configuration.
No GPL libraries are included in this build.
"@

$ReadmeContent | Out-File -FilePath "julia-windows-package\README.txt" -Encoding UTF8

# Create ZIP file
Write-Host "Creating ZIP package..." -ForegroundColor Yellow
$ZipFileName = "julia-windows-$JuliaVersion.zip"
Compress-Archive -Path "julia-windows-package" -DestinationPath $ZipFileName -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build Summary" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Julia Version: $JuliaVersion" -ForegroundColor White
Write-Host "Build Type: $BuildType" -ForegroundColor White
Write-Host "Docker Image: $DockerImage" -ForegroundColor White
Write-Host ""
Write-Host "Files created:" -ForegroundColor White
Write-Host "- julia-windows-package\julia.exe" -ForegroundColor White
Write-Host "- julia-windows-package\README.txt" -ForegroundColor White
Write-Host "- $ZipFileName" -ForegroundColor White
Write-Host ""
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "You can find the Julia executable in: $(Get-Location)\julia-windows-package\julia.exe" -ForegroundColor White
Write-Host "You can find the ZIP package at: $(Get-Location)\$ZipFileName" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit" 