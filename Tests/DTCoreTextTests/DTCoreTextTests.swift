import XCTest
@testable import DTCoreText

final class DTCoreTextTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DTCoreText().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
