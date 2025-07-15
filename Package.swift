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
            exclude: [
                "Models/CoreData/FORM_MIGRATION_GUIDE.md",
                "Resources/Regulations",  // Exclude HTML regulation files
                "Resources/Clauses/clauseSelectionEngine.ts",
                "Resources/Clauses/ClauseSelectionEngine.md",
                "Resources/Clauses/ClauseDatabase.json",
                "Resources/Clauses/ClauseSelection_QuickReference.md"
            ],
            resources: [
                .copy("Resources/DFTemplates"),
                .copy("Resources/Templates"),
                .copy("Models/AIKO.xcdatamodeld"),
                .copy("Models/MetricsModel.xcdatamodeld"),
                .copy("Models/AIKO_Updated.xcdatamodeld"),
                .process("Resources/AppIcon.png"),
                .process("Resources/SAMIcon.png"),
                .copy("Resources/Forms/SF1449_Form.md"),
                .copy("Resources/Forms/SF33_Form.md"),
                .copy("Resources/Forms/SF30_Form.md"),
                .copy("Resources/Forms/SF18_Form.md"),
                .copy("Resources/Forms/SF26_Form.md"),
                .copy("Resources/Forms/SF44_Form.md"),
                .copy("Resources/Forms/DD1155_Form.md")
            ]
        ),
        .testTarget(
            name: "AIKOTests",
            dependencies: ["AIKO"],
            path: "Tests",
            exclude: [
                "README.md",
                "Templates/Template_03_TestNamingConvention.md",
                "Test_Documentation/TestDoc_01_AppTestFramework.md",
                "Test_Documentation/TestDoc_02_ComprehensiveTestReport.md",
                "Test_Documentation/TestDoc_03_MCPTestFramework.md",
                "Test_Documentation/TestDoc_04_TestResultsTemplate.md",
                "Test_Documentation/TestDoc_05_TestScenarios.md",
                "OCRValidation"  // Exclude OCR validation markdown files
            ]
        ),
    ]
)
