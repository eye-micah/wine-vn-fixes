#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/your-username/your-repo.git"
TARGET_DIR="./wine-vn-fixes"

echo "Cloning repository: $REPO_URL"
echo "Target directory: $(pwd)/$TARGET_DIR"

# Function to detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            debian|ubuntu) echo "debian" ;;
            arch|manjaro) echo "arch" ;;
            *) echo "unsupported" ;;
        esac
    else
        echo "unsupported"
    fi
}

# Function to install git if necessary
install_git() {
    local distro="$1"
    case "$distro" in
        debian)
            echo "Installing Git for Debian-based system..."
            sudo apt update
            sudo apt install -y git
            ;;
        arch)
            echo "Installing Git for Arch-based system..."
            sudo pacman -Syu --needed --noconfirm git
            ;;
        *)
            echo "Error: Unsupported distribution for auto-installing Git."
            exit 1
            ;;
    esac
}

# Ensure git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Detecting distribution to install Git..."
    distro=$(detect_distro)
    if [[ "$distro" == "unsupported" ]]; then
        echo "Error: Unsupported Linux distribution. Please install Git manually and try again."
        exit 1
    fi
    install_git "$distro"
fi

# Clone the repository with submodules into the ./wine-vn-fixes directory
if [[ -d "$TARGET_DIR" ]]; then
    echo "Error: Target directory $TARGET_DIR already exists."
    exit 1
fi

git clone --recurse-submodules "$REPO_URL" "$TARGET_DIR"

echo "Repository successfully cloned to $(pwd)/$TARGET_DIR"

