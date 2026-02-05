import Foundation

/// WebDriverAgent session response
struct WDASessionResponse: Codable {
    let sessionId: String
    let value: WDASessionValue?

    struct WDASessionValue: Codable {
        let sessionId: String?
    }
}

/// WebDriverAgent status response
struct WDAStatusResponse: Codable {
    let value: WDAStatusValue

    struct WDAStatusValue: Codable {
        let ready: Bool
        let message: String?
    }
}

/// WebDriverAgent element response
struct WDAElementResponse: Codable {
    let value: WDAElementValue

    struct WDAElementValue: Codable {
        let ELEMENT: String
    }
}

/// WebDriverAgent screenshot response
struct WDAScreenshotResponse: Codable {
    let value: String  // Base64 encoded image
}

/// WebDriverAgent generic response
struct WDAGenericResponse: Codable {
    let value: AnyCodable?
    let status: Int?
}

/// Type-erased Codable for generic responses
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        default:
            try container.encodeNil()
        }
    }
}

/// Locator strategies for finding elements
public enum LocatorStrategy: String, Sendable {
    case accessibilityId = "accessibility id"
    case className = "class name"
    case predicate = "-ios predicate string"
    case classChain = "-ios class chain"
    case xpath = "xpath"
    case name = "name"
    case linkText = "link text"
}

/// Represents a WDA element
public struct WDAElement: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}
