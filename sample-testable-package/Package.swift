// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "sample-testable-package",
    products: [
        .library(name: "sample-testable-package", targets: ["SampleTestablePackage"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "SampleTestablePackage", dependencies: []),
        .testTarget(name: "SampleTestablePackageTests", dependencies: [.target(name: "SampleTestablePackage")]),
    ]
)
