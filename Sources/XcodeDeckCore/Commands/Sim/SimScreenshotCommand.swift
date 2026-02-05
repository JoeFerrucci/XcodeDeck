import ArgumentParser
import Foundation

/// Capture a screenshot from a simulator
public struct SimScreenshotCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Capture a screenshot from a simulator"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "screenshot.png"

    @Option(name: .shortAndLong, help: "Simulator name or UDID (defaults to booted)")
    var simulator: String?

    public init() {}

    public func run() async throws {
        let service = SimulatorService()

        // Find target simulator
        let target: Simulator
        if let simulator {
            let simulators = try await service.list()
            guard let found = simulators.first(where: {
                $0.udid == simulator || $0.name == simulator
            }) else {
                throw SimError.simulatorNotFound(simulator)
            }
            target = found
        } else {
            // Use first booted simulator
            let simulators = try await service.list()
            guard let booted = simulators.first(where: { $0.state == "Booted" }) else {
                throw ScreenshotError.noBootedSimulator
            }
            target = booted
        }

        // Ensure booted
        if target.state != "Booted" {
            throw ScreenshotError.simulatorNotBooted(target.name)
        }

        try await service.screenshot(identifier: target.udid, path: output)

        if globalOptions.format == .json {
            let data = ScreenshotData(path: output, simulator: target.name)
            let response = JSONResponse.success(data)
            print(response.encode())
        } else {
            print("✅ Screenshot saved to \(output)")
        }
    }
}

struct ScreenshotData: Encodable {
    let path: String
    let simulator: String
}

enum ScreenshotError: LocalizedError {
    case noBootedSimulator
    case simulatorNotBooted(String)

    var errorDescription: String? {
        switch self {
        case .noBootedSimulator:
            return "No booted simulator found. Boot one with 'xcodedeck sim boot'"
        case let .simulatorNotBooted(name):
            return "Simulator '\(name)' is not booted"
        }
    }
}
