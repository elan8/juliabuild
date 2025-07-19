# Julia Build Without GPL Libraries

This repository contains documentation and scripts for building Julia without GPL licensed libraries using the `USE_GPL_LIBS=0` build option.

## Overview

Julia can be built without GPL licensed dependencies by setting the `USE_GPL_LIBS=0` build option. This creates a more permissive build that avoids GPL licensing restrictions while maintaining core functionality.

## What Gets Excluded

When building with `USE_GPL_LIBS=0`, the following GPL-licensed libraries are excluded:

- **FFTW**: Fast Fourier Transform library (replaced with MKL or OpenBLAS)
- **GMP**: GNU Multiple Precision Arithmetic Library (replaced with MPFR)
- **MPFR**: Multiple Precision Floating-Point Reliable Library (replaced with alternative implementations)

## Prerequisites

Before building Julia without GPL libraries, ensure you have:

### System Requirements
- **Linux**: Ubuntu 18.04+, CentOS 7+, or similar
- **macOS**: 10.13+ (High Sierra)
- **Windows**: Windows 10+ with WSL2 recommended
- **Memory**: At least 8GB RAM (16GB recommended)
- **Storage**: At least 10GB free space

### Required Tools
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential cmake git curl wget

# CentOS/RHEL
sudo yum groupinstall "Development Tools"
sudo yum install cmake git curl wget

# macOS (using Homebrew)
brew install cmake git curl wget

# Windows (using Chocolatey)
choco install cmake git curl wget
```

## Building Julia Without GPL Libraries

### Option 1: Using GitHub Actions (Recommended)

This repository includes GitHub Actions workflows that automatically build Julia without GPL libraries. This is the easiest and most reliable method.

#### Quick Start with GitHub Actions

1. **Fork this repository** to your GitHub account
2. **Go to the Actions tab** in your forked repository
3. **Select a workflow**:
   - `Quick Test Build`: Fast test build (Windows only, ~45 minutes)
   - `Build Julia Without GPL Libraries`: Full build for all platforms
   - `Advanced Julia Build Without GPL Libraries`: Advanced build with custom version support

4. **Click "Run workflow"** and configure:
   - **Julia version**: Choose from v1.11.6, v1.10.0, v1.9.4 (or any custom version)
   - **Platforms**: Select linux, macos, windows (or all)
   - **Build type**: release or debug
   - **Create release**: true or false (advanced workflow only)

#### Using the Trigger Script

If you have the GitHub CLI installed:

```bash
# Make the script executable
chmod +x scripts/trigger-build.sh

# Trigger a build with default settings
./scripts/trigger-build.sh

# Trigger a build with custom settings
./scripts/trigger-build.sh v1.11.6 "linux,macos" release
```

#### Manual Local Build

### Step 1: Clone Julia Source

```bash
git clone https://github.com/JuliaLang/julia.git
cd julia
```

### Step 2: Set Build Options

Create a `Make.user` file in the Julia source directory:

```bash
cat > Make.user << EOF
# Build without GPL libraries
USE_GPL_LIBS=0

# Optional: Specify number of parallel jobs
JULIA_CPU_TARGET=native
MAKEFLAGS=-j$(nproc)

# Optional: Use specific BLAS/LAPACK
USE_BLAS64=1
USE_INTEL_MKL=1
EOF
```

### Step 3: Build Julia

```bash
# Clean any previous builds
make clean

# Build Julia (this may take 1-3 hours)
make

# Verify the build
./julia --version
```

### Step 4: Install (Optional)

```bash
# Install to system
sudo make install

# Or create a local installation
make install prefix=$HOME/julia-nogpl
```

## GitHub Actions Workflows

This repository includes several GitHub Actions workflows for building Julia without GPL libraries:

### Available Workflows

1. **`build.yml`** - Basic build workflow
   - Builds Julia v1.11.6 for Linux, macOS, and Windows
   - Includes basic testing and verification
   - Creates distribution packages (tar.gz for Linux/macOS, zip for Windows)

2. **`build-advanced.yml`** - Advanced build workflow
   - Supports multiple Julia versions (v1.11.6, v1.10.0, v1.9.4)
   - Includes caching for faster builds
   - Comprehensive testing and package compatibility checks
   - Automatic release creation with platform-specific packages

3. **`quick-test.yml`** - Quick test workflow
   - Fast build for development and testing
   - Windows only, reduced parallel jobs
   - ~45 minute build time
   - Uses Julia v1.11.6

### Workflow Features

- **Automatic GPL library verification** on Linux builds
- **Package compatibility testing** with common Julia packages
- **Artifact uploads** for easy download of built binaries
- **Distribution package creation** for easy deployment
  - **Linux/macOS**: tar.gz packages
  - **Windows**: zip packages
- **Caching** to speed up subsequent builds

## Build Configuration Options

### Core Options
- `USE_GPL_LIBS=0`: Exclude GPL licensed libraries
- `USE_BLAS64=1`: Use 64-bit BLAS (recommended for large matrices)
- `USE_INTEL_MKL=0`: Use OpenBLAS instead of Intel MKL (better compatibility)

### Performance Options
- `JULIA_CPU_TARGET=native`: Optimize for current CPU
- `JULIA_CPU_TARGET=x86-64`: Generic x86-64 target
- `MAKEFLAGS=-j$(nproc)`: Use all CPU cores for building

### Debug Options
- `JULIA_DEBUG=1`: Enable debug symbols
- `VERBOSE=1`: Verbose build output

## Verification

After building, verify that GPL libraries are not included:

```bash
# Check for FFTW (should not be present)
ldd ./julia | grep fftw

# Check for GMP (should not be present)
ldd ./julia | grep gmp

# Check for MPFR (should not be present)
ldd ./julia | grep mpfr
```

## Performance Considerations

### What You Might Lose
- **FFTW**: Some FFT operations may be slower with MKL
- **GMP**: Large integer arithmetic may be slower
- **MPFR**: High-precision arithmetic may have reduced functionality

### What You Gain
- **License Freedom**: No GPL licensing restrictions
- **Commercial Use**: Can be used in proprietary software
- **Distribution**: Easier to distribute without GPL compliance concerns

## Troubleshooting

### Common Issues

#### Build Fails with MKL Error
```bash
# Solution: Use OpenBLAS instead
echo "USE_INTEL_MKL=0" >> Make.user
make clean
make
```

#### Memory Issues During Build
```bash
# Reduce parallel jobs
echo "MAKEFLAGS=-j2" >> Make.user
make clean
make
```

#### Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install libopenblas-dev liblapack-dev

# CentOS/RHEL
sudo yum install openblas-devel lapack-devel

# macOS
brew install openblas lapack
```

### Debug Build Issues
```bash
# Enable verbose output
make VERBOSE=1

# Check build logs
tail -f /tmp/julia-build.log
```

## Package Compatibility

Most Julia packages work with the non-GPL build, but some may have issues:

### Known Incompatibilities
- Packages that directly depend on FFTW
- Packages requiring GMP for arbitrary-precision arithmetic
- Packages using MPFR for high-precision floating-point

### Testing Packages
```bash
# Test core functionality
./julia -e "using LinearAlgebra; println(\"LinearAlgebra works\")"

# Test FFT functionality
./julia -e "using FFTW; println(\"FFT works\")"

# Test arbitrary-precision arithmetic
./julia -e "using Base.GMP; println(\"GMP works\")"
```

## Distribution

### Creating Distributable Builds

For distribution, you can create a tarball:

```bash
# Create distribution tarball
make dist

# Or create a custom distribution
make install prefix=/tmp/julia-nogpl
tar -czf julia-nogpl-$(./julia --version | cut -d' ' -f3).tar.gz -C /tmp julia-nogpl
```

### Docker Support

Create a Dockerfile for reproducible builds:

```dockerfile
FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    build-essential cmake git curl wget \
    libopenblas-dev liblapack-dev

WORKDIR /julia
RUN git clone https://github.com/JuliaLang/julia.git .

RUN echo "USE_GPL_LIBS=0" > Make.user && \
    echo "USE_BLAS64=1" >> Make.user && \
    echo "MAKEFLAGS=-j$(nproc)" >> Make.user

RUN make -j$(nproc)

ENV PATH="/julia:$PATH"
CMD ["julia"]
```

## Contributing

To contribute to this build process:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test the build process
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

- [Julia Build System Documentation](https://docs.julialang.org/en/v1/devdocs/build/)
- [Julia Source Code](https://github.com/JuliaLang/julia)
- [GPL License Information](https://www.gnu.org/licenses/gpl-3.0.en.html)

## Support

For issues with this build process:

1. Check the [Julia Discourse](https://discourse.julialang.org/)
2. Review the [Julia GitHub Issues](https://github.com/JuliaLang/julia/issues)
3. Create an issue in this repository

---

**Note**: This build configuration is for users who need to avoid GPL licensing restrictions. For most users, the standard Julia build with GPL libraries provides better performance and functionality. 