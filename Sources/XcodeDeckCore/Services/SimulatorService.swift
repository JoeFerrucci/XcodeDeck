import Foundation

/// Service for managing iOS Simulators via xcrun simctl
public actor SimulatorService {
    private let shell: ShellExecutor

    public init(shell: ShellExecutor = ShellExecutor()) {
        self.shell = shell
    }

    /// List all available simulators
    public func list() async throws -> [Simulator] {
        let result = try await shell.xcrun("simctl", arguments: ["list", "--json", "devices"])

        guard result.succeeded else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }

        guard let data = result.stdout.data(using: .utf8) else {
            throw SimulatorServiceError.invalidOutput
        }

        let decoder = JSONDecoder()
        let output = try decoder.decode(SimctlListOutput.self, from: data)

        var simulators: [Simulator] = []
        for (runtime, devices) in output.devices {
            // Extract runtime name from identifier (e.g., "com.apple.CoreSimulator.SimRuntime.iOS-17-0" -> "iOS 17.0")
            let runtimeName = formatRuntime(runtime)

            for device in devices {
                simulators.append(Simulator(
                    udid: device.udid,
                    name: device.name,
                    state: device.state,
                    runtime: runtimeName,
                    deviceTypeIdentifier: device.deviceTypeIdentifier
                ))
            }
        }

        return simulators.sorted { $0.name < $1.name }
    }

    /// Boot a simulator by identifier
    public func boot(identifier: String) async throws {
        let result = try await shell.xcrun("simctl", arguments: ["boot", identifier])

        guard result.succeeded || result.stderr.contains("current state: Booted") else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }
    }

    /// Shutdown a simulator by identifier
    public func shutdown(identifier: String) async throws {
        let result = try await shell.xcrun("simctl", arguments: ["shutdown", identifier])

        guard result.succeeded || result.stderr.contains("current state: Shutdown") else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }
    }

    /// Shutdown all simulators
    public func shutdownAll() async throws {
        let result = try await shell.xcrun("simctl", arguments: ["shutdown", "all"])

        guard result.succeeded else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }
    }

    /// Take a screenshot
    public func screenshot(identifier: String, path: String) async throws {
        let result = try await shell.xcrun("simctl", arguments: ["io", identifier, "screenshot", path])

        guard result.succeeded else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }
    }

    /// Install an app on a simulator
    public func install(simulator: Simulator, appPath: String) async throws {
        let result = try await shell.xcrun("simctl", arguments: ["install", simulator.udid, appPath])

        guard result.succeeded else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }
    }

    /// Launch an app on a simulator
    public func launch(simulator: Simulator, bundleId: String) async throws {
        let result = try await shell.xcrun("simctl", arguments: ["launch", simulator.udid, bundleId])

        guard result.succeeded else {
            throw SimulatorServiceError.commandFailed(result.stderr)
        }
    }

    private func formatRuntime(_ identifier: String) -> String {
        // Convert "com.apple.CoreSimulator.SimRuntime.iOS-17-0" to "iOS 17.0"
        let parts = identifier.components(separatedBy: ".")
        guard let last = parts.last else { return identifier }

        return last
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "iOS ", with: "iOS ")
            .replacingOccurrences(of: " ", with: ".", range: last.range(of: " [0-9]", options: .regularExpression))
    }
}

enum SimulatorServiceError: LocalizedError {
    case commandFailed(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case let .commandFailed(message):
            return "Simulator command failed: \(message)"
        case .invalidOutput:
            return "Invalid output from simctl"
        }
    }
}
