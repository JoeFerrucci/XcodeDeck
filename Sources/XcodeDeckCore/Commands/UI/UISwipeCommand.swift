import ArgumentParser
import Foundation

/// Perform a swipe gesture
public struct UISwipeCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "swipe",
        abstract: "Perform a swipe gesture"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .long, help: "Start coordinates (x,y)")
    var from: String

    @Option(name: .long, help: "End coordinates (x,y)")
    var to: String

    @Option(name: .long, help: "Duration in seconds")
    var duration: Double = 0.5

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

        guard let fromCoords = parseCoordinates(from),
              let toCoords = parseCoordinates(to) else {
            throw SwipeError.invalidCoordinates
        }

        let client = try await wdaService.client()
        try await client.swipe(
            from: CGPoint(x: Double(fromCoords.x), y: Double(fromCoords.y)),
            to: CGPoint(x: Double(toCoords.x), y: Double(toCoords.y)),
            duration: duration
        )

        if globalOptions.format == .json {
            let data = SwipeData(
                from: SwipeData.Point(x: fromCoords.x, y: fromCoords.y),
                to: SwipeData.Point(x: toCoords.x, y: toCoords.y),
                duration: duration
            )
            let response = JSONResponse.success(data)
            print(response.encode())
        } else {
            print("✅ Swiped from (\(fromCoords.x),\(fromCoords.y)) to (\(toCoords.x),\(toCoords.y))")
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

struct SwipeData: Encodable {
    let from: Point
    let to: Point
    let duration: Double

    struct Point: Encodable {
        let x: Int
        let y: Int
    }
}

enum SwipeError: LocalizedError {
    case invalidCoordinates

    var errorDescription: String? {
        switch self {
        case .invalidCoordinates:
            return "Invalid coordinates format. Use 'x,y' (e.g., '100,200')"
        }
    }
}
