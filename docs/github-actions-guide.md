# GitHub Actions Guide for Julia Build Without GPL Libraries

This guide explains how to use the GitHub Actions workflows in this repository to build Julia without GPL libraries.

## Overview

The GitHub Actions workflows automate the process of building Julia with the `USE_GPL_LIBS=0` option, making it easy to create GPL-free Julia distributions.

## Available Workflows

### 1. Quick Test Build (`quick-test.yml`)

**Purpose**: Fast testing and development
- **Platform**: Windows only
- **Julia Version**: v1.11.6
- **Build Time**: ~45 minutes
- **Use Case**: Development, testing changes, quick verification

**How to use**:
1. Go to Actions tab in your repository
2. Select "Quick Test Build"
3. Click "Run workflow"
4. Wait for completion and download Windows artifacts

### 2. Basic Build (`build.yml`)

**Purpose**: Standard builds for all platforms
- **Platforms**: Linux, macOS, Windows
- **Julia Version**: v1.11.6
- **Build Time**: 1-3 hours
- **Use Case**: Production builds, distribution
- **Packages**: tar.gz (Linux/macOS), zip (Windows)

**How to use**:
1. Go to Actions tab
2. Select "Build Julia Without GPL Libraries"
3. Click "Run workflow"
4. Configure options if needed
5. Wait for completion

### 3. Advanced Build (`build-advanced.yml`)

**Purpose**: Comprehensive builds with custom version support
- **Platforms**: Linux, macOS, Windows
- **Julia Versions**: Custom version (default: v1.11.6)
- **Build Time**: 2-4 hours
- **Features**: Caching, comprehensive testing, automatic releases
- **Use Case**: Production releases, custom version builds
- **Packages**: tar.gz (Linux/macOS), zip (Windows)
- **Release Creation**: Optional GitHub release with artifacts

**How to use**:
1. Go to Actions tab
2. Select "Advanced Julia Build Without GPL Libraries"
3. Click "Run workflow"
4. Configure:
   - Julia version
   - Platforms (comma-separated)
   - Build type (release/debug)

## Workflow Configuration

### Input Parameters

#### `julia_version`
- **Description**: Julia version to build (any valid Julia version)
- **Examples**: v1.11.6, v1.12.0, v1.10.0
- **Default**: v1.11.6
- **Note**: You can enter any Julia version that exists in the official repository

#### `platforms`
- **Description**: Platforms to build for
- **Options**: linux, macos, windows (comma-separated)
- **Default**: linux,macos,windows

#### `build_type`
- **Description**: Build type
- **Options**: release, debug
- **Default**: release

#### `create_release`
- **Description**: Whether to create a GitHub release
- **Options**: true, false
- **Default**: true
- **Note**: When enabled, creates a release with all built artifacts

### Build Configuration

All workflows use the same core configuration:

```makefile
# Build without GPL libraries
USE_GPL_LIBS=0

# Use 64-bit BLAS for better performance
USE_BLAS64=1

# Use OpenBLAS instead of MKL for better compatibility
USE_INTEL_MKL=0

# Optimize for current CPU
JULIA_CPU_TARGET=native

# Use all available CPU cores
MAKEFLAGS=-j$(nproc)

# Build type
JULIA_DEBUG=0  # or 1 for debug builds

# Enable verbose output
VERBOSE=1

# Optimization flags
CFLAGS=-O3
CXXFLAGS=-O3
LDFLAGS=-O3
```

## Using the Trigger Script

The `scripts/trigger-build.sh` script provides a command-line interface for triggering builds:

### Prerequisites

1. Install GitHub CLI: https://cli.github.com/
2. Authenticate: `gh auth login`

### Usage

```bash
# Make script executable
chmod +x scripts/trigger-build.sh

# Trigger with default settings
./scripts/trigger-build.sh

# Trigger with custom settings
./scripts/trigger-build.sh v1.11.6 "linux,macos" release true

# Trigger without creating a release
./scripts/trigger-build.sh v1.12.0 "linux,macos,windows" release false
```

### Script Options

- **Argument 1**: Julia version (default: v1.11.6)
- **Argument 2**: Platforms (default: linux,macos,windows)
- **Argument 3**: Build type (default: release)
- **Argument 4**: Create release (default: true)

## Monitoring Builds

### Build Progress

1. **GitHub Actions Tab**: Real-time progress
2. **Logs**: Detailed build logs for debugging
3. **Artifacts**: Download built binaries

### Common Build Times

- **Quick Test**: 45 minutes
- **Single Platform**: 1-2 hours
- **All Platforms**: 2-4 hours
- **Multiple Versions**: 4-6 hours

## Artifacts and Downloads

### Available Artifacts

1. **Julia Binary**: Direct executable
2. **Distribution Package**: Tarball with full installation
3. **Build Logs**: Detailed build information

### Download Locations

- **GitHub Actions**: Actions tab → Workflow run → Artifacts
- **Releases**: Automatic releases for advanced builds
- **Direct Links**: Available in workflow logs

## Troubleshooting

### Common Issues

#### Build Fails with Memory Error
- **Solution**: Reduce parallel jobs in Make.user
- **Workaround**: Use quick-test workflow

#### Missing Dependencies
- **Solution**: Check system dependencies in workflow
- **Workaround**: Use Linux runner (most reliable)

#### Timeout Issues
- **Solution**: Use quick-test for faster builds
- **Workaround**: Increase timeout in workflow

### Debug Steps

1. **Check Logs**: Detailed error messages in workflow logs
2. **Verify Configuration**: Check Make.user settings
3. **Test Locally**: Try manual build with same settings
4. **Check Dependencies**: Verify system packages

## Best Practices

### For Development
- Use `quick-test.yml` for rapid iteration
- Check logs for specific error messages
- Test locally before pushing changes

### For Production
- Use `build-advanced.yml` for comprehensive builds
- Test multiple Julia versions
- Verify package compatibility

### For Distribution
- Create releases with proper versioning
- Include multiple platforms
- Document any known limitations

## Integration with CI/CD

### Manual Triggers
- **Manual dispatch**: Full control over parameters
- **No automatic triggers**: All workflows must be manually started
- **Custom scheduling**: Can be integrated with external schedulers if needed

### Custom Workflows
You can create custom workflows by copying and modifying the existing ones:

```yaml
name: Custom Build
on:
  workflow_dispatch:
    inputs:
      julia_version:
        description: 'Julia version'
        required: true
        default: 'v1.11.6'
```

## Support

For issues with the workflows:

1. Check the workflow logs for error messages
2. Verify the configuration matches your requirements
3. Test with the quick-test workflow first
4. Create an issue in this repository with:
   - Workflow name and run ID
   - Error message or unexpected behavior
   - Steps to reproduce

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Julia Build System](https://docs.julialang.org/en/v1/devdocs/build/)
- [GitHub CLI Documentation](https://cli.github.com/) 