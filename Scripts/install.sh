#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
VERSION_FILE="$PROJECT_DIR/Sources/XcodeDeckCore/Version.swift"

# Get version from VERSION file
VERSION=$(cat "$PROJECT_DIR/VERSION")

echo "Building XcodeDeck v${VERSION}..."
cd "$PROJECT_DIR"

# Generate Version.swift
cat > "$VERSION_FILE" << EOF
import Foundation

/// Version information for XcodeDeck
public enum Version {
    public static let version = "${VERSION}"
    public static var fullVersion: String { version }
}
EOF

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

echo ""
echo "Installed xcodedeck v${VERSION} to $INSTALL_DIR/xcodedeck"
echo "Run 'xcodedeck --version' to verify."
