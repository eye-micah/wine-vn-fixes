#!/usr/bin/env bash

set -euo pipefail

# Define Wine prefix and executable path
WINEPREFIX="$HOME/.wine-muramasa"
GAME_DIR="$WINEPREFIX/drive_c/Program Files/Full Metal Daemon Muramasa"
GAME_EXECUTABLE="muramasa_en.exe"



# Check if the game executable exists
if [[ ! -f "$GAME_EXECUTABLE" ]]; then
    echo "Error: Game executable not found at $GAME_EXECUTABLE"
    exit 1
fi

# Run the game with WINEESYNC and WINEFSYNC disabled
echo "Launching Full Metal Daemon Muramasa..."
cd $GAME_DIR
LANG=ja_JP.UTF-8 WINEDLLOVERRIDES="xaudio2_8=n" WINEESYNC=0 WINEFSYNC=0 WINEPREFIX="$WINEPREFIX" wine "$GAME_EXECUTABLE"

