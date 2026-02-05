import ArgumentParser
import Foundation

/// Capture a screenshot via WebDriverAgent
public struct UIScreenshotCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Capture a screenshot via WebDriverAgent"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "screenshot.png"

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
            if !globalOptions.json {
                print("🔄 Starting WebDriverAgent...")
            }
            try await wdaService.start(simulator: sim)
        }

        let client = try await wdaService.client()
        let imageData = try await client.screenshot()

        // Save to file
        let url = URL(fileURLWithPath: output)
        try imageData.write(to: url)

        if globalOptions.format == .json {
            let data = ScreenshotData(path: output, simulator: sim.name)
            let response = JSONResponse.success(data)
            print(response.encode())
        } else {
            print("✅ Screenshot saved to \(output)")
        }
    }
}
