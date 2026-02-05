import ArgumentParser
import Foundation

/// Tap at coordinates or on an element
public struct UITapCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "tap",
        abstract: "Tap at coordinates or on an element"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "Element accessibility ID or coordinates (x,y)")
    var target: String

    @Option(name: .long, help: "App bundle ID (required for element lookup)")
    var bundleId: String?

    @Option(name: .long, help: "Simulator UDID (defaults to booted)")
    var simulator: String?

    public init() {}

    public func run() async throws {
        let wdaService = WDAService.shared
        let simService = SimulatorService()

        // Find target simulator
        let sim: Simulator
        if let simulator {
            let simulators = try await simService.list()
            guard let found = simulators.first(where: {
                $0.udid == simulator || $0.name == simulator
            }) else {
                throw SimError.simulatorNotFound(simulator)
            }
            sim = found
        } else {
            let simulators = try await simService.list()
            guard let booted = simulators.first(where: { $0.state == "Booted" }) else {
                throw UIError.noBootedSimulator
            }
            sim = booted
        }

        // Ensure WDA is running
        if await !wdaService.isRunning {
            try await wdaService.start(simulator: sim)
        }

        let client = try await wdaService.client()

        // Create session if bundle ID provided
        if let bundleId {
            _ = try await client.createSession(bundleId: bundleId)
        }

        // Parse target as coordinates or element ID
        if let coordinates = parseCoordinates(target) {
            try await client.tap(x: coordinates.x, y: coordinates.y)

            if globalOptions.format == .json {
                let data = UIActionData(action: "tap", target: target, coordinates: coordinates)
                let response = JSONResponse.success(data)
                print(response.encode())
            } else {
                print("✅ Tapped at (\(coordinates.x), \(coordinates.y))")
            }
        } else {
            // Find and tap element
            let element = try await client.findElement(using: .accessibilityId, value: target)
            try await client.tap(element: element)

            if globalOptions.format == .json {
                let data = UIActionData(action: "tap", target: target, coordinates: nil)
                let response = JSONResponse.success(data)
                print(response.encode())
            } else {
                print("✅ Tapped element '\(target)'")
            }
        }
    }

    private func parseCoordinates(_ string: String) -> (x: Int, y: Int)? {
        let parts = string.split(separator: ",")
        guard parts.count == 2,
              let x = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let y = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        return (x, y)
    }
}

struct UIActionData: Encodable {
    let action: String
    let target: String
    let coordinates: Coordinates?

    struct Coordinates: Encodable {
        let x: Int
        let y: Int
    }

    init(action: String, target: String, coordinates: (x: Int, y: Int)?) {
        self.action = action
        self.target = target
        self.coordinates = coordinates.map { Coordinates(x: $0.x, y: $0.y) }
    }
}

enum UIError: LocalizedError {
    case noBootedSimulator
    case wdaNotRunning

    var errorDescription: String? {
        switch self {
        case .noBootedSimulator:
            return "No booted simulator found. Boot one with 'xcodedeck sim boot'"
        case .wdaNotRunning:
            return "WebDriverAgent is not running"
        }
    }
}
