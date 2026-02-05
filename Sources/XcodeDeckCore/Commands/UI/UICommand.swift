import ArgumentParser

/// UI automation commands via WebDriverAgent
public struct UICommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "ui",
        abstract: "UI automation commands (requires WebDriverAgent)",
        subcommands: [
            UITapCommand.self,
            UISwipeCommand.self,
            UIScreenshotCommand.self,
        ]
    )

    public init() {}
}
