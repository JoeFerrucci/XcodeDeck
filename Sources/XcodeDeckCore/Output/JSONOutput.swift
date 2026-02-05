import Foundation

/// Standard JSON output wrapper for all commands
public struct JSONResponse<T: Encodable>: Encodable {
    public let success: Bool
    public let data: T?
    public let error: ErrorInfo?
    public let timestamp: Date

    public init(success: Bool, data: T? = nil, error: ErrorInfo? = nil) {
        self.success = success
        self.data = data
        self.error = error
        self.timestamp = Date()
    }

    public static func success(_ data: T) -> JSONResponse {
        JSONResponse(success: true, data: data, error: nil)
    }

    public static func failure(_ error: ErrorInfo) -> JSONResponse {
        JSONResponse(success: false, data: nil, error: error)
    }

    public func encode() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"success\": false, \"error\": \"Failed to encode response\"}"
        }
        return string
    }
}

/// Error information for JSON responses
public struct ErrorInfo: Encodable {
    public let code: String
    public let message: String
    public let details: String?

    public init(code: String, message: String, details: String? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

/// Empty data type for responses with no data
public struct EmptyData: Encodable {
    public init() {}
}
