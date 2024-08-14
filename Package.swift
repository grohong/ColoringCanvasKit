// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "4.10.0+4"
let checksum = "bbf7ef886a1488f08a59813819145c4929c8f0d41f62adbdc8bcbf489c398da4"

let package = Package(
    name: "ColoringCanvasKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "ColoringCanvasKit",
            targets: ["ColoringCanvasKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "opencv2",
            url: "https://github.com/yeatse/opencv-spm/releases/download/\(version)/opencv2.xcframework.zip",
            checksum: checksum
        ),
        .target(
            name: "ColoringModule",
            dependencies: ["opencv2"],
            publicHeadersPath: "./",
            cSettings: [.headerSearchPath("Coloring"),]
        ),
        .target(
            name: "ColoringCanvasKit",
            dependencies: ["ColoringModule"],
            path: "Sources/ColoringCanvasKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ColoringCanvasKitTests",
            dependencies: ["ColoringCanvasKit"]
        ),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx20
)
