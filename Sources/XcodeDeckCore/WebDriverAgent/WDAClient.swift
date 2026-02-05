import Foundation

/// REST client for WebDriverAgent HTTP API
public actor WDAClient {
    private let baseURL: URL
    private let session: URLSession
    private var sessionId: String?

    public init(port: Int = 8100, host: String = "localhost") {
        self.baseURL = URL(string: "http://\(host):\(port)")!
        self.session = URLSession.shared
    }

    // MARK: - Session Management

    /// Create a new session with an app
    public func createSession(bundleId: String) async throws -> String {
        let body: [String: Any] = [
            "capabilities": [
                "alwaysMatch": [
                    "bundleId": bundleId
                ]
            ]
        ]

        let response: WDASessionResponse = try await post("/session", body: body)

        let newSessionId = response.sessionId
        self.sessionId = newSessionId
        return newSessionId
    }

    /// Delete the current session
    public func deleteSession() async throws {
        guard let sessionId else { return }
        try await delete("/session/\(sessionId)")
        self.sessionId = nil
    }

    /// Check if WDA is ready
    public func isReady() async -> Bool {
        do {
            let response: WDAStatusResponse = try await get("/status")
            return response.value.ready
        } catch {
            return false
        }
    }

    // MARK: - Element Operations

    /// Find an element using a locator strategy
    public func findElement(using strategy: LocatorStrategy, value: String) async throws -> WDAElement {
        guard let sessionId else { throw WDAClientError.noSession }

        let body: [String: Any] = [
            "using": strategy.rawValue,
            "value": value
        ]

        let response: WDAElementResponse = try await post("/session/\(sessionId)/element", body: body)
        return WDAElement(id: response.value.ELEMENT)
    }

    /// Tap on an element
    public func tap(element: WDAElement) async throws {
        guard let sessionId else { throw WDAClientError.noSession }
        let _: WDAGenericResponse = try await post("/session/\(sessionId)/element/\(element.id)/click", body: [:])
    }

    /// Tap at specific coordinates
    public func tap(x: Int, y: Int) async throws {
        guard let sessionId else { throw WDAClientError.noSession }

        let body: [String: Any] = [
            "actions": [[
                "type": "pointer",
                "id": "finger1",
                "parameters": ["pointerType": "touch"],
                "actions": [
                    ["type": "pointerMove", "duration": 0, "x": x, "y": y],
                    ["type": "pointerDown"],
                    ["type": "pause", "duration": 100],
                    ["type": "pointerUp"]
                ]
            ]]
        ]

        let _: WDAGenericResponse = try await post("/session/\(sessionId)/actions", body: body)
    }

    // MARK: - Gestures

    /// Perform a swipe gesture
    public func swipe(from: CGPoint, to: CGPoint, duration: TimeInterval = 0.5) async throws {
        guard let sessionId else { throw WDAClientError.noSession }

        let durationMs = Int(duration * 1000)

        let body: [String: Any] = [
            "actions": [[
                "type": "pointer",
                "id": "finger1",
                "parameters": ["pointerType": "touch"],
                "actions": [
                    ["type": "pointerMove", "duration": 0, "x": Int(from.x), "y": Int(from.y)],
                    ["type": "pointerDown"],
                    ["type": "pointerMove", "duration": durationMs, "x": Int(to.x), "y": Int(to.y)],
                    ["type": "pointerUp"]
                ]
            ]]
        ]

        let _: WDAGenericResponse = try await post("/session/\(sessionId)/actions", body: body)
    }

    /// Perform a scroll gesture
    public func scroll(from: CGPoint, deltaX: Int, deltaY: Int, duration: TimeInterval = 0.3) async throws {
        let to = CGPoint(x: from.x + CGFloat(deltaX), y: from.y + CGFloat(deltaY))
        try await swipe(from: from, to: to, duration: duration)
    }

    // MARK: - Screenshots

    /// Take a screenshot
    public func screenshot() async throws -> Data {
        guard let sessionId else { throw WDAClientError.noSession }

        let response: WDAScreenshotResponse = try await get("/session/\(sessionId)/screenshot")

        guard let data = Data(base64Encoded: response.value) else {
            throw WDAClientError.invalidScreenshotData
        }

        return data
    }

    // MARK: - HTTP Helpers

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WDAClientError.requestFailed
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WDAClientError.requestFailed
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func delete(_ path: String) async throws {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WDAClientError.requestFailed
        }
    }
}

/// Errors from WDA client operations
public enum WDAClientError: LocalizedError {
    case noSession
    case requestFailed
    case invalidScreenshotData
    case elementNotFound

    public var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active WebDriverAgent session"
        case .requestFailed:
            return "WebDriverAgent request failed"
        case .invalidScreenshotData:
            return "Invalid screenshot data from WebDriverAgent"
        case .elementNotFound:
            return "Element not found"
        }
    }
}
