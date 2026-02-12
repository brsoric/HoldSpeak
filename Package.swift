// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TranscribeHoldPaste",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "TranscribeHoldPasteKit", targets: ["TranscribeHoldPasteKit"]),
        .executable(name: "TranscribeHoldPasteCLI", targets: ["TranscribeHoldPasteCLI"]),
        .executable(name: "TranscribeHoldPasteApp", targets: ["TranscribeHoldPasteApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "TranscribeHoldPasteKit",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ]
        ),
        .executableTarget(
            name: "TranscribeHoldPasteCLI",
            dependencies: ["TranscribeHoldPasteKit"]
        ),
        .executableTarget(
            name: "TranscribeHoldPasteApp",
            dependencies: ["TranscribeHoldPasteKit"]
        ),
    ]
)
