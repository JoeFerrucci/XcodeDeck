import XCTest
@testable import XcodeDeckCore

final class SimulatorTests: XCTestCase {
    func testSimulatorInitialization() {
        let simulator = Simulator(
            udid: "ABC123-DEF456",
            name: "iPhone 17 Pro",
            state: "Booted",
            runtime: "iOS 26.0"
        )

        XCTAssertEqual(simulator.udid, "ABC123-DEF456")
        XCTAssertEqual(simulator.name, "iPhone 17 Pro")
        XCTAssertEqual(simulator.state, "Booted")
        XCTAssertEqual(simulator.runtime, "iOS 26.0")
    }

    func testSimulatorEncoding() throws {
        let simulator = Simulator(
            udid: "ABC123",
            name: "iPhone 17 Pro",
            state: "Shutdown",
            runtime: "iOS 26.0",
            deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(simulator)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("ABC123"))
        XCTAssertTrue(json.contains("iPhone 17 Pro"))
    }

    func testSimulatorDecoding() throws {
        let json = """
        {
            "udid": "ABC123-DEF456",
            "name": "iPhone 17 Pro",
            "state": "Booted",
            "runtime": "iOS 26.0",
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
        }
        """

        let data = json.data(using: .utf8)!
        let simulator = try JSONDecoder().decode(Simulator.self, from: data)

        XCTAssertEqual(simulator.udid, "ABC123-DEF456")
        XCTAssertEqual(simulator.name, "iPhone 17 Pro")
        XCTAssertEqual(simulator.state, "Booted")
        XCTAssertEqual(simulator.runtime, "iOS 26.0")
    }
}
