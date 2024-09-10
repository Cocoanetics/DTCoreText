// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "DTCoreText",
    platforms: [
        .iOS(.v9),         //.v8 - .v13
        .macOS(.v10_10),    //.v10_10 - .v10_15
        .tvOS(.v9),        //.v9 - .v13
    ],
    products: [
        .library(
            name: "DTCoreText",
			// type: .dynamic,
            targets: ["DTCoreText"])
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/DTFoundation.git", from: "1.7.15"),
    ],
    targets: [
        .target(
            name: "DTCoreText",
            dependencies: [
                .product(name: "DTFoundation", package: "DTFoundation"),
            ],
            path: "Core",
			exclude: ["DTCoreText-Info.plist", "DTCoreText-Prefix.pch"],  
             resources: [
            	.copy("Source/default.css")]
        ),
        .testTarget(
            name: "DTCoreTextTests",
            dependencies: ["DTCoreText"],
			path: "Test/Source",
            resources: [
                .copy("Resources/AppleConverted.html"),
                .copy("Resources/CSSCascading.html"),
                .copy("Resources/CSSCascading.plist"),
                .copy("Resources/CSSOOMCrash.html"),
                .copy("Resources/CSSOOMCrash.plist"),
                .copy("Resources/CustomFont.plist"),
                .copy("Resources/Emoji.html"),
                .copy("Resources/Empty_and_Unclosed_Paragraphs.html"),
                .copy("Resources/EmptyLinesAndFontAttribute.html"),
                .copy("Resources/KeepMeTogether.html"),
                .copy("Resources/ListItemBulletColorAndFont.html"),
                .copy("Resources/ListTest.plist"),
                .copy("Resources/MalformedURL.html"),
                .copy("Resources/NavTag.html"),
                .copy("Resources/NavTag.plist"),
                .copy("Resources/PreWhitespace.html"),
                .copy("Resources/PreWhitespace.plist"),
                .copy("Resources/RetinaDataURL.html"),
                .copy("Resources/RTL.html"),
                .copy("Resources/SpaceBetweenUnderlines.html"),
                .copy("Resources/Video.plist"),
                .copy("Resources/WarAndPeace.plist"),
                .copy("Resources/WhitespaceFollowingImagePromotedToParagraph.html"),
                .copy("Resources/Oliver.jpg"),
                .copy("Resources/Oliver@2x.jpg"),
            ]
			)
    ]
)
