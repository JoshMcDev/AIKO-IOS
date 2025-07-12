// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIKO",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "AIKO", targets: ["AIKO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.8.0"),
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/vapor/multipart-kit", from: "4.5.0"),
    ],
    targets: [
        .target(
            name: "AIKO",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "MultipartKit", package: "multipart-kit"),
            ],
            path: "Sources",
            resources: [
                .copy("Resources/DFTemplates"),
                .copy("Resources/Templates"),
                .copy("Models/AIKO.xcdatamodeld"),
                .copy("Models/MetricsModel.xcdatamodeld"),
                .process("Resources/AppIcon.png"),
                .process("Resources/SAMIcon.png")
            ]
        ),
    ]
)