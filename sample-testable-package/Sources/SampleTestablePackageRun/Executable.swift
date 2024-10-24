import Logging
import SampleTestablePackage
import SampleTestablePackageBenchmark

@main
struct Executable {
    static func main() async throws {
        _ = SampleTestablePackage().text
        Benchmarker().benchmarker()
    }
}
