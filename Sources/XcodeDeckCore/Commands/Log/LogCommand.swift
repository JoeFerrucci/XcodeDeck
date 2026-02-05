import ArgumentParser
import Foundation

/// Log streaming commands
public struct LogCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "log",
        abstract: "Log streaming commands",
        subcommands: [
            LogStreamCommand.self,
        ],
        defaultSubcommand: LogStreamCommand.self
    )

    public init() {}
}

/// Stream real-time logs from a simulator
public struct LogStreamCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream real-time logs from a running app"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .long, help: "Simulator UDID (defaults to booted)")
    var simulator: String?

    @Option(name: .long, help: "Filter by subsystem (e.g., com.example.app)")
    var subsystem: String?

    @Option(name: .long, help: "Filter by process name")
    var process: String?

    @Option(name: .long, help: "Log level (debug, info, default, error, fault)")
    var level: String = "debug"

    public init() {}

    public func run() async throws {
        let simService = SimulatorService()
        let logService = LogStreamService()

        // Find target simulator
        let target: Simulator
        if let simulator {
            let simulators = try await simService.list()
            guard let found = simulators.first(where: {
                $0.udid == simulator || $0.name == simulator
            }) else {
                throw SimError.simulatorNotFound(simulator)
            }
            target = found
        } else {
            let simulators = try await simService.list()
            guard let booted = simulators.first(where: { $0.state == "Booted" }) else {
                throw LogError.noBootedSimulator
            }
            target = booted
        }

        // Build predicate
        var predicates: [String] = []
        if let subsystem {
            predicates.append("subsystem == '\(subsystem)'")
        }
        if let process {
            predicates.append("processImagePath endswith '\(process)'")
        }
        let predicate = predicates.isEmpty ? nil : predicates.joined(separator: " and ")

        if !globalOptions.json {
            print("📋 Streaming logs from \(target.name)...")
            print("   Press Ctrl+C to stop")
            print("")
        }

        // Stream logs
        for try await line in logService.stream(
            simulatorUDID: target.udid,
            level: level,
            predicate: predicate,
            jsonFormat: globalOptions.json
        ) {
            print(line)
        }
    }
}

enum LogError: LocalizedError {
    case noBootedSimulator

    var errorDescription: String? {
        switch self {
        case .noBootedSimulator:
            return "No booted simulator found. Boot one with 'xcodedeck sim boot'"
        }
    }
}
