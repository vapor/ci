// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "sample-testable-package",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .executable(name: "SampleTestablePackageRun", targets: ["SampleTestablePackageRun"]),
        .library(name: "SampleTestablePackage", targets: ["SampleTestablePackage"]),
        .library(name: "SampleTestablePackageBenchmark", targets: ["SampleTestablePackageBenchmark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "SampleTestablePackageRun",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .target(name: "SampleTestablePackageBenchmark"),
            ],
            path: "sample-testable-package/Sources/SampleTestablePackageRun"
        ),
        .target(
            name: "SampleTestablePackage",
            dependencies: [],
            path: "sample-testable-package/Sources/SampleTestablePackage"
        ),
        .target(
            name: "SampleTestablePackageBenchmark",
            dependencies: [.target(name: "SampleTestablePackage")],
            path: "sample-testable-package/Sources/SampleTestablePackageBenchmark"
        ),
        .testTarget(
            name: "SampleTestablePackageTests",
            dependencies: [.target(name: "SampleTestablePackage")],
            path: "sample-testable-package/Tests/SampleTestablePackageTests"
        ),
    ]
)
