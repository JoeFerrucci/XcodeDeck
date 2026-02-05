import ArgumentParser
import Foundation

/// Build and launch the app on a simulator or device
public struct RunCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Build and launch the app on a simulator or device"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .shortAndLong, help: "Scheme to build and run")
    var scheme: String?

    @Option(name: .shortAndLong, help: "Destination (simulator name or device ID)")
    var destination: String?

    @Option(name: .shortAndLong, help: "Build configuration (Debug/Release)")
    var configuration: String = "Debug"

    @Option(name: .shortAndLong, help: "Path to .xcodeproj or .xcworkspace")
    var project: String?

    public init() {}

    public func run() async throws {
        let buildService = XcodeBuildService()
        let simService = SimulatorService()

        // Auto-discover scheme if not provided
        let targetScheme: String
        if let scheme {
            targetScheme = scheme
        } else {
            let schemes = try await buildService.discoverSchemes(projectPath: project)
            guard let first = schemes.first else {
                throw RunError.noSchemesFound
            }
            targetScheme = first
        }

        // Resolve simulator
        let simulator: Simulator
        if let destination {
            let simulators = try await simService.list()
            if let found = simulators.first(where: { $0.udid == destination || $0.name == destination }) {
                simulator = found
            } else {
                throw RunError.simulatorNotFound(destination)
            }
        } else {
            let simulators = try await simService.list()
            if let booted = simulators.first(where: { $0.state == "Booted" }) {
                simulator = booted
            } else {
                throw RunError.noBootedSimulator
            }
        }

        // Boot simulator if needed
        if simulator.state != "Booted" {
            if !globalOptions.json {
                print("🔄 Booting simulator \(simulator.name)...")
            }
            try await simService.boot(identifier: simulator.udid)
        }

        // Build
        if !globalOptions.json {
            print("🔨 Building \(targetScheme)...")
        }

        let buildResult = try await buildService.build(
            scheme: targetScheme,
            destination: "id=\(simulator.udid)",
            configuration: configuration,
            derivedDataPath: nil,
            projectPath: project
        )

        guard buildResult.success, let productPath = buildResult.productPath else {
            if globalOptions.format == .json {
                let response = JSONResponse<RunResult>.failure(ErrorInfo(
                    code: "BUILD_FAILED",
                    message: buildResult.errorMessage ?? "Build failed"
                ))
                print(response.encode())
            } else {
                print("❌ Build failed: \(buildResult.errorMessage ?? "Unknown error")")
            }
            return
        }

        // Install and launch
        if !globalOptions.json {
            print("📲 Installing on \(simulator.name)...")
        }

        try await simService.install(simulator: simulator, appPath: productPath)

        // Extract bundle ID from app
        let bundleId = try await extractBundleId(from: productPath)

        if !globalOptions.json {
            print("🚀 Launching \(bundleId)...")
        }

        try await simService.launch(simulator: simulator, bundleId: bundleId)

        let result = RunResult(
            scheme: targetScheme,
            simulator: simulator.name,
            bundleId: bundleId,
            productPath: productPath
        )

        if globalOptions.format == .json {
            let response = JSONResponse.success(result)
            print(response.encode())
        } else {
            print("✅ App launched successfully")
            print("   Simulator: \(simulator.name)")
            print("   Bundle ID: \(bundleId)")
        }
    }

    private func extractBundleId(from appPath: String) async throws -> String {
        let plistPath = "\(appPath)/Info.plist"
        let shell = ShellExecutor()
        let result = try await shell.run("defaults", arguments: ["read", plistPath, "CFBundleIdentifier"])
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RunResult: Encodable {
    let scheme: String
    let simulator: String
    let bundleId: String
    let productPath: String
}

enum RunError: LocalizedError {
    case noSchemesFound
    case simulatorNotFound(String)
    case noBootedSimulator

    var errorDescription: String? {
        switch self {
        case .noSchemesFound:
            return "No schemes found in the project"
        case let .simulatorNotFound(name):
            return "Simulator not found: \(name)"
        case .noBootedSimulator:
            return "No booted simulator found. Boot one with 'xcodedeck sim boot'"
        }
    }
}
