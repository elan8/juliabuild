#!/bin/bash

# Script to trigger GitHub Actions builds for Julia without GPL libraries
# Usage: ./trigger-build.sh [julia_version] [platforms] [build_type] [create_release]

set -e

# Default values
JULIA_VERSION=${1:-"v1.11.6"}
PLATFORMS=${2:-"linux,macos,windows"}
BUILD_TYPE=${3:-"release"}
CREATE_RELEASE=${4:-"true"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Triggering Julia build without GPL libraries...${NC}"
echo -e "${YELLOW}Version:${NC} $JULIA_VERSION"
echo -e "${YELLOW}Platforms:${NC} $PLATFORMS"
echo -e "${YELLOW}Build Type:${NC} $BUILD_TYPE"
echo -e "${YELLOW}Create Release:${NC} $CREATE_RELEASE"
echo

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo -e "${GREEN}Repository:${NC} $REPO"
echo

# Trigger the workflow
echo -e "${YELLOW}Triggering workflow...${NC}"
gh workflow run build-advanced.yml \
    --field julia_version="$JULIA_VERSION" \
    --field platforms="$PLATFORMS" \
    --field build_type="$BUILD_TYPE" \
    --field create_release="$CREATE_RELEASE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Workflow triggered successfully!${NC}"
    echo
    echo -e "${YELLOW}You can monitor the build progress at:${NC}"
    echo "https://github.com/$REPO/actions"
else
    echo -e "${RED}✗ Failed to trigger workflow${NC}"
    exit 1
fi

echo
echo -e "${GREEN}Build configuration:${NC}"
echo "- Julia version: $JULIA_VERSION"
echo "- Platforms: $PLATFORMS"
echo "- Build type: $BUILD_TYPE"
echo "- Create release: $CREATE_RELEASE"
echo "- GPL libraries: Excluded (USE_GPL_LIBS=0)"
echo
echo -e "${YELLOW}Note:${NC} The build may take 1-3 hours depending on the platforms selected." 