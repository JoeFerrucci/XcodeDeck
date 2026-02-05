import ArgumentParser

/// Simulator management commands
public struct SimCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "sim",
        abstract: "Simulator management commands",
        subcommands: [
            SimListCommand.self,
            SimBootCommand.self,
            SimShutdownCommand.self,
            SimScreenshotCommand.self,
        ],
        defaultSubcommand: SimListCommand.self
    )

    public init() {}
}
