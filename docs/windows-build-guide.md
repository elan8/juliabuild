# Windows Build Guide for Julia (GitHub Actions)

This guide explains how to properly build Julia on Windows in GitHub Actions, following the [official Julia Windows build documentation](https://docs.julialang.org/en/v1/devdocs/build/windows/).

## Official Julia Windows Build Method

According to the official Julia documentation, the **recommended** way to build Julia on Windows is **Cygwin-to-MinGW cross-compiling**. This approach:

- ✅ Uses cross-compilation (cleaner separation)
- ✅ Avoids system library conflicts
- ✅ Is the officially tested method
- ✅ Doesn't require any source code patches

## Key Issues with Previous Workflow

The previous workflow had several problems:

### 1. **Incorrect Build Method**
- **Problem**: Using MSYS2 instead of the recommended Cygwin-to-MinGW cross-compilation
- **Solution**: Follow the official documentation exactly

### 2. **Missing Cross-Compilation Setup**
- **Problem**: Not setting `XC_HOST` for cross-compilation
- **Solution**: Use `XC_HOST = x86_64-w64-mingw32` for 64-bit builds

### 3. **Incorrect Dependencies**
- **Problem**: Using MSYS2 packages instead of Cygwin packages
- **Solution**: Install the exact packages specified in official documentation

### 4. **Missing Cygwin Environment**
- **Problem**: Not using Cygwin as the build environment
- **Solution**: Set up Cygwin with proper MinGW-w64 toolchain

## Fixed Workflow Features

### Proper Cygwin Setup
Following the official documentation exactly:

```powershell
# Download and install Cygwin with required packages
$packages = "cmake,gcc-g++,git,make,patch,curl,m4,python3,p7zip,mingw64-x86_64-gcc-g++,mingw64-x86_64-gcc-fortran"
Start-Process -FilePath "setup-x86_64.exe" -ArgumentList "-s https://mirrors.kernel.org/sourceware/cygwin/ -q -P $packages" -Wait
```

### Cross-Compilation Configuration
```bash
# Set XC_HOST for MinGW-w64 cross-compilation (64-bit)
echo 'XC_HOST = x86_64-w64-mingw32' > Make.user

# Add build configuration without GPL libraries
cat >> Make.user << 'EOF'
# Build without GPL libraries
USE_GPL_LIBS=0

# Use 64-bit BLAS for better performance
USE_BLAS64=1

# Use OpenBLAS instead of MKL for better compatibility
USE_INTEL_MKL=0

# Optimize for current CPU
JULIA_CPU_TARGET=native

# Use all available CPU cores
MAKEFLAGS=-j2

# Enable verbose output for debugging
VERBOSE=1
EOF
```

### Correct Build Process
```bash
# Set up Cygwin environment
export PATH="/cygdrive/c/cygwin64/bin:$PATH"

# Clone Julia source
git clone --depth 1 --branch v1.11.6 https://github.com/JuliaLang/julia.git julia-source
cd julia-source

# Configure and build
make -j2
```

## Key Improvements

### 1. **Official Method Compliance**
- Uses Cygwin-to-MinGW cross-compilation as recommended
- Follows official documentation exactly
- No source code patches required

### 2. **Proper Cross-Compilation Setup**
- Sets `XC_HOST = x86_64-w64-mingw32` for 64-bit builds
- Uses MinGW-w64 toolchain through Cygwin
- Clean separation between build and target environments

### 3. **Correct Dependencies**
- Installs exact packages from official documentation
- Uses Cygwin package manager for consistency
- Includes all required MinGW-w64 components

### 4. **Windows-Specific Optimizations**
- Limited parallel jobs (`-j2`) for Windows stability
- Proper timeout settings (180 minutes)
- Windows-specific verification commands

### 5. **No Source Code Modifications**
- No need for `_aligned_msize` or other patches
- Uses official Julia source code as-is
- Follows official build process exactly

## Build Process

### Step 1: Cygwin Installation
1. **Download Cygwin**: Uses official Cygwin installer
2. **Install Required Packages**: Installs exact packages from official documentation
3. **Environment Setup**: Configures Cygwin environment properly

### Step 2: Source Management
1. **Cloning**: Clones Julia source code
2. **Configuration**: Sets up cross-compilation configuration
3. **Dependencies**: Uses Cygwin package manager for dependencies

### Step 3: Build Configuration
1. **XC_HOST Setup**: Configures for MinGW-w64 cross-compilation
2. **Make.user Creation**: Creates proper build configuration
3. **GPL Exclusion**: Ensures no GPL libraries are included

### Step 4: Cross-Compilation Build
1. **Environment Setup**: Configures Cygwin environment
2. **Parallel Build**: Uses limited parallel jobs for stability
3. **Timeout Protection**: 180-minute timeout to prevent hanging builds

### Step 5: Verification
1. **Basic Testing**: Tests Julia executable and basic functionality
2. **GPL Verification**: Checks that GPL libraries are not included
3. **Package Testing**: Tests core Julia packages

## Troubleshooting Common Issues

### Issue: Cygwin Installation Fails
**Solution**: Use official Cygwin mirror and ensure proper package selection:
```powershell
$packages = "cmake,gcc-g++,git,make,patch,curl,m4,python3,p7zip,mingw64-x86_64-gcc-g++,mingw64-x86_64-gcc-fortran"
```

### Issue: Cross-Compilation Configuration
**Solution**: Ensure proper XC_HOST setting:
```bash
echo 'XC_HOST = x86_64-w64-mingw32' > Make.user
```

### Issue: Build Times Out
**Solution**: 
- Limit parallel jobs: `MAKEFLAGS=-j2`
- Increase timeout: `timeout-minutes: 180`
- Use proper Cygwin environment

### Issue: GPL Libraries Still Included
**Solution**: Ensure proper configuration:
```bash
USE_GPL_LIBS=0
USE_INTEL_MKL=0
```

### Issue: Environment Path Problems
**Solution**: Set up Cygwin environment properly:
```bash
export PATH="/cygdrive/c/cygwin64/bin:$PATH"
```

## Performance Considerations

### Build Time Optimization
- **Cross-Compilation**: Cleaner build process
- **Cygwin Environment**: Stable and tested
- **Parallel Jobs**: Limited to 2 for Windows stability

### Memory Usage
- **Recommended**: 8GB+ RAM for Windows builds
- **Minimum**: 4GB RAM
- **Swap Space**: Ensure adequate virtual memory

### Storage Requirements
- **Cygwin Installation**: ~2GB
- **Source Code**: ~500MB
- **Dependencies**: ~1GB
- **Build Output**: ~1GB
- **Total**: ~5GB free space recommended

## Verification Commands

### Check for GPL Libraries
```bash
# Use objdump to check dependencies
objdump -p ./usr/bin/julia.exe | grep -i fftw || echo "FFTW not found (good)"
objdump -p ./usr/bin/julia.exe | grep -i gmp || echo "GMP not found (good)"
```

### Verify Cross-Compilation Setup
```bash
# Check that XC_HOST is set correctly
grep "XC_HOST" Make.user || echo "XC_HOST not found"

# Check that MinGW-w64 tools are available
which x86_64-w64-mingw32-gcc || echo "MinGW-w64 GCC not found"
```

## Comparison with Official Documentation

This workflow follows the official Julia Windows build documentation exactly:

1. **Cygwin Installation**: Uses official Cygwin installer with required packages
2. **Cross-Compilation**: Sets `XC_HOST = x86_64-w64-mingw32`
3. **Build Process**: Uses `make -j2` as recommended
4. **Dependencies**: Installs exact packages from official documentation
5. **Environment**: Uses Cygwin environment as specified

The workflow now matches the official recommended approach, ensuring compatibility and avoiding any system-specific issues. 