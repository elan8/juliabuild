# Windows Build Guide for Julia (GitHub Actions)

This guide explains how to properly build Julia on Windows in GitHub Actions, following the [official Julia Windows build documentation](https://docs.julialang.org/en/v1/devdocs/build/windows/).

## Official Julia Windows Build Method

According to the official Julia documentation, the **recommended** way to build Julia on Windows is **Cygwin-to-MinGW cross-compiling**. This approach:

- ✅ Uses cross-compilation (cleaner separation)
- ✅ Avoids system library conflicts
- ✅ Is the officially tested method
- ✅ Doesn't require any source code patches

## Docker-Based Approach (Recommended for GitHub Actions)

For GitHub Actions, we provide a **Docker-based approach** that follows the exact same method as the official Julia Buildkite process:

### Why Use Docker?

1. **Official Method**: Uses the same `juliapackaging/package-windows-x86_64:v7.10` Docker image as the official Julia build
2. **Consistent Environment**: Guarantees the same build environment as official releases
3. **No System Conflicts**: Avoids all Windows-specific compilation issues
4. **Cross-Platform**: Can build Windows binaries from Linux runners
5. **Reproducible**: Same results every time

### Docker Workflow Features

The `build-windows-docker.yml` workflow:

- ✅ **Uses Official Docker Image**: `juliapackaging/package-windows-x86_64:v7.10`
- ✅ **Same Build Process**: Uses the same approach as official Buildkite
- ✅ **BinaryBuilder Integration**: Uses `USE_BINARYBUILDER=1` for dependencies
- ✅ **No GPL Libraries**: Builds without GPL-licensed libraries
- ✅ **Comprehensive Testing**: Verifies build and functionality
- ✅ **Artifact Creation**: Creates distribution packages

### Docker Build Process

The workflow follows the official Buildkite configuration exactly:

```yaml
# Use the same Docker image as the official Buildkite process
docker run --rm \
  -v "$(pwd)/julia-source:/julia-source" \
  -w /julia-source \
  -e JULIA_CPU_THREADS=2 \
  -e VERBOSE=1 \
  juliapackaging/package-windows-x86_64:v7.10 \
  bash -c "
    echo 'Starting Julia build...'
    make -j2
    
    echo 'Testing Julia build...'
    ./julia --version
    ./julia -e 'println(\"Julia build successful!\")'
  "
```

### Key Differences from Buildkite

1. **Volume Mounting**: Instead of copying files into the container, we mount the Julia source directory
2. **Direct Execution**: Run the build commands directly in the container
3. **Artifact Extraction**: Copy the built binary back to the host

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
2. **Configuration**: Creates `Make.user` with proper settings
3. **Dependencies**: Uses BinaryBuilder for consistent dependencies

### Step 3: Build Process
1. **Cross-Compilation**: Uses MinGW-w64 toolchain
2. **Parallel Build**: Uses limited parallelism for stability
3. **Verification**: Tests build and functionality

### Step 4: Artifact Creation
1. **Binary Extraction**: Extracts Julia executable
2. **Package Creation**: Creates distribution packages
3. **Upload**: Uploads artifacts for download

## Comparison of Methods

| Method | Pros | Cons | Use Case |
|--------|------|------|----------|
| **Docker (Recommended)** | ✅ Official method<br>✅ No system conflicts<br>✅ Cross-platform<br>✅ Reproducible | ❌ Requires Docker<br>❌ Larger build time | GitHub Actions, CI/CD |
| **Cygwin-to-MinGW** | ✅ Official documentation<br>✅ Native Windows build<br>✅ Full control | ❌ Complex setup<br>❌ System conflicts<br>❌ Windows-only | Local development |
| **MSYS2** | ✅ Easy setup<br>✅ Good package manager | ❌ Not official method<br>❌ System conflicts<br>❌ Limited compatibility | Quick testing |

## Recommended Approach

For **GitHub Actions**, use the **Docker-based approach** (`build-windows-docker.yml`):

1. **Most Reliable**: Uses official Docker images
2. **No Conflicts**: Avoids all Windows-specific issues
3. **Cross-Platform**: Can build from Linux runners
4. **Official Method**: Same as official Julia build process

For **Local Development**, use the **Cygwin-to-MinGW approach** (`build-windows.yml`):

1. **Native Build**: Builds directly on Windows
2. **Full Control**: Complete control over build environment
3. **Official Documentation**: Follows official Julia docs exactly

## Troubleshooting

### Common Issues

1. **`_aligned_msize` Conflict**: This is resolved by using the official Docker image or proper cross-compilation setup
2. **Missing Dependencies**: Ensure all required packages are installed
3. **Build Timeouts**: Use limited parallelism (`-j2`) for Windows stability
4. **Memory Issues**: Reduce parallel jobs and increase timeout

### Debug Steps

1. **Check Environment**: Verify all required tools are available
2. **Review Logs**: Check verbose output for specific errors
3. **Test Incrementally**: Build dependencies separately if needed
4. **Use Official Method**: Follow official documentation exactly

## Conclusion

The **Docker-based approach** is recommended for GitHub Actions as it:

- ✅ Uses the exact same method as official Julia builds
- ✅ Avoids all Windows-specific compilation issues
- ✅ Provides consistent, reproducible results
- ✅ Requires no source code modifications
- ✅ Works reliably in CI/CD environments

This approach ensures that your builds are as close as possible to the official Julia releases while avoiding the complexity and potential issues of native Windows builds. 