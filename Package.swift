// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrowdinSDK",
    platforms: [
        .macOS(.v10_13),
        .watchOS(.v5),
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(name: "CrowdinSDK", targets: ["CrowdinSDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/nemanja-simic/BaseAPI", .upToNextMajor(from: "master")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "4.0.8"))
    ],
    targets: [
        .target(name: "CrowdinSDK",
                dependencies: ["BaseAPI", "Starscream"],
                path: "Sources/CrowdinSDK",
                swiftSettings: [
                    .define("CrowdinSDKSPM")
                ])
    ]
)
