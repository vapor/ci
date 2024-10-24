public struct SampleTestablePackage {
    public private(set) var text = "Hello, World!"

    public init() {}

    public mutating func setNormalized(text: String) {
        self.text = text.lowercased()
    }

    public func methodWithNoTest() {
        print("I have no unit test.")
    }
}
