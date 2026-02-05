import Foundation

/// Service for managing WebDriverAgent lifecycle
public actor WDAService {
    /// Shared instance
    public static let shared = WDAService()

    private let shell: ShellExecutor
    private var wdaProcess: Process?
    private var wdaClient: WDAClient?
    private var currentPort: Int = 8100

    private init(shell: ShellExecutor = ShellExecutor()) {
        self.shell = shell
    }

    /// Check if WDA is currently running
    public var isRunning: Bool {
        get async {
            guard let client = wdaClient else { return false }
            return await client.isReady()
        }
    }

    /// Start WebDriverAgent on a simulator
    public func start(simulator: Simulator, port: Int = 8100) async throws {
        // Check if already running
        if await isRunning {
            return
        }

        self.currentPort = port

        // Find WDA project path
        let wdaPath = try await locateWDAProject()

        // Build WDA for the simulator
        try await buildWDA(wdaPath: wdaPath, simulatorUDID: simulator.udid)

        // Start WDA via xcodebuild test-without-building
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "xcodebuild",
            "-project", wdaPath,
            "-scheme", "WebDriverAgentRunner",
            "-destination", "id=\(simulator.udid)",
            "test-without-building"
        ]

        // Set environment for port
        var env = ProcessInfo.processInfo.environment
        env["USE_PORT"] = "\(port)"
        process.environment = env

        // Redirect output to /dev/null to run in background
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        self.wdaProcess = process

        // Wait for WDA to be ready
        try await waitForWDAReady(port: port)

        self.wdaClient = WDAClient(port: port)
    }

    /// Stop WebDriverAgent
    public func stop() async throws {
        wdaProcess?.terminate()
        wdaProcess = nil

        if let client = wdaClient {
            try await client.deleteSession()
        }
        wdaClient = nil
    }

    /// Get the WDA client
    public func client() async throws -> WDAClient {
        guard let client = wdaClient else {
            throw WDAServiceError.notRunning
        }
        return client
    }

    // MARK: - Private Helpers

    private func locateWDAProject() async throws -> String {
        // Check common locations
        let possiblePaths = [
            // Alongside XcodeDeck
            FileManager.default.currentDirectoryPath + "/WebDriverAgent/WebDriverAgent.xcodeproj",
            // In home directory
            NSHomeDirectory() + "/WebDriverAgent/WebDriverAgent.xcodeproj",
            // Homebrew location
            "/usr/local/lib/node_modules/appium/node_modules/appium-webdriveragent/WebDriverAgent.xcodeproj",
            // User Developer directory
            NSHomeDirectory() + "/Developer/WebDriverAgent/WebDriverAgent.xcodeproj",
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Try to find via Spotlight
        let result = try await shell.run("mdfind", arguments: ["-name", "WebDriverAgent.xcodeproj"])
        if result.succeeded {
            let paths = result.stdout.components(separatedBy: "\n").filter { !$0.isEmpty }
            if let first = paths.first {
                return first
            }
        }

        throw WDAServiceError.wdaNotFound
    }

    private func buildWDA(wdaPath: String, simulatorUDID: String) async throws {
        let result = try await shell.run("xcodebuild", arguments: [
            "-project", wdaPath,
            "-scheme", "WebDriverAgentRunner",
            "-destination", "id=\(simulatorUDID)",
            "-derivedDataPath", NSTemporaryDirectory() + "XcodeDeck/WDA",
            "build-for-testing"
        ])

        guard result.succeeded else {
            throw WDAServiceError.buildFailed(result.stderr)
        }
    }

    private func waitForWDAReady(port: Int, timeout: TimeInterval = 60) async throws {
        let startTime = Date()
        let statusURL = URL(string: "http://localhost:\(port)/status")!

        while Date().timeIntervalSince(startTime) < timeout {
            do {
                var request = URLRequest(url: statusURL)
                request.timeoutInterval = 2

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    // Parse response to check ready status
                    if let json = try? JSONDecoder().decode(WDAStatusResponse.self, from: data),
                       json.value.ready {
                        return
                    }
                }
            } catch {
                // WDA not ready yet, continue waiting
            }

            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        throw WDAServiceError.startupTimeout
    }
}

/// Errors from WDA service
public enum WDAServiceError: LocalizedError {
    case wdaNotFound
    case buildFailed(String)
    case startupTimeout
    case notRunning

    public var errorDescription: String? {
        switch self {
        case .wdaNotFound:
            return "WebDriverAgent project not found. Clone it from https://github.com/appium/WebDriverAgent"
        case let .buildFailed(message):
            return "Failed to build WebDriverAgent: \(message)"
        case .startupTimeout:
            return "WebDriverAgent failed to start within timeout"
        case .notRunning:
            return "WebDriverAgent is not running. Start it with a UI command first."
        }
    }
}
