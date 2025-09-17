// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "sample-testable-package",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
    ],
    products: [
        .executable(name: "SampleTestablePackageRun", targets: ["SampleTestablePackageRun"]),
        .library(name: "SampleTestablePackage", targets: ["SampleTestablePackage"]),
        .library(name: "SampleTestablePackageBenchmark", targets: ["SampleTestablePackageBenchmark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0")
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
