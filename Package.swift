// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SVGKit",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "SVGKitSwift",
            targets: ["SVGKitSwift"]
        ),
        .library(
            name: "SVGKitCore",
            targets: ["SVGKitCore"]
        ),
        .library(
            name: "SVGKitDOM",
            targets: ["SVGKitDOM"]
        ),
        .library(
            name: "SVGKitParser",
            targets: ["SVGKitParser"]
        ),
        .library(
            name: "SVGKitRendering",
            targets: ["SVGKitRendering"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SVGKitSwift",
            dependencies: [
                "SVGKitCore",
                "SVGKitDOM",
                "SVGKitParser",
                "SVGKitRendering"
            ],
            resources: [.process("Resources/PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "SVGKitCore",
        ),
        .target(
            name: "SVGKitDOM",
            dependencies: [
                "SVGKitCore"
            ],
        ),
        .target(
            name: "SVGKitParser",
            dependencies: [
                "SVGKitCore",
                "SVGKitDOM"
            ],
        ),
        .target(
            name: "SVGKitRendering",
            dependencies: [
                "SVGKitCore",
                "SVGKitDOM"
            ],
        ),
        .testTarget(
            name: "SVGKitTests",
            dependencies: [
                "SVGKitCore",
                "SVGKitDOM",
                "SVGKitParser",
                "SVGKitRendering",
                "SVGKitSwift"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
