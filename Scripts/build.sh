#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$PROJECT_DIR/Sources/XcodeDeckCore/Version.swift"

# Get version info
VERSION=$(cat "$PROJECT_DIR/VERSION")
BUILD_TIMESTAMP=$(date +"%Y%m%d.%H%M")
COMMIT_COUNT=$(git -C "$PROJECT_DIR" rev-list --count HEAD 2>/dev/null || echo "0")
COMMIT_HASH=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
DIRTY_FLAG=$(git -C "$PROJECT_DIR" diff --quiet 2>/dev/null && git -C "$PROJECT_DIR" diff --cached --quiet 2>/dev/null || echo "+dirty")
GIT_INFO="${COMMIT_COUNT}-${COMMIT_HASH}${DIRTY_FLAG}"

cd "$PROJECT_DIR"

# Generate Version.swift with build info
cat > "$VERSION_FILE" << EOF
import Foundation

/// Version information for XcodeDeck
public enum Version {
    /// Semantic version (major.minor.patch)
    public static let version = "${VERSION}"

    /// Build timestamp (YYYYMMDD.HHMM)
    public static let timestamp = "${BUILD_TIMESTAMP}"

    /// Git info (commits-hash+dirty)
    public static let gitInfo = "${GIT_INFO}"

    /// Full version string for display
    public static var fullVersion: String {
        "\\(version) (\\(gitInfo) \\(timestamp))"
    }
}
EOF

# Pass through any arguments to swift build
swift build "$@"
