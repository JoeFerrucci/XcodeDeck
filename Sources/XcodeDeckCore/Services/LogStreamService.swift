import Foundation

/// Service for streaming logs from simulators
public final class LogStreamService: Sendable {
    public init() {}

    /// Stream logs from a simulator
    public func stream(
        simulatorUDID: String,
        level: String,
        predicate: String?,
        jsonFormat: Bool
    ) -> AsyncThrowingStream<String, Error> {
        var args = [
            "simctl", "spawn", simulatorUDID,
            "log", "stream",
            "--level", level
        ]

        if jsonFormat {
            args += ["--style", "json"]
        } else {
            args += ["--style", "compact"]
        }

        if let predicate {
            args += ["--predicate", predicate]
        }

        let shell = ShellExecutor()
        return shell.stream("xcrun", arguments: args)
    }
}
