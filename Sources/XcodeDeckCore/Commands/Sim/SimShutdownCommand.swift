import ArgumentParser
import Foundation

/// Shutdown simulator(s)
public struct SimShutdownCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "shutdown",
        abstract: "Shutdown a simulator or all simulators"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Argument(help: "Simulator name, UDID, or 'all'")
    var simulator: String = "all"

    public init() {}

    public func run() async throws {
        let service = SimulatorService()

        if simulator.lowercased() == "all" {
            try await service.shutdownAll()

            if globalOptions.format == .json {
                let data = SimActionData(action: "shutdown", simulator: "all", message: "All simulators shut down")
                let response = JSONResponse.success(data)
                print(response.encode())
            } else {
                print("✅ All simulators shut down")
            }
            return
        }

        // Find specific simulator
        let simulators = try await service.list()
        guard let target = simulators.first(where: {
            $0.udid == simulator || $0.name == simulator
        }) else {
            throw SimError.simulatorNotFound(simulator)
        }

        if target.state != "Booted" {
            if globalOptions.format == .json {
                let data = SimActionData(action: "shutdown", simulator: target.name, message: "Already shut down")
                let response = JSONResponse.success(data)
                print(response.encode())
            } else {
                print("ℹ️  \(target.name) is already shut down")
            }
            return
        }

        try await service.shutdown(identifier: target.udid)

        if globalOptions.format == .json {
            let data = SimActionData(action: "shutdown", simulator: target.name, message: "Shut down successfully")
            let response = JSONResponse.success(data)
            print(response.encode())
        } else {
            print("✅ Shut down \(target.name)")
        }
    }
}
