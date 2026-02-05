import ArgumentParser
import Foundation

/// Run unit/UI tests
public struct TestCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run unit or UI tests"
    )

    @OptionGroup var globalOptions: GlobalOptions

    @Option(name: .shortAndLong, help: "Scheme to test")
    var scheme: String?

    @Option(name: .shortAndLong, help: "Destination (simulator name or device ID)")
    var destination: String?

    @Option(name: .long, help: "Test plan file")
    var testPlan: String?

    @Option(name: .long, help: "Run only specific test (TestTarget/TestClass/testMethod)")
    var only: String?

    @Option(name: .long, help: "Result bundle path for detailed results")
    var resultBundle: String?

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
                throw TestError.noSchemesFound
            }
            targetScheme = first
        }

        // Resolve destination
        let destString = try await resolveDestination()

        let result = try await service.test(
            scheme: targetScheme,
            destination: destString,
            testPlan: testPlan,
            onlyTesting: only,
            resultBundlePath: resultBundle,
            projectPath: project
        )

        if globalOptions.format == .json {
            let response = JSONResponse.success(result)
            print(response.encode())
        } else {
            if result.success {
                print("✅ Tests passed")
                print("   Total: \(result.totalTests)")
                print("   Passed: \(result.passedTests)")
                print("   Failed: \(result.failedTests)")
                print("   Duration: \(String(format: "%.1f", result.duration))s")
            } else {
                print("❌ Tests failed")
                print("   Total: \(result.totalTests)")
                print("   Passed: \(result.passedTests)")
                print("   Failed: \(result.failedTests)")
                for failure in result.failures {
                    print("   - \(failure)")
                }
            }
        }
    }

    private func resolveDestination() async throws -> String {
        if let destination {
            if destination.contains("-") && destination.count > 30 {
                return "id=\(destination)"
            }
            return "platform=iOS Simulator,name=\(destination)"
        }

        let simService = SimulatorService()
        let simulators = try await simService.list()
        if let booted = simulators.first(where: { $0.state == "Booted" }) {
            return "id=\(booted.udid)"
        }
        return "platform=iOS Simulator,name=iPhone 17 Pro"
    }
}

enum TestError: LocalizedError {
    case noSchemesFound

    var errorDescription: String? {
        switch self {
        case .noSchemesFound:
            return "No schemes found in the project"
        }
    }
}
