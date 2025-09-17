import Testing

@testable import SampleTestablePackage

@Suite
struct SampleTestablePackageTests {
    @Test
    func defaultTest() throws {
        #expect(SampleTestablePackage().text == "Hello, World!")
    }

    @Test
    func normalization() throws {
        var p = SampleTestablePackage()

        p.setNormalized(text: "Hello, World!")
        #expect(p.text == "hello, world!")
    }
}
