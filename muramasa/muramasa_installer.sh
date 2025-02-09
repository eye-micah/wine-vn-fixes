#!/usr/bin/env bash

set -euo pipefail

# Default Wine prefix and installer executable
WINEPREFIX="${HOME}/.wine-muramasa"
INSTALLER_EXE=""

# Function to print usage
usage() {
    echo "Usage: $0 --installer-exe INSTALLER_EXE"
    echo
    echo "  --installer-exe INSTALLER_EXE  Path to the game installer executable (required)"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --installer-exe)
            if [[ $# -lt 2 ]]; then
                echo "Error: --installer-exe requires a value."
                usage
            fi
            INSTALLER_EXE="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Validate arguments
if [[ -z "$INSTALLER_EXE" ]]; then
    echo "Error: --installer-exe is required."
    usage
fi

if [[ ! -f "$INSTALLER_EXE" ]]; then
    echo "Error: Installer file $INSTALLER_EXE not found."
    exit 1
fi

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        case "$ID" in
            debian) echo "debian" ;;
            ubuntu | pop | linuxmint) echo "ubuntu" ;;
            arch | manjaro | endeavouros) echo "arch" ;;
            *) echo "unsupported" ;;
        esac
    else
        echo "unsupported"
    fi
}

is_dpkg_available() {
        apt-cache show "$1" > /dev/null 2>&1
}

# Install Wine based on distribution
install_wine() {
    local distro="$1"
    
    local codename
    if [[ ! -f /etc/upstream-release/lsb-release ]]; then
	codename=$(lsb_release -c | awk '{print $2}')
    else
	codename=$(grep "^DISTRIB_CODENAME=" /etc/upstream-release/lsb-release | cut -d'=' -f2)
    fi
    case "$distro" in
        debian | ubuntu)
	    sudo mkdir -pm755 /etc/apt/keyrings
            sudo mkdir -pm755 /etc/apt/keyrings

            # Check if the WineHQ keyring already exists
            if [[ ! -f /etc/apt/keyrings/winehq-archive.key ]]; then
                echo "Importing WineHQ keyring..."
                wget -O - https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
            else
                echo "WineHQ keyring already exists. Skipping import."
            fi
            sudo dpkg --add-architecture i386
            sudo apt update
	    if [[ ! -f /etc/apt/sources.list.d/winehq-${codename}.sources ]]; then
	        echo "Importing WineHQ repo..."
                sudo wget -NP /etc/apt/sources.list.d/ "https://dl.winehq.org/wine-builds/ubuntu/dists/${codename}/winehq-${codename}.sources"
	    else
	        echo "WineHQ repo already exists. Skipping import."
	    fi
            sudo apt update
	    # Check if winehq-stable is available in the repositories
	    if is_dpkg_available "winehq-stable"; then
	        echo "winehq-stable is available in the repositories. Installing it."
	        sudo apt update
	        sudo apt install -y --install-recommends winehq-stable winetricks
	    else
	        echo "winehq-stable is not available in the repositories. Installing wine from apt repo instead. You may remove the WineHQ repository manually or wait for the stable package to appear in your distro."
		sudo apt install -y --install-recommends wine wine32 wine64 winetricks
	    fi
	    sudo apt install --install-recommends vulkan-icd:i386 libgl1:i386
            ;;
        arch)
            sudo pacman -Syu --needed --noconfirm wine wine-mono wine-gecko winetricks
            ;;
        *)
            echo "Error: Unsupported distribution."
            exit 1
            ;;
    esac
}

# Configure Wine prefix
setup_wineprefix() {
    echo "Setting up Wine prefix at $WINEPREFIX..."
    mkdir -p "$WINEPREFIX"
    WINEPREFIX="$WINEPREFIX" wineboot --init

    echo "Installing required dependencies using Winetricks..."
    WINEPREFIX="$WINEPREFIX" winetricks -q dxvk
}

# Run the installer executable
run_installer() {
    echo "Running the installer: $INSTALLER_EXE"
    echo " "
    echo "   !!! Note: DO NOT RUN THE GAME YET! INSTALL TO THE DEFAULT LOCATION IT PROVIDES !!! "
    echo " "
    WINEPREFIX="$WINEPREFIX" wine "$INSTALLER_EXE"
}

# Copy xaudio2_8.dll
xaudio_dll() {
    echo "Copying over xaudio2_8.dll..."
    local target_dir="$WINEPREFIX/drive_c/Program Files/Full Metal Daemon Muramasa"
    if [[ ! -f "./xaudio2_8.dll" ]]; then
        echo "Error: xaudio2_8.dll not found in the current directory."
        exit 1
    fi
    if [[ ! -d "$target_dir" ]]; then
        echo "Error: Target directory $target_dir does not exist."
        exit 1
    fi
    cp ./xaudio2_8.dll "$target_dir"
}

# Install Media Foundation
mf_install() {
    echo "Installing Media Foundation..."
    if [[ ! -d "../mf-install" || ! -d "../mf-installcab" ]]; then
        echo "Error: Media Foundation installation scripts not found."
        exit 1
    fi

    cd ../mf-install
    chmod +x ./mf-install.sh
    WINEPREFIX="$WINEPREFIX" sh ./mf-install.sh
    popd > /dev/null

    pushd ../mf-installcab
    local file="install-mf-64.sh"
    if grep -q "python2" "$file"; then
        sed -i 's/python2/python3/g' "$file"
        echo "Replaced python2 with python3 in $file"
    else
        echo "No 'python2' found in $file. No changes made."
    fi
    chmod +x ./install-mf-64.sh
    WINEPREFIX="$WINEPREFIX" sh ./install-mf-64.sh &>/dev/null
    ls "$WINEPREFIX/drive_c/Program Files/Full Metal Daemon Muramasa/"
    popd
}

main() {
    echo "Detecting distribution..."
    local distro
    distro=$(detect_distro)
    if [[ "$distro" == "unsupported" ]]; then
        echo "Error: Unsupported Linux distribution."
        exit 1
    fi

    echo "Installing Wine for $distro..."
    install_wine "$distro"

    echo "Configuring Wine prefix..."
    setup_wineprefix

    echo "Running the game installer..."
    run_installer

    echo "Copying necessary DLLs..."
    xaudio_dll

    echo "Installing Media Foundation..."
    mf_install
}

main

