import Foundation

/// Result of a build operation
public struct BuildResult: Encodable, Sendable {
    public let success: Bool
    public let scheme: String
    public let configuration: String
    public let destination: String
    public let buildTime: TimeInterval
    public let warnings: Int
    public let errors: Int
    public let productPath: String?
    public let errorMessage: String?

    public init(
        success: Bool,
        scheme: String,
        configuration: String,
        destination: String,
        buildTime: TimeInterval,
        warnings: Int = 0,
        errors: Int = 0,
        productPath: String? = nil,
        errorMessage: String? = nil
    ) {
        self.success = success
        self.scheme = scheme
        self.configuration = configuration
        self.destination = destination
        self.buildTime = buildTime
        self.warnings = warnings
        self.errors = errors
        self.productPath = productPath
        self.errorMessage = errorMessage
    }
}

/// Result of a test operation
public struct TestResult: Encodable, Sendable {
    public let success: Bool
    public let totalTests: Int
    public let passedTests: Int
    public let failedTests: Int
    public let skippedTests: Int
    public let duration: TimeInterval
    public let failures: [String]

    public init(
        success: Bool,
        totalTests: Int,
        passedTests: Int,
        failedTests: Int,
        skippedTests: Int = 0,
        duration: TimeInterval,
        failures: [String] = []
    ) {
        self.success = success
        self.totalTests = totalTests
        self.passedTests = passedTests
        self.failedTests = failedTests
        self.skippedTests = skippedTests
        self.duration = duration
        self.failures = failures
    }
}
