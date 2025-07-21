# Julia Windows Build Scripts

These scripts allow you to build Julia on your Windows machine using the same approach as the official Julia Buildkite process.

## Prerequisites

Before running the scripts, make sure you have the following installed:

1. **Docker Desktop for Windows**
   - Download from: https://www.docker.com/products/docker-desktop
   - Make sure Docker Desktop is running
   - Enable WSL 2 backend (recommended)

2. **Git for Windows**
   - Download from: https://git-scm.com/download/win
   - Make sure Git is in your PATH

3. **PowerShell** (for PowerShell script)
   - Usually pre-installed on Windows 10/11
   - Or download from: https://github.com/PowerShell/PowerShell/releases

## Available Scripts

### 1. PowerShell Script (Recommended)
- **File**: `build-julia-windows.ps1`
- **Usage**: More reliable on modern Windows systems
- **Features**: Better error handling, colored output, parameter support

### 2. Batch Script
- **File**: `build-julia-windows.bat`
- **Usage**: Works on all Windows versions
- **Features**: Simple batch file, basic error handling

## Usage

### PowerShell Script (Recommended)

```powershell
# Run with default settings (Julia v1.11.6)
.\build-julia-windows.ps1

# Run with custom Julia version
.\build-julia-windows.ps1 -JuliaVersion "v1.12.0"

# Run with custom build type
.\build-julia-windows.ps1 -BuildType "debug"

# Run with all custom parameters
.\build-julia-windows.ps1 -JuliaVersion "v1.12.0" -BuildType "debug"
```

### Batch Script

```cmd
# Run with default settings
build-julia-windows.bat

# To modify settings, edit the variables at the top of the file:
# set JULIA_VERSION=v1.12.0
# set BUILD_TYPE=debug
```

## What the Scripts Do

1. **Check Prerequisites**: Verify Docker and Git are installed
2. **Pull Docker Image**: Download the official Julia Windows build image
3. **Clone Source**: Download Julia source code for the specified version
4. **Configure Build**: Create `Make.user` with proper settings
5. **Build Julia**: Run the build process inside Docker
6. **Test Build**: Verify the build works correctly
7. **Create Package**: Generate distribution files

## Build Configuration

The scripts use the same configuration as the official Julia build:

```makefile
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
```

## Output Files

After a successful build, you'll find:

1. **`julia-windows-package/julia.exe`** - The Julia executable
2. **`julia-windows-package/README.txt`** - Build information
3. **`julia-windows-v1.11.6.zip`** - Distribution package

## Troubleshooting

### Common Issues

1. **Docker not found**
   - Make sure Docker Desktop is installed and running
   - Check that Docker is in your PATH

2. **Git not found**
   - Install Git for Windows
   - Make sure Git is in your PATH

3. **Docker image pull fails**
   - Check your internet connection
   - Make sure Docker Desktop is running
   - Try running `docker pull juliapackaging/package-windows-x86_64:v7.10` manually

4. **Build fails**
   - Check the error messages in the output
   - Make sure you have enough disk space (at least 5GB free)
   - Try running with fewer parallel jobs by editing `MAKEFLAGS=-j1`

5. **Permission errors**
   - Run PowerShell as Administrator
   - Make sure Docker has permission to access your drives

### Performance Tips

1. **Use WSL 2 Backend**: Enable WSL 2 in Docker Desktop for better performance
2. **Allocate More Resources**: Give Docker more RAM and CPU cores in Docker Desktop settings
3. **Use SSD**: Build on an SSD for faster I/O
4. **Close Other Applications**: Free up system resources during the build

## Build Time

- **First build**: ~2-3 hours (downloads dependencies)
- **Subsequent builds**: ~1-2 hours (uses cached dependencies)
- **Build time varies** based on your system specifications

## Comparison with Official Build

This approach uses the **exact same method** as the official Julia Buildkite process:

- ✅ Same Docker image: `juliapackaging/package-windows-x86_64:v7.10`
- ✅ Same build configuration
- ✅ Same dependencies and toolchain
- ✅ Same testing and verification process

The only difference is that we run it locally instead of in CI/CD.

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Look at the error messages in the script output
3. Try running the Docker commands manually to isolate the issue
4. Check the [official Julia Windows build documentation](https://docs.julialang.org/en/v1/devdocs/build/windows/)

## License

These scripts are provided as-is for building Julia on Windows. They follow the official Julia build process and use the same Docker images and configuration as the official Julia CI/CD pipeline. 