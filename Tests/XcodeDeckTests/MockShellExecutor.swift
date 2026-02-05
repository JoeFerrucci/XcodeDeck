import Foundation
@testable import XcodeDeckCore

/// Mock shell executor for testing
final class MockShellExecutor: ShellExecuting, @unchecked Sendable {
    var responses: [String: ShellResult] = [:]
    var executedCommands: [(command: String, arguments: [String])] = []

    func setResponse(for command: String, result: ShellResult) {
        responses[command] = result
    }

    func run(_ command: String, arguments: [String]) async throws -> ShellResult {
        executedCommands.append((command, arguments))

        // Check for specific command matches
        let fullCommand = ([command] + arguments).joined(separator: " ")
        if let response = responses[fullCommand] {
            return response
        }

        // Check for command-only matches
        if let response = responses[command] {
            return response
        }

        // Default success response
        return ShellResult(exitCode: 0, stdout: "", stderr: "")
    }

    func stream(_ command: String, arguments: [String]) -> AsyncThrowingStream<String, Error> {
        executedCommands.append((command, arguments))
        return AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}
