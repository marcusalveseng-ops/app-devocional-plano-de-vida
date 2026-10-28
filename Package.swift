// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevotionalCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "DevotionalCore", targets: ["DevotionalCore"])],
    targets: [
        .target(name: "DevotionalCore"),
        .testTarget(name: "DevotionalCoreTests", dependencies: ["DevotionalCore"])
    ]
)
