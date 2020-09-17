// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DTFoundation",
    platforms: [
        .iOS(.v9),         //.v8 - .v13
        .macOS(.v10_10),    //.v10_10 - .v10_15
        .tvOS(.v9),        //.v9 - .v13
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DTFoundation",
            targets: ["DTFoundation"]),
    ],
    targets: [
        .target(
            name: "DTFoundation",
            dependencies: [],
            path: "Core",
            cSettings: [
                .headerSearchPath("include/DTFoundation"),
                .headerSearchPath("Source/Externals/minizip"),
                .define("TARGET_OS_IPHONE=1", .when(platforms: [.iOS, .tvOS])),
                .define("TARGET_OS_OSX=1", .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "DTFoundationTests",
            dependencies: ["DTFoundation"]),
    ]
)
