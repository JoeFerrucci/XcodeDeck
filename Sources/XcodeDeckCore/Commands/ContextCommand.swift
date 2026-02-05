import ArgumentParser
import Foundation

/// Discover project context (schemes, targets, simulators)
public struct ContextCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "context",
        abstract: "Discover project context (schemes, targets, simulators)"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .shortAndLong, help: "Path to .xcodeproj or .xcworkspace")
    var project: String?

    public init() {}

    public func run() async throws {
        let buildService = XcodeBuildService()
        let simService = SimulatorService()

        // Discover schemes
        let schemes = try await buildService.discoverSchemes(projectPath: project)

        // Get simulators
        let simulators = try await simService.list()
        let bootedSimulators = simulators.filter { $0.state == "Booted" }

        let context = ProjectContext(
            schemes: schemes,
            simulators: simulators.map { SimulatorInfo(from: $0) },
            bootedSimulators: bootedSimulators.map { $0.name },
            xcodeVersion: try await getXcodeVersion()
        )

        if globalOptions.format == .json {
            let response = JSONResponse.success(context)
            print(response.encode())
        } else {
            print("📱 XcodeDeck Context")
            print("")
            print("Xcode: \(context.xcodeVersion)")
            print("")
            print("Schemes:")
            for scheme in context.schemes {
                print("  - \(scheme)")
            }
            print("")
            print("Booted Simulators:")
            if context.bootedSimulators.isEmpty {
                print("  (none)")
            } else {
                for sim in context.bootedSimulators {
                    print("  - \(sim)")
                }
            }
            print("")
            print("Available Simulators: \(context.simulators.count)")
        }
    }

    private func getXcodeVersion() async throws -> String {
        let shell = ShellExecutor()
        let result = try await shell.run("xcodebuild", arguments: ["-version"])
        let lines = result.stdout.components(separatedBy: "\n")
        return lines.first ?? "Unknown"
    }
}

struct ProjectContext: Encodable {
    let schemes: [String]
    let simulators: [SimulatorInfo]
    let bootedSimulators: [String]
    let xcodeVersion: String
}

struct SimulatorInfo: Encodable {
    let udid: String
    let name: String
    let state: String
    let runtime: String

    init(from simulator: Simulator) {
        self.udid = simulator.udid
        self.name = simulator.name
        self.state = simulator.state
        self.runtime = simulator.runtime
    }
}
