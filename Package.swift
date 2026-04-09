// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "DTCoreText",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
    ],
    products: [
        .library(
            name: "DTCoreText",
			// type: .dynamic,
            targets: ["DTCoreTextSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/DTFoundation.git", from: "1.7.15"),
        .package(url: "https://github.com/Cocoanetics/SwiftText.git", branch: "main", traits: ["HTML"]),
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
		.target(
			name: "DTCoreTextSwift",
			dependencies: [
				"DTCoreText",
				.product(name: "SwiftTextHTML", package: "SwiftText"),
			],
			path: "Sources/DTCoreTextSwift"
		),
        .target(
            name: "DTCoreTextTestHelpers",
            dependencies: ["DTCoreText"],
            path: "Tests/DTCoreTextTestHelpers",
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "DTCoreTextSwiftTests",
            dependencies: ["DTCoreTextSwift", "DTCoreTextTestHelpers"],
            path: "Tests/DTCoreTextSwiftTests",
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
        ),
    ]
)
