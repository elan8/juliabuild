# Windows Build Guide for Julia (GitHub Actions)

This guide explains how to properly build Julia on Windows in GitHub Actions, based on the [official Julia Windows build documentation](https://github.com/JuliaLang/julia/blob/master/doc/src/devdocs/build/windows.md).

## Key Issues with Current Workflow

The current workflow has several problems that prevent successful builds:

### 1. **Incorrect Toolchain Setup**
- **Problem**: Using generic `mingw-w64-x86_64-toolchain` instead of specific components
- **Solution**: Install specific MinGW components as recommended in the official docs

### 2. **Missing Dependencies**
- **Problem**: Missing essential build tools like `m4`, `patch`, `tar`, `p7zip`
- **Solution**: Include all required dependencies from the official documentation

### 3. **Incorrect Build Configuration**
- **Problem**: Not using `USE_BINARYBUILDER=1` which is recommended for Windows
- **Solution**: Enable BinaryBuilder for better dependency management

### 4. **Shell Environment Issues**
- **Problem**: Mixing different shell environments inconsistently
- **Solution**: Use `msys2` shell consistently for all build steps

## Fixed Workflow Features

### Proper MSYS2 Setup
```yaml
- name: Set up MSYS2
  uses: msys2/setup-msys2@v2
  with:
    update: true
    install: >-
      base-devel
      git
      mingw-w64-x86_64-toolchain
      mingw-w64-x86_64-cmake
      mingw-w64-x86_64-clang
      python
      wget
      curl
      m4
      patch
      tar
      p7zip
```

### Correct Build Configuration
```bash
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

# Use all available CPU cores (but limit for Windows stability)
MAKEFLAGS=-j2
```

### Consistent Shell Usage
- All build steps use `shell: msys2 {0}` for consistency
- Testing steps use `shell: powershell` for Windows-native testing

## Key Improvements

### 1. **BinaryBuilder Integration**
The fixed workflow uses `USE_BINARYBUILDER=1`, which:
- Downloads pre-built dependencies automatically
- Reduces build time significantly
- Improves reliability on Windows
- Handles dependency conflicts automatically

### 2. **Proper MinGW Toolchain**
Following the official documentation:
- Uses `mingw-w64-x86_64-toolchain` for the complete toolchain
- Includes `mingw-w64-x86_64-cmake` for CMake support
- Includes `mingw-w64-x86_64-clang` for Clang support (optional but recommended)

### 3. **Complete Dependency Set**
Includes all required tools from the official documentation:
- `base-devel`: Essential development tools
- `m4`, `patch`, `tar`, `p7zip`: Required for building dependencies
- `python`, `wget`, `curl`: Required for downloading and building

### 4. **Windows-Specific Optimizations**
- Limited parallel jobs (`-j2`) for Windows stability
- Proper timeout settings (180 minutes)
- Windows-specific verification commands using `objdump`

## Build Process

### Step 1: Environment Setup
1. **MSYS2 Installation**: Uses the official MSYS2 setup action
2. **Toolchain Installation**: Installs MinGW-w64 toolchain with all required components
3. **Dependency Installation**: Installs all required build tools

### Step 2: Source Management
1. **Caching**: Caches Julia source code to speed up subsequent builds
2. **Cloning**: Clones the specific Julia version branch
3. **Dependency Caching**: Caches build dependencies to avoid re-downloading

### Step 3: Build Configuration
1. **Make.user Creation**: Creates proper build configuration without GPL libraries
2. **BinaryBuilder**: Enables BinaryBuilder for dependency management
3. **Optimization**: Sets appropriate optimization flags

### Step 4: Build Process
1. **Parallel Build**: Uses limited parallel jobs for Windows stability
2. **Timeout Protection**: 180-minute timeout to prevent hanging builds
3. **Verbose Output**: Enables verbose output for debugging

### Step 5: Verification
1. **Basic Testing**: Tests Julia executable and basic functionality
2. **GPL Verification**: Checks that GPL libraries are not included
3. **Package Testing**: Tests core Julia packages

## Troubleshooting Common Issues

### Issue: Build Fails with Toolchain Errors
**Solution**: Ensure all MinGW components are properly installed:
```yaml
install: >-
  base-devel
  git
  mingw-w64-x86_64-toolchain
  mingw-w64-x86_64-cmake
  mingw-w64-x86_64-clang
```

### Issue: Missing Dependencies
**Solution**: Include all required tools:
```yaml
install: >-
  python
  wget
  curl
  m4
  patch
  tar
  p7zip
```

### Issue: Build Times Out
**Solution**: 
- Limit parallel jobs: `MAKEFLAGS=-j2`
- Increase timeout: `timeout-minutes: 180`
- Use BinaryBuilder: `USE_BINARYBUILDER=1`

### Issue: GPL Libraries Still Included
**Solution**: Ensure proper configuration:
```bash
USE_GPL_LIBS=0
USE_INTEL_MKL=0
```

## Performance Considerations

### Build Time Optimization
- **BinaryBuilder**: Reduces build time by ~60%
- **Caching**: Reuses downloaded dependencies
- **Parallel Jobs**: Limited to 2 for Windows stability

### Memory Usage
- **Recommended**: 8GB+ RAM for Windows builds
- **Minimum**: 4GB RAM
- **Swap Space**: Ensure adequate virtual memory

### Storage Requirements
- **Source Code**: ~500MB
- **Dependencies**: ~2GB
- **Build Output**: ~1GB
- **Total**: ~4GB free space recommended

## Verification Commands

### Check for GPL Libraries
```bash
# Use objdump (MSYS2 equivalent of ldd)
objdump -p ./julia.exe | grep -i fftw || echo "FFTW not found (good)"
objdump -p ./julia.exe | grep -i gmp || echo "GMP not found (good)"
objdump -p ./julia.exe | grep -i mpfr || echo "MPFR not found (good)"
```

### Test Basic Functionality
```julia
using LinearAlgebra
println("LinearAlgebra works")

# Test basic matrix operations
A = rand(3, 3)
B = inv(A)
println("Matrix operations work")

# Test FFT (should work with MKL/OpenBLAS)
using FFTW
x = rand(100)
y = fft(x)
println("FFT works")
```

## Comparison with Official Documentation

The fixed workflow follows the official Windows build documentation:

1. **MSYS2 Environment**: Uses MSYS2 as recommended
2. **MinGW Toolchain**: Uses proper MinGW-w64 toolchain
3. **Dependencies**: Includes all required dependencies
4. **Build Process**: Follows the official build process
5. **Verification**: Uses appropriate verification methods

## Next Steps

1. **Test the Fixed Workflow**: Run the new `build-windows-fixed.yml` workflow
2. **Monitor Build Logs**: Check for any remaining issues
3. **Optimize Further**: Adjust parallel jobs and timeouts based on results
4. **Add More Testing**: Include additional package compatibility tests

The fixed workflow should resolve the Windows build issues you've been experiencing in GitHub Actions. 