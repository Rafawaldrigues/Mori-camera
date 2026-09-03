// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoriRecorder",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "MoriRecorder", targets: ["MoriRecorder"])
    ],
    targets: [
        .target(
            name: "MoriRecorder",
            resources: [.process("Resources")]
        )
    ]
)
