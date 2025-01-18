#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/eye-micah/wine-vn-fixes.git"

echo "Cloning repository: $REPO_URL"
echo "Target directory: $(pwd)/wine-vn-fixes"

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git and try again."
    exit 1
fi

# Clone the repository with submodules into the current directory
git clone --recurse-submodules "$REPO_URL" ./wine-vn-fixes

echo "Repository successfully cloned to $(pwd)/wine-vn-fixes"

