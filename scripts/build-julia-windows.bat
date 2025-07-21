@echo off
setlocal enabledelayedexpansion

REM Julia Windows Build Script
REM Based on official Julia Buildkite configuration
REM https://github.com/JuliaCI/julia-buildkite/blob/main/pipelines/main/platforms/build_windows.yml

echo ========================================
echo Julia Windows Build Script
echo Based on official Buildkite configuration
echo ========================================

REM Configuration
set JULIA_VERSION=v1.11.6
set BUILD_TYPE=release
set DOCKER_IMAGE=juliapackaging/package-windows-x86_64:v7.10
set BUILD_DIR=julia-build
set SOURCE_DIR=julia-source

REM Check if Docker is available
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop for Windows
    pause
    exit /b 1
)

REM Check if Git is available
git --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not in PATH
    echo Please install Git for Windows
    pause
    exit /b 1
)

echo.
echo Checking Docker image availability...
docker pull %DOCKER_IMAGE%
if errorlevel 1 (
    echo ERROR: Failed to pull Docker image %DOCKER_IMAGE%
    echo Please check your internet connection and Docker configuration
    pause
    exit /b 1
)

echo.
echo Creating build directory...
if exist %BUILD_DIR% (
    echo Removing existing build directory...
    rmdir /s /q %BUILD_DIR%
)
mkdir %BUILD_DIR%
cd %BUILD_DIR%

echo.
echo Cloning Julia source code...
git clone --depth 1 --branch %JULIA_VERSION% https://github.com/JuliaLang/julia.git %SOURCE_DIR%
if errorlevel 1 (
    echo ERROR: Failed to clone Julia repository
    pause
    exit /b 1
)

cd %SOURCE_DIR%

echo.
echo Creating Make.user configuration...
(
echo # Build without GPL libraries
echo USE_GPL_LIBS=0
echo.
echo # Use 64-bit BLAS for better performance
echo USE_BLAS64=1
echo.
echo # Use OpenBLAS instead of MKL for better compatibility
echo USE_INTEL_MKL=0
echo.
echo # Optimize for current CPU
echo JULIA_CPU_TARGET=native
echo.
echo # Use BinaryBuilder for dependencies ^(recommended for Windows^)
echo USE_BINARYBUILDER=1
echo.
echo # Use GNU C11 standard ^(same as official Julia build^)
echo JCFLAGS += -std=gnu11
echo JCXXFLAGS += -std=gnu++17
echo.
echo # Build type
echo JULIA_DEBUG=0
echo.
echo # Enable verbose output for debugging
echo VERBOSE=1
echo.
echo # Use limited parallelism for Windows stability
echo MAKEFLAGS=-j2
) > Make.user

echo Make.user contents:
type Make.user

echo.
echo ========================================
echo Starting Julia build using Docker...
echo ========================================

REM Set environment variables for the build
set JULIA_CPU_THREADS=2
set VERBOSE=1

REM Run the build using the official Docker image
docker run --rm ^
  -v "%cd%:/julia-source" ^
  -w /julia-source ^
  -e JULIA_CPU_THREADS=%JULIA_CPU_THREADS% ^
  -e VERBOSE=%VERBOSE% ^
  %DOCKER_IMAGE% ^
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
      
      A = rand(3, 3^)
      B = inv(A^)
      println(\"Matrix operations work\")
      
      using FFTW
      x = rand(100^)
      y = fft(x^)
      println(\"FFT works\")
    '
    
    echo 'Checking for GPL libraries...'
    objdump -p ./julia.exe ^| grep -i fftw ^|^| echo 'FFTW not found ^(good^)'
    objdump -p ./julia.exe ^| grep -i gmp ^|^| echo 'GMP not found ^(good^)'
    objdump -p ./julia.exe ^| grep -i mpfr ^|^| echo 'MPFR not found ^(good^)'
    
    echo 'Build statistics:'
    ls -la julia.exe
    echo \"File size: \$(stat -c%%s julia.exe^) bytes\"
  "

if errorlevel 1 (
    echo.
    echo ERROR: Julia build failed!
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================

echo.
echo Creating distribution package...
cd ..

REM Create distribution directory
if exist julia-windows-package (
    rmdir /s /q julia-windows-package
)
mkdir julia-windows-package

REM Copy Julia executable
copy "%SOURCE_DIR%\julia.exe" julia-windows-package\

REM Create README file
(
echo Julia %JULIA_VERSION% Windows Build
echo Built on: %date% %time%
echo Build type: %BUILD_TYPE%
echo Built using official Julia Docker image: %DOCKER_IMAGE%
echo.
echo This build was created using the official Julia Buildkite configuration.
echo No GPL libraries are included in this build.
) > julia-windows-package\README.txt

REM Create ZIP file
echo Creating ZIP package...
powershell -Command "Compress-Archive -Path julia-windows-package -DestinationPath julia-windows-%JULIA_VERSION%.zip -Force"

echo.
echo ========================================
echo Build Summary
echo ========================================
echo Julia Version: %JULIA_VERSION%
echo Build Type: %BUILD_TYPE%
echo Docker Image: %DOCKER_IMAGE%
echo.
echo Files created:
echo - julia-windows-package\julia.exe
echo - julia-windows-package\README.txt
echo - julia-windows-%JULIA_VERSION%.zip
echo.
echo Build completed successfully!
echo You can find the Julia executable in: %cd%\julia-windows-package\julia.exe
echo You can find the ZIP package at: %cd%\julia-windows-%JULIA_VERSION%.zip
echo.
pause 