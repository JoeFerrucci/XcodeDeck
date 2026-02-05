import XCTest
@testable import XcodeDeckCore

final class JSONOutputTests: XCTestCase {
    func testSuccessResponseEncoding() {
        struct TestData: Encodable {
            let message: String
        }

        let response = JSONResponse.success(TestData(message: "hello"))
        let encoded = response.encode()

        XCTAssertTrue(encoded.contains("\"success\" : true"))
        XCTAssertTrue(encoded.contains("\"message\" : \"hello\""))
        XCTAssertTrue(encoded.contains("\"timestamp\" :"))
    }

    func testFailureResponseEncoding() {
        let errorInfo = ErrorInfo(code: "TEST_ERROR", message: "Something went wrong")
        let response = JSONResponse<EmptyData>.failure(errorInfo)
        let encoded = response.encode()

        XCTAssertTrue(encoded.contains("\"success\" : false"))
        XCTAssertTrue(encoded.contains("\"message\" : \"Something went wrong\""))
        XCTAssertTrue(encoded.contains("\"code\" : \"TEST_ERROR\""))
    }

    func testResponseContainsTimestamp() {
        let response = JSONResponse.success("test")
        let encoded = response.encode()

        // Timestamp should be ISO8601 format (contains year)
        XCTAssertTrue(encoded.contains("\"timestamp\" : \"20"))
    }

    func testErrorInfoWithDetails() {
        let errorInfo = ErrorInfo(
            code: "BUILD_FAILED",
            message: "Build failed",
            details: "Missing provisioning profile"
        )

        XCTAssertEqual(errorInfo.code, "BUILD_FAILED")
        XCTAssertEqual(errorInfo.message, "Build failed")
        XCTAssertEqual(errorInfo.details, "Missing provisioning profile")
    }
}
