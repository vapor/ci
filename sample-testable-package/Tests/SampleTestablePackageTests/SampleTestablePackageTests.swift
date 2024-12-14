import XCTest

@testable import SampleTestablePackage

final class SampleTestablePackageTests: XCTestCase {
    func testDefaultTest() throws {
        XCTAssertEqual(SampleTestablePackage().text, "Hello, World!")
    }

    func testNormalization() throws {
        var p = SampleTestablePackage()

        p.setNormalized(text: "Hello, World!")
        XCTAssertEqual(p.text, "hello, world!")
    }
}
