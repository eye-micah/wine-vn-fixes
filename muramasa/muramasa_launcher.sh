#!/usr/bin/env bash

set -euo pipefail

# Define Wine prefix and executable path
WINEPREFIX="$HOME/.wine-muramasa"
GAME_EXECUTABLE="$WINEPREFIX/drive_c/Program Files/Full Metal Daemon Muramasa/muramasa_en.exe"

# Check if the game executable exists
if [[ ! -f "$GAME_EXECUTABLE" ]]; then
    echo "Error: Game executable not found at $GAME_EXECUTABLE"
    exit 1
fi

# Run the game with WINEESYNC and WINEFSYNC disabled
echo "Launching Full Metal Daemon Muramasa..."
WINEDLLOVERRIDES="xaudio2_8=n" WINEESYNC=0 WINEFSYNC=0 WINEPREFIX="$WINEPREFIX" wine "$GAME_EXECUTABLE"

