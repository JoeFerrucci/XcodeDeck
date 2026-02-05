import ArgumentParser

/// Root command for XcodeDeck CLI
public struct XcodeDeck: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "xcodedeck",
        abstract: "iOS/macOS development CLI tool - a local FlowDeck alternative",
        version: "1.0.0",
        subcommands: [
            BuildCommand.self,
            TestCommand.self,
            RunCommand.self,
            SimCommand.self,
            LogCommand.self,
            UICommand.self,
            ContextCommand.self,
        ],
        defaultSubcommand: ContextCommand.self
    )

    public init() {}
}
