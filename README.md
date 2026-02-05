# XcodeDeck

A local, open-source alternative to FlowDeck for iOS development automation. XcodeDeck wraps native Apple tools (`xcodebuild`, `simctl`, `log stream`) and integrates WebDriverAgent for UI automation.

## Installation

### From Source

```bash
git clone --recursive https://github.com/yourorg/XcodeDeck.git
cd XcodeDeck
swift build -c release
cp .build/release/xcodedeck /usr/local/bin/
```

Or use the install script:

```bash
./Scripts/install.sh
```

### Dependencies

- macOS 13.0+
- Xcode Command Line Tools
- [WebDriverAgent](https://github.com/appium/WebDriverAgent) (included as submodule)

## Usage

All commands support `--json` for CI/CD integration.

### Project Context

Discover project schemes, targets, and simulators:

```bash
xcodedeck context --project MyApp.xcodeproj
xcodedeck context --json  # JSON output for scripts
```

### Build & Test

```bash
# Build project
xcodedeck build --scheme MyApp --destination "iPhone 17 Pro"

# Run tests
xcodedeck test --scheme MyApp --destination "iPhone 17 Pro"

# Build and launch app
xcodedeck run --scheme MyApp
```

### Simulator Management

```bash
# List all simulators
xcodedeck sim list
xcodedeck sim list --json

# Boot a simulator
xcodedeck sim boot "iPhone 17 Pro"
xcodedeck sim boot ABC123-UDID

# Shutdown simulators
xcodedeck sim shutdown "iPhone 17 Pro"
xcodedeck sim shutdown --all

# Take screenshot
xcodedeck sim screenshot --output screen.png
```

### Log Streaming

```bash
# Stream logs from booted simulator
xcodedeck log stream

# Filter by subsystem
xcodedeck log stream --subsystem com.example.MyApp

# Filter by log level
xcodedeck log stream --level error

# JSON format for parsing
xcodedeck log stream --json
```

### UI Automation (requires WebDriverAgent)

UI commands automatically start WebDriverAgent if not running.

```bash
# Tap at coordinates
xcodedeck ui tap --x 200 --y 400

# Tap element by accessibility identifier
xcodedeck ui tap --element "LoginButton" --bundle-id com.example.MyApp

# Swipe gesture
xcodedeck ui swipe --from 200,400 --to 200,100 --duration 0.5

# Take screenshot via WDA
xcodedeck ui screenshot --output screen.png
```

## JSON Output

All commands support `--json` for structured output:

```bash
xcodedeck sim list --json
```

```json
{
  "success": true,
  "data": {
    "simulators": [
      {
        "udid": "ABC123-DEF456",
        "name": "iPhone 17 Pro",
        "state": "Booted",
        "runtime": "iOS 26.0"
      }
    ]
  },
  "timestamp": "2026-02-05T12:00:00Z"
}
```

## WebDriverAgent Setup

WebDriverAgent is included as a git submodule. On first UI command, XcodeDeck will:

1. Locate the WDA project (checks common locations)
2. Build WDA for the target simulator
3. Start WDA and wait for it to be ready

If WDA is not found, clone it manually:

```bash
git clone https://github.com/appium/WebDriverAgent.git ~/Developer/WebDriverAgent
```

## Command Reference

| Command | Description |
|---------|-------------|
| `context` | Discover project schemes, targets, simulators |
| `build` | Build Xcode project |
| `test` | Run unit/UI tests |
| `run` | Build and launch app |
| `sim list` | List available simulators |
| `sim boot` | Boot a simulator |
| `sim shutdown` | Shutdown simulator(s) |
| `sim screenshot` | Capture simulator screenshot |
| `log stream` | Stream real-time logs |
| `ui tap` | Tap at coordinates or element |
| `ui swipe` | Perform swipe gesture |
| `ui screenshot` | Capture screenshot via WDA |

## License

GPL-3.0
