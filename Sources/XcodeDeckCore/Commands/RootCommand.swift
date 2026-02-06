import ArgumentParser

/// Root command for XcodeDeck CLI
public struct XcodeDeck: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "xcodedeck",
        abstract: "iOS/macOS development CLI tool - a local FlowDeck alternative",
        version: Version.fullVersion,
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
