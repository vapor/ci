// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "sample-testable-package",
    products: [
        .library(name: "SampleTestablePackage", targets: ["SampleTestablePackage"]),
        .library(name: "SampleTestablePackageBenchmark", targets: ["SampleTestablePackageBenchmark"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "SampleTestablePackage", dependencies: []),
        .target(name: "SampleTestablePackageBenchmark", dependencies: [.target(name: "SampleTestablePackage")]),
        .testTarget(name: "SampleTestablePackageTests", dependencies: [.target(name: "SampleTestablePackage")]),
    ]
)
