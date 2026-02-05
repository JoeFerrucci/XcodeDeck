import ArgumentParser
import Foundation

/// List available simulators
public struct SimListCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available simulators"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Flag(name: .long, help: "Show only booted simulators")
    var booted: Bool = false

    @Option(name: .long, help: "Filter by runtime (e.g., iOS-17-0)")
    var runtime: String?

    public init() {}

    public func run() async throws {
        let service = SimulatorService()
        var simulators = try await service.list()

        if booted {
            simulators = simulators.filter { $0.state == "Booted" }
        }

        if let runtime {
            simulators = simulators.filter { $0.runtime.contains(runtime) }
        }

        if globalOptions.format == .json {
            let data = SimulatorListData(simulators: simulators)
            let response = JSONResponse.success(data)
            print(response.encode())
        } else {
            if simulators.isEmpty {
                print("No simulators found")
                return
            }

            print("📱 Simulators")
            print("")

            // Group by runtime
            let grouped = Dictionary(grouping: simulators) { $0.runtime }
            for (runtime, sims) in grouped.sorted(by: { $0.key > $1.key }) {
                print("\(runtime):")
                for sim in sims {
                    let status = sim.state == "Booted" ? "🟢" : "⚪"
                    print("  \(status) \(sim.name) (\(sim.udid))")
                }
                print("")
            }
        }
    }
}

struct SimulatorListData: Encodable {
    let simulators: [Simulator]
}
