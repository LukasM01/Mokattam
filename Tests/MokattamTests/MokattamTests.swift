import XCTest
@testable import Mokattam

final class MokattamTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Mokattam().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
