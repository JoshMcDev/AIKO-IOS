// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIKO",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "AIKO", targets: ["AIKO"]),
        .library(name: "AppCore", targets: ["AppCore"]),
        .library(name: "AIKOiOS", targets: ["AIKOiOS"]),
        .library(name: "AIKOmacOS", targets: ["AIKOmacOS"]),
    ],
    dependencies: [
        // TCA dependency removed ✅
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
        .package(url: "https://github.com/vapor/multipart-kit", from: "4.5.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0"),
    ],
    targets: [
        // MARK: - Compatibility Module for Non-Sendable Dependencies

        .target(
            name: "AikoCompat",
            dependencies: [
                .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
            ],
            path: "Sources/AikoCompat",
            exclude: ["README.md"],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),

        // MARK: - Shared Core Module (Platform-Agnostic)

        .target(
            name: "AppCore",
            dependencies: [
                "AikoCompat",
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "MLX", package: "mlx-swift"),
            ],
            path: "Sources/AppCore",
            exclude: ["README.md"],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),

        // MARK: - iOS Platform Module

        .target(
            name: "AIKOiOS",
            dependencies: [
                "AppCore",
            ],
            path: "Sources/AIKOiOS",
            exclude: ["README.md", "Service-Concurrency-Guide.md", "Services/DocumentImageProcessor.swift.backup"],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),

        // MARK: - macOS Platform Module

        .target(
            name: "AIKOmacOS",
            dependencies: [
                "AppCore",
            ],
            path: "Sources/AIKOmacOS",
            exclude: ["README.md"],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),

        // MARK: - GraphRAG Module

        .target(
            name: "GraphRAG",
            dependencies: [
                "AppCore",
            ],
            path: "Sources/GraphRAG",
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),

        // MARK: - Main App Target

        .target(
            name: "AIKO",
            dependencies: [
                "AppCore",
                "GraphRAG",
                .target(name: "AIKOiOS", condition: .when(platforms: [.iOS])),
                .target(name: "AIKOmacOS", condition: .when(platforms: [.macOS])),
                .product(name: "MultipartKit", package: "multipart-kit"),
            ],
            path: "Sources",
            exclude: [
                "AppCore",
                "AIKOiOS",
                "AIKOmacOS",
                "AikoCompat",
                "GraphRAG",
                "Models/CoreData/FORM_MIGRATION_GUIDE.md",
                "Resources/Clauses/clauseSelectionEngine.ts",
                "Resources/Clauses/ClauseSelectionEngine.md",
                "Resources/Clauses/ClauseDatabase.json",
                "Resources/Clauses/ClauseSelection_QuickReference.md",
                "AIKOiOS/Service-Concurrency-Guide.md",
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
                .copy("Resources/Forms/DD1155_Form.md"),
                .copy("Resources/Source Selection Procedures.pdf"),
                // LFM2 Model Resources (conditionally included based on build configuration)
                // Note: These large model files are excluded by default to prevent Xcode indexing issues
                // Uncomment for production builds that need the actual model files:
                // .copy("Resources/Models/LFM2-700M-Unsloth-XL-GraphRAG.mlmodel"),
                // .copy("Resources/Models/LFM2-700M-Q6K.gguf"),
                // .copy("Resources/Models/LFM2-700M.mlmodel"),
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),

        // MARK: - Test Targets

        .testTarget(
            name: "AppCoreTests",
            dependencies: [
                "AppCore",
                "AIKO",
            ],
            path: "Tests/AppCoreTests"
        ),
        .testTarget(
            name: "AIKOiOSTests",
            dependencies: [
                .target(name: "AIKOiOS", condition: .when(platforms: [.iOS])),
                "AppCore",
            ],
            path: "Tests/AIKOiOSTests"
        ),
        .testTarget(
            name: "AIKOmacOSTests",
            dependencies: [
                .target(name: "AIKOmacOS", condition: .when(platforms: [.macOS])),
                "AppCore",
            ],
            path: "Tests/AIKOmacOSTests"
        ),
        .testTarget(
            name: "GraphRAGTests",
            dependencies: [
                "GraphRAG",
                "AppCore",
            ],
            path: "Tests/GraphRAGTests"
        ),
        .testTarget(
            name: "AIKOTests",
            dependencies: [
                "AppCore",
                "AIKO",
            ],
            path: "Tests",
            exclude: [
                "README.md",
                "Test_Documentation",
                "OCRValidation",
                "AppCoreTests",
                "AIKOiOSTests",
                "AIKOmacOSTests",
                "GraphRAGTests",
                "Templates",
                "Shared",
                "RED_Phase_Verification.swift.disabled",
                "UI/UI_DocumentScannerViewTests.swift.disabled",
                "Services/AgenticOrchestratorTests.swift.disabled",
                "test_red_phase.swift",
                "verify_compliance_guardian.swift",
            ]
        ),
    ]
)
