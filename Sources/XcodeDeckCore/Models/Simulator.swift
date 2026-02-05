import Foundation

/// Represents an iOS Simulator
public struct Simulator: Codable, Sendable {
    public let udid: String
    public let name: String
    public let state: String
    public let runtime: String
    public let deviceTypeIdentifier: String?

    public init(
        udid: String,
        name: String,
        state: String,
        runtime: String,
        deviceTypeIdentifier: String? = nil
    ) {
        self.udid = udid
        self.name = name
        self.state = state
        self.runtime = runtime
        self.deviceTypeIdentifier = deviceTypeIdentifier
    }
}

/// Raw output from `xcrun simctl list --json`
struct SimctlListOutput: Codable {
    let devices: [String: [SimctlDevice]]
}

struct SimctlDevice: Codable {
    let udid: String
    let name: String
    let state: String
    let deviceTypeIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case udid
        case name
        case state
        case deviceTypeIdentifier
    }
}
