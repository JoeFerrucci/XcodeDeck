#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

echo "Building XcodeDeck..."
cd "$PROJECT_DIR"

# Initialize submodules if needed
if [ ! -f "$PROJECT_DIR/WebDriverAgent/WebDriverAgent.xcodeproj/project.pbxproj" ]; then
    echo "Initializing WebDriverAgent submodule..."
    git submodule update --init --recursive
fi

# Build release binary
swift build -c release

# Install binary
echo "Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
    cp ".build/release/xcodedeck" "$INSTALL_DIR/"
else
    echo "Requires sudo to install to $INSTALL_DIR"
    sudo cp ".build/release/xcodedeck" "$INSTALL_DIR/"
fi

echo "Installed xcodedeck to $INSTALL_DIR/xcodedeck"
echo ""
echo "Run 'xcodedeck --help' to get started."
