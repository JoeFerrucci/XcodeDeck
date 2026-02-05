import ArgumentParser
import Foundation

/// Output format options (JSON for CI/CD, pretty for humans)
public enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case json
    case pretty

    public init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
}

/// Protocol for types that can be rendered in different formats
public protocol OutputRenderable {
    func render(format: OutputFormat) -> String
}

/// Global options shared across all commands
public struct GlobalOptions: ParsableArguments {
    @Flag(name: .shortAndLong, help: "Output in JSON format")
    public var json: Bool = false

    @Flag(name: .shortAndLong, help: "Verbose output")
    public var verbose: Bool = false

    public var format: OutputFormat { json ? .json : .pretty }

    public init() {}
}
