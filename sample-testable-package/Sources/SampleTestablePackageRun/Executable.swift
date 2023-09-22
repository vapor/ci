import SampleTestablePackageBenchmark
import SampleTestablePackage
import Logging

@main
struct Executable {
    static func main() async throws {
        _ = SampleTestablePackage().text
        Benchmarker().benchmarker()
    }
}
