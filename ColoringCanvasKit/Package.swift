// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColoringCanvasKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "ColoringCanvasKit",
            targets: ["ColoringCanvasKit"]),
    ],
    targets: [
        .binaryTarget(name: "opencv2", path: "Thirdparties/opencv2.xcframework"),
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
