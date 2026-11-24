// swift-tools-version: 6.0
import PackageDescription

let languageMode: [SwiftSetting] = [.swiftLanguageMode(.v5)]

let package = Package(
    name: "PortWatch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "PortWatch", targets: ["PortWatch"]),
        .library(name: "PortWatchCore", targets: ["PortWatchCore"]),
    ],
    targets: [
        .target(
            name: "PortWatchCore",
            swiftSettings: languageMode
        ),
        .executableTarget(
            name: "PortWatch",
            dependencies: ["PortWatchCore"],
            resources: [
                .copy("Resources"),
            ],
            swiftSettings: languageMode
        ),
        .testTarget(
            name: "PortWatchCoreTests",
            dependencies: ["PortWatchCore"],
            resources: [
                .copy("Fixtures"),
            ],
            swiftSettings: languageMode
        ),
    ]
)