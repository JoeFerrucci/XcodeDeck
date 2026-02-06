#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
VERSION_FILE="$PROJECT_DIR/Sources/XcodeDeckCore/Version.swift"

# Get version from VERSION file
VERSION=$(cat "$PROJECT_DIR/VERSION")
COMMIT_HASH=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
DIRTY_FLAG=$(git -C "$PROJECT_DIR" diff --quiet 2>/dev/null && git -C "$PROJECT_DIR" diff --cached --quiet 2>/dev/null || echo "-dirty")
BUILD_ID="${COMMIT_HASH}${DIRTY_FLAG}"

echo "Building XcodeDeck v${VERSION} (${BUILD_ID})..."
cd "$PROJECT_DIR"

# Generate Version.swift
cat > "$VERSION_FILE" << EOF
import Foundation

/// Version information for XcodeDeck
public enum Version {
    public static let version = "${VERSION}"
    public static let build = "${BUILD_ID}"
    public static var fullVersion: String { "\\(version) (\\(build))" }
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
echo "Installed xcodedeck v${VERSION} (${BUILD_ID}) to $INSTALL_DIR/xcodedeck"
echo "Run 'xcodedeck --version' to verify."
