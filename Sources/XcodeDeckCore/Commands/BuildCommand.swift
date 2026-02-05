import ArgumentParser
import Foundation

/// Build the project for simulator, device, or macOS
public struct BuildCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the project for simulator, device, or macOS"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .shortAndLong, help: "Scheme to build")
    var scheme: String?

    @Option(name: .shortAndLong, help: "Build configuration (Debug/Release)")
    var configuration: String = "Debug"

    @Option(name: .shortAndLong, help: "Destination (simulator name, device ID, or 'macos')")
    var destination: String?

    @Option(name: .long, help: "Derived data path")
    var derivedDataPath: String?

    @Option(name: .shortAndLong, help: "Path to .xcodeproj or .xcworkspace")
    var project: String?

    public init() {}

    public func run() async throws {
        let service = XcodeBuildService()

        // Auto-discover scheme if not provided
        let targetScheme: String
        if let scheme {
            targetScheme = scheme
        } else {
            let schemes = try await service.discoverSchemes(projectPath: project)
            guard let first = schemes.first else {
                throw BuildError.noSchemesFound
            }
            targetScheme = first
        }

        // Build destination string
        let destString = try await resolveDestination()

        let result = try await service.build(
            scheme: targetScheme,
            destination: destString,
            configuration: configuration,
            derivedDataPath: derivedDataPath,
            projectPath: project
        )

        if globalOptions.format == .json {
            let response = JSONResponse.success(result)
            print(response.encode())
        } else {
            if result.success {
                print("✅ Build succeeded")
                print("   Scheme: \(result.scheme)")
                print("   Configuration: \(result.configuration)")
                print("   Duration: \(String(format: "%.1f", result.buildTime))s")
                if let path = result.productPath {
                    print("   Product: \(path)")
                }
            } else {
                print("❌ Build failed")
                if let errorMessage = result.errorMessage {
                    print("   Error: \(errorMessage)")
                }
            }
        }
    }

    private func resolveDestination() async throws -> String {
        if let destination {
            if destination.lowercased() == "macos" {
                return "platform=macOS"
            }
            // Check if it's a UUID (device/simulator ID)
            if destination.contains("-") && destination.count > 30 {
                return "id=\(destination)"
            }
            // Assume it's a simulator name
            return "platform=iOS Simulator,name=\(destination)"
        }

        // Default to first booted simulator or generic simulator
        let simService = SimulatorService()
        let simulators = try await simService.list()
        if let booted = simulators.first(where: { $0.state == "Booted" }) {
            return "id=\(booted.udid)"
        }
        return "platform=iOS Simulator,name=iPhone 17 Pro"
    }
}

enum BuildError: LocalizedError {
    case noSchemesFound

    var errorDescription: String? {
        switch self {
        case .noSchemesFound:
            return "No schemes found in the project"
        }
    }
}
