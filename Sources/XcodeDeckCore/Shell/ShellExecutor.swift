import Foundation

/// Protocol for executing shell commands (enables testing via mocks)
public protocol ShellExecuting: Sendable {
    func run(_ command: String, arguments: [String]) async throws -> ShellResult
    func stream(_ command: String, arguments: [String]) -> AsyncThrowingStream<String, Error>
}

/// Concrete implementation using Foundation.Process
public final class ShellExecutor: ShellExecuting, Sendable {
    public init() {}

    public func run(_ command: String, arguments: [String]) async throws -> ShellResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(returning: ShellResult(
                    exitCode: proc.terminationStatus,
                    stdout: stdout,
                    stderr: stderr
                ))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func stream(_ command: String, arguments: [String]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments

            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    continuation.finish()
                    return
                }
                if let line = String(data: data, encoding: .utf8) {
                    continuation.yield(line)
                }
            }

            process.terminationHandler = { _ in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    /// Run xcrun with a specific tool
    public func xcrun(_ tool: String, arguments: [String]) async throws -> ShellResult {
        try await run("xcrun", arguments: [tool] + arguments)
    }
}

/// Errors that can occur during shell execution
public enum ShellError: LocalizedError {
    case commandFailed(exitCode: Int32, stderr: String)
    case processLaunchFailed(Error)

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(exitCode, stderr):
            return "Command failed with exit code \(exitCode): \(stderr)"
        case let .processLaunchFailed(error):
            return "Failed to launch process: \(error.localizedDescription)"
        }
    }
}
