import Foundation

/// Service for building and testing via xcodebuild
public actor XcodeBuildService {
    private let shell: ShellExecutor

    public init(shell: ShellExecutor = ShellExecutor()) {
        self.shell = shell
    }

    /// Discover available schemes in the project
    public func discoverSchemes(projectPath: String?) async throws -> [String] {
        var args = ["-list", "-json"]

        if let projectPath {
            if projectPath.hasSuffix(".xcworkspace") {
                args += ["-workspace", projectPath]
            } else {
                args += ["-project", projectPath]
            }
        }

        let result = try await shell.run("xcodebuild", arguments: args)

        guard result.succeeded else {
            throw XcodeBuildError.commandFailed(result.stderr)
        }

        guard let data = result.stdout.data(using: .utf8) else {
            throw XcodeBuildError.invalidOutput
        }

        struct ListOutput: Codable {
            let project: ProjectInfo?
            let workspace: WorkspaceInfo?

            struct ProjectInfo: Codable {
                let schemes: [String]
            }

            struct WorkspaceInfo: Codable {
                let schemes: [String]
            }
        }

        let output = try JSONDecoder().decode(ListOutput.self, from: data)
        return output.project?.schemes ?? output.workspace?.schemes ?? []
    }

    /// Build a scheme
    public func build(
        scheme: String,
        destination: String,
        configuration: String,
        derivedDataPath: String?,
        projectPath: String?
    ) async throws -> BuildResult {
        var args = [
            "-scheme", scheme,
            "-destination", destination,
            "-configuration", configuration,
            "build"
        ]

        if let projectPath {
            if projectPath.hasSuffix(".xcworkspace") {
                args = ["-workspace", projectPath] + args
            } else {
                args = ["-project", projectPath] + args
            }
        }

        if let derivedDataPath {
            args += ["-derivedDataPath", derivedDataPath]
        }

        let startTime = Date()
        let result = try await shell.run("xcodebuild", arguments: args)
        let buildTime = Date().timeIntervalSince(startTime)

        // Parse output for warnings/errors
        let warnings = result.stdout.components(separatedBy: "warning:").count - 1
        let errors = result.stdout.components(separatedBy: "error:").count - 1

        // Try to find product path
        var productPath: String?
        if let range = result.stdout.range(of: "BUILD_DIR = ") {
            let afterBuildDir = result.stdout[range.upperBound...]
            if let endRange = afterBuildDir.range(of: "\n") {
                let buildDir = String(afterBuildDir[..<endRange.lowerBound])
                // The actual .app is in Debug-iphonesimulator or similar
                productPath = buildDir
            }
        }

        if result.succeeded {
            return BuildResult(
                success: true,
                scheme: scheme,
                configuration: configuration,
                destination: destination,
                buildTime: buildTime,
                warnings: warnings,
                errors: 0,
                productPath: productPath
            )
        } else {
            // Extract error message
            let errorMessage = extractErrorMessage(from: result.stderr + result.stdout)

            return BuildResult(
                success: false,
                scheme: scheme,
                configuration: configuration,
                destination: destination,
                buildTime: buildTime,
                warnings: warnings,
                errors: errors,
                errorMessage: errorMessage
            )
        }
    }

    /// Run tests
    public func test(
        scheme: String,
        destination: String,
        testPlan: String?,
        onlyTesting: String?,
        resultBundlePath: String?,
        projectPath: String?
    ) async throws -> TestResult {
        var args = [
            "-scheme", scheme,
            "-destination", destination,
            "test"
        ]

        if let projectPath {
            if projectPath.hasSuffix(".xcworkspace") {
                args = ["-workspace", projectPath] + args
            } else {
                args = ["-project", projectPath] + args
            }
        }

        if let testPlan {
            args += ["-testPlan", testPlan]
        }

        if let onlyTesting {
            args += ["-only-testing:\(onlyTesting)"]
        }

        if let resultBundlePath {
            args += ["-resultBundlePath", resultBundlePath]
        }

        let startTime = Date()
        let result = try await shell.run("xcodebuild", arguments: args)
        let duration = Date().timeIntervalSince(startTime)

        // Parse test results from output
        let (total, passed, failed, failures) = parseTestResults(from: result.stdout)

        return TestResult(
            success: result.succeeded && failed == 0,
            totalTests: total,
            passedTests: passed,
            failedTests: failed,
            duration: duration,
            failures: failures
        )
    }

    private func extractErrorMessage(from output: String) -> String {
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("error:") {
                return line.trimmingCharacters(in: .whitespaces)
            }
        }
        return "Build failed"
    }

    private func parseTestResults(from output: String) -> (total: Int, passed: Int, failed: Int, failures: [String]) {
        var total = 0
        var passed = 0
        var failed = 0
        var failures: [String] = []

        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("Test Case") && line.contains("passed") {
                passed += 1
                total += 1
            } else if line.contains("Test Case") && line.contains("failed") {
                failed += 1
                total += 1
                // Extract test name
                if let range = line.range(of: "Test Case '") {
                    let afterQuote = line[range.upperBound...]
                    if let endRange = afterQuote.range(of: "'") {
                        failures.append(String(afterQuote[..<endRange.lowerBound]))
                    }
                }
            }
        }

        return (total, passed, failed, failures)
    }
}

enum XcodeBuildError: LocalizedError {
    case commandFailed(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case let .commandFailed(message):
            return "xcodebuild failed: \(message)"
        case .invalidOutput:
            return "Invalid output from xcodebuild"
        }
    }
}
