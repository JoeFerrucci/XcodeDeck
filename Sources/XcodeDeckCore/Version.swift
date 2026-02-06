import Foundation

/// Version information for XcodeDeck
public enum Version {
    /// Semantic version (major.minor.patch)
    public static let version = "0.1.0"

    /// Build timestamp (YYYYMMDD.HHMM)
    public static let timestamp = "20260205.1803"

    /// Git info (commits-hash+dirty)
    public static let gitInfo = "2-c7a9f93+dirty"

    /// Full version string for display
    public static var fullVersion: String {
        "\(version) (\(gitInfo) \(timestamp))"
    }
}
