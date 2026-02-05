import ArgumentParser
import Foundation

/// Boot a simulator
public struct SimBootCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "boot",
        abstract: "Boot a simulator"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "Simulator name or UDID")
    var simulator: String

    public init() {}

    public func run() async throws {
        let service = SimulatorService()

        // Find the simulator
        let simulators = try await service.list()
        guard let target = simulators.first(where: {
            $0.udid == simulator || $0.name == simulator
        }) else {
            throw SimError.simulatorNotFound(simulator)
        }

        if target.state == "Booted" {
            if globalOptions.format == .json {
                let data = SimActionData(action: "boot", simulator: target.name, message: "Already booted")
                let response = JSONResponse.success(data)
                print(response.encode())
            } else {
                print("ℹ️  \(target.name) is already booted")
            }
            return
        }

        try await service.boot(identifier: target.udid)

        if globalOptions.format == .json {
            let data = SimActionData(action: "boot", simulator: target.name, message: "Booted successfully")
            let response = JSONResponse.success(data)
            print(response.encode())
        } else {
            print("✅ Booted \(target.name)")
        }
    }
}

struct SimActionData: Encodable {
    let action: String
    let simulator: String
    let message: String
}

enum SimError: LocalizedError {
    case simulatorNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .simulatorNotFound(name):
            return "Simulator not found: \(name)"
        }
    }
}
