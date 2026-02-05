import XCTest
@testable import XcodeDeckCore

final class ShellResultTests: XCTestCase {
    func testSucceededWithZeroExitCode() {
        let result = ShellResult(exitCode: 0, stdout: "output", stderr: "")
        XCTAssertTrue(result.succeeded)
    }

    func testSucceededWithNonZeroExitCode() {
        let result = ShellResult(exitCode: 1, stdout: "", stderr: "error")
        XCTAssertFalse(result.succeeded)
    }

    func testStdoutCapture() {
        let result = ShellResult(exitCode: 0, stdout: "hello world", stderr: "")
        XCTAssertEqual(result.stdout, "hello world")
    }

    func testStderrCapture() {
        let result = ShellResult(exitCode: 1, stdout: "", stderr: "error message")
        XCTAssertEqual(result.stderr, "error message")
    }
}
