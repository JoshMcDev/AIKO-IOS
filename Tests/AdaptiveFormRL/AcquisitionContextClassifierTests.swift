@testable import AIKO
@testable import AppCore
import XCTest

/// Comprehensive tests for AcquisitionContextClassifier
/// RED Phase: Tests written before implementation exists
/// Coverage: Rule-based classification accuracy, feature extraction, confidence scoring
final class AcquisitionContextClassifierTests: XCTestCase {
    // MARK: - Test Infrastructure

    var sut: AcquisitionContextClassifier?

    override func setUp() {
        super.setUp()
        sut = AcquisitionContextClassifier()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Rule-Based Classification Accuracy Tests

    /// Test IT keyword detection with >80% accuracy target
    func testITKeywordDetectionAccuracy() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: IT-focused acquisition data
        let itAcquisitions = createITAcquisitionTestData()

        var correctClassifications = 0
        let totalAcquisitions = itAcquisitions.count

        // When: Classify each acquisition
        for acquisition in itAcquisitions {
            let context = try await sut.classifyAcquisition(acquisition)

            if context.category == .informationTechnology, context.confidence >= 0.8 {
                correctClassifications += 1
            }
        }

        // Then: Accuracy should be >80%
        let accuracy = Double(correctClassifications) / Double(totalAcquisitions)

        XCTAssertGreaterThan(accuracy, 0.8,
                             "IT classification accuracy should be >80%, got \(accuracy * 100)%")
    }

    /// Test Construction keyword detection with >80% accuracy target
    func testConstructionKeywordDetectionAccuracy() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Construction-focused acquisition data
        let constructionAcquisitions = createConstructionAcquisitionTestData()

        var correctClassifications = 0
        let totalAcquisitions = constructionAcquisitions.count

        // When: Classify each acquisition
        for acquisition in constructionAcquisitions {
            let context = try await sut.classifyAcquisition(acquisition)

            if context.category == .construction, context.confidence >= 0.8 {
                correctClassifications += 1
            }
        }

        // Then: Accuracy should be >80%
        let accuracy = Double(correctClassifications) / Double(totalAcquisitions)

        XCTAssertGreaterThan(accuracy, 0.8,
                             "Construction classification accuracy should be >80%, got \(accuracy * 100)%")
    }

    /// Test Professional Services classification accuracy
    func testProfessionalServicesClassificationAccuracy() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Professional services acquisition data
        let servicesAcquisitions = createProfessionalServicesTestData()

        var correctClassifications = 0
        let totalAcquisitions = servicesAcquisitions.count

        // When: Classify each acquisition
        for acquisition in servicesAcquisitions {
            let context = try await sut.classifyAcquisition(acquisition)

            if context.category == .professionalServices, context.confidence >= 0.6 {
                correctClassifications += 1
            }
        }

        // Then: Accuracy should be reasonable for services category
        let accuracy = Double(correctClassifications) / Double(totalAcquisitions)

        XCTAssertGreaterThan(accuracy, 0.7,
                             "Professional Services classification accuracy should be >70%, got \(accuracy * 100)%")
    }

    /// Test confidence scoring algorithm correctness
    func testConfidenceScoringAlgorithm() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: High-confidence IT acquisition
        let highConfidenceIT = AcquisitionAggregate(
            id: UUID(),
            title: "Software Development Services for Cloud-based Cybersecurity Platform",
            requirements: "We need comprehensive software development services for a cloud-based cybersecurity platform including database design, network security implementation, and IT infrastructure management.",
            projectDescription: "This project involves building a complete IT solution with advanced cybersecurity features, cloud computing infrastructure, and comprehensive software licensing.",
            estimatedValue: 500_000,
            deadline: Date().addingTimeInterval(90 * 24 * 3600),
            isRecurring: false
        )

        // When: Classify acquisition
        let context = try await sut.classifyAcquisition(highConfidenceIT)

        // Then: Should have high confidence for clear IT context
        XCTAssertEqual(context.category, .informationTechnology,
                       "Should classify as IT with high keyword density")
        XCTAssertGreaterThan(context.confidence, 0.8,
                             "Should have high confidence >0.8 for clear IT keywords")
    }

    /// Test mixed-context scenarios and confidence degradation
    func testMixedContextConfidenceHandling() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Mixed IT/Construction acquisition
        let mixedAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "Smart Building IT Infrastructure and Construction Management",
            requirements: "Need both software systems for building management and construction services for facility renovation.",
            projectDescription: "Project includes both IT components (network hardware, software development) and construction elements (building renovation, architectural services).",
            estimatedValue: 750_000,
            deadline: Date().addingTimeInterval(120 * 24 * 3600),
            isRecurring: false
        )

        // When: Classify mixed acquisition
        let context = try await sut.classifyAcquisition(mixedAcquisition)

        // Then: Confidence should be lower for mixed contexts
        XCTAssertLessThan(context.confidence, 0.7,
                          "Mixed context should have lower confidence <0.7")

        // Should still make a primary categorization
        XCTAssertTrue([.informationTechnology, .construction].contains(context.category),
                      "Should categorize to strongest matching context")
    }

    // MARK: - Feature Extraction Validation Tests

    /// Test contextual feature derivation accuracy
    func testContextualFeatureExtraction() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: High-value, urgent, specialized acquisition
        let complexAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "Critical Cybersecurity Infrastructure Upgrade",
            requirements: "Urgent need for specialized cybersecurity expertise and security clearance required. High-value project with strict compliance requirements.",
            projectDescription: "Mission-critical cybersecurity upgrade requiring top-secret clearance and specialized skills in advanced persistent threat detection.",
            estimatedValue: 2_000_000,
            deadline: Date().addingTimeInterval(14 * 24 * 3600), // 14 days - urgent
            isRecurring: false
        )

        // When: Extract features
        let context = try await sut.classifyAcquisition(complexAcquisition)

        // Then: Features should be correctly extracted
        XCTAssertEqual(context.acquisitionValue, 2_000_000,
                       "Should extract correct acquisition value")
        XCTAssertEqual(context.urgency, .urgent,
                       "Should detect urgent deadline (14 days)")
        XCTAssertEqual(context.complexity, .high,
                       "Should detect high complexity based on value and requirements")
        XCTAssertTrue(context.features.requiresSpecializedSkills,
                      "Should detect specialized skill requirements")
        XCTAssertTrue(context.features.involvesSecurity,
                      "Should detect security-related requirements")
    }

    /// Test urgency level determination logic
    func testUrgencyLevelDetermination() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Test urgent deadline (< 7 days)
        let urgentAcquisition = createTestAcquisition(
            title: "Emergency IT Support",
            deadline: Date().addingTimeInterval(5 * 24 * 3600) // 5 days
        )

        let urgentContext = try await sut.classifyAcquisition(urgentAcquisition)
        XCTAssertEqual(urgentContext.urgency, .urgent, "Should detect urgent deadline")

        // Test moderate deadline (7-30 days)
        let moderateAcquisition = createTestAcquisition(
            title: "Standard IT Services",
            deadline: Date().addingTimeInterval(20 * 24 * 3600) // 20 days
        )

        let moderateContext = try await sut.classifyAcquisition(moderateAcquisition)
        XCTAssertEqual(moderateContext.urgency, .moderate, "Should detect moderate deadline")

        // Test normal deadline (> 30 days)
        let normalAcquisition = createTestAcquisition(
            title: "Long-term IT Project",
            deadline: Date().addingTimeInterval(60 * 24 * 3600) // 60 days
        )

        let normalContext = try await sut.classifyAcquisition(normalAcquisition)
        XCTAssertEqual(normalContext.urgency, .normal, "Should detect normal deadline")
    }

    /// Test complexity scoring algorithm
    func testComplexityScoringAlgorithm() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Test high complexity (high value + detailed requirements + tight timeline)
        let highComplexityAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "Enterprise-wide IT Transformation",
            requirements: String(repeating: "Detailed requirements for complex system architecture, integration patterns, security frameworks, compliance protocols, and performance optimization across multiple domains. ", count: 10), // >1000 chars
            projectDescription: "Comprehensive enterprise transformation",
            estimatedValue: 5_000_000, // High value
            deadline: Date().addingTimeInterval(20 * 24 * 3600), // Tight timeline
            isRecurring: false
        )

        let highContext = try await sut.classifyAcquisition(highComplexityAcquisition)
        XCTAssertEqual(highContext.complexity, .high, "Should detect high complexity")

        // Test low complexity (low value + simple requirements)
        let lowComplexityAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "Simple IT Support",
            requirements: "Basic IT support needed", // <100 chars
            projectDescription: "Simple support request",
            estimatedValue: 5000, // Low value
            deadline: Date().addingTimeInterval(90 * 24 * 3600), // Plenty of time
            isRecurring: false
        )

        let lowContext = try await sut.classifyAcquisition(lowComplexityAcquisition)
        XCTAssertEqual(lowContext.complexity, .low, "Should detect low complexity")
    }

    /// Test temporal context extraction
    func testTemporalContextExtraction() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Acquisition classified at specific time
        let acquisition = createTestAcquisition(title: "IT Services")

        // When: Classify acquisition
        let context = try await sut.classifyAcquisition(acquisition)

        // Then: Should include temporal context
        let now = Date()
        let calendar = Calendar.current
        let expectedHour = calendar.component(.hour, from: now)
        let expectedDayOfWeek = calendar.component(.weekday, from: now)
        let expectedIsWeekend = calendar.isDateInWeekend(now)

        // Note: In actual implementation, temporal context would be part of the classification result
        // This test verifies the contract for temporal context inclusion
        XCTAssertNotNil(context, "Context should include temporal information")

        // Additional temporal validation would be added once TemporalContext is part of AcquisitionContext
    }

    // MARK: - Edge Cases and Boundary Testing

    /// Test empty or minimal content handling
    func testMinimalContentHandling() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Acquisition with minimal content
        let minimalAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "",
            requirements: nil,
            projectDescription: nil,
            estimatedValue: nil,
            deadline: nil,
            isRecurring: nil
        )

        // When: Classify minimal acquisition
        let context = try await sut.classifyAcquisition(minimalAcquisition)

        // Then: Should fallback to general category with neutral confidence
        XCTAssertEqual(context.category, .general,
                       "Should fallback to general category for minimal content")
        XCTAssertEqual(context.confidence, 0.5, accuracy: 0.1,
                       "Should have neutral confidence for minimal content")
    }

    /// Test very long content handling
    func testLongContentHandling() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Acquisition with very long content
        let longContent = String(repeating: "software development cloud computing network security cybersecurity database management IT infrastructure digital transformation ", count: 100) // ~10,000 characters

        let longAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "Enterprise IT Transformation Project",
            requirements: longContent,
            projectDescription: longContent,
            estimatedValue: 1_000_000,
            deadline: Date().addingTimeInterval(90 * 24 * 3600),
            isRecurring: false
        )

        // When: Classify long acquisition
        let context = try await sut.classifyAcquisition(longAcquisition)

        // Then: Should handle long content without performance issues
        XCTAssertEqual(context.category, .informationTechnology,
                       "Should correctly classify despite long content")
        XCTAssertGreaterThan(context.confidence, 0.8,
                             "Should maintain high confidence with clear keywords")
    }

    /// Test special characters and formatting
    func testSpecialCharacterHandling() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Acquisition with special characters and formatting
        let specialCharAcquisition = AcquisitionAggregate(
            id: UUID(),
            title: "IT Services - Software Development & Cloud Computing (Priority: High)",
            requirements: """
            • Software development services
            • Cloud computing infrastructure
            • Network security & cybersecurity
            • Database management systems

            Requirements include:
            - 24/7 support
            - 99.9% uptime SLA
            - SOC 2 compliance
            """,
            projectDescription: "Comprehensive IT solution with special chars: @#$%^&*(){}[]|\\:;\"'<>,.?/~`",
            estimatedValue: 250_000,
            deadline: Date().addingTimeInterval(45 * 24 * 3600),
            isRecurring: false
        )

        // When: Classify acquisition with special characters
        let context = try await sut.classifyAcquisition(specialCharAcquisition)

        // Then: Should handle special characters gracefully
        XCTAssertEqual(context.category, .informationTechnology,
                       "Should classify correctly despite special characters")
        XCTAssertGreaterThan(context.confidence, 0.7,
                             "Should maintain confidence with formatted content")
    }

    // MARK: - Performance and Scalability Tests

    /// Test classification performance with large datasets
    func testClassificationPerformance() async throws {
        guard let sut else {
            XCTFail("AcquisitionContextClassifier should be initialized")
            return
        }
        // Given: Large set of acquisitions
        let acquisitions = createLargeAcquisitionDataset(count: 1000)

        // When: Classify all acquisitions and measure time
        let startTime = CFAbsoluteTimeGetCurrent()

        var results: [AcquisitionContext] = []
        for acquisition in acquisitions {
            let context = try await sut.classifyAcquisition(acquisition)
            results.append(context)
        }

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTimePerClassification = totalTime / Double(acquisitions.count)

        // Then: Should meet performance requirements
        XCTAssertLessThan(averageTimePerClassification, 0.030, // 30ms per classification
                          "Average classification time should be <30ms, got \(averageTimePerClassification * 1000)ms")

        XCTAssertEqual(results.count, acquisitions.count,
                       "Should successfully classify all acquisitions")
    }

    // MARK: - Test Helper Methods

    private func createTestAcquisition(
        title: String,
        requirements: String? = "Standard requirements",
        description: String? = "Standard description",
        value: Double? = 100_000,
        deadline: Date? = nil
    ) -> AppCore.AcquisitionAggregate {
        AppCore.AcquisitionAggregate(
            id: UUID(),
            title: title,
            requirements: requirements,
            projectDescription: description,
            estimatedValue: value,
            deadline: deadline ?? Date().addingTimeInterval(30 * 24 * 3600),
            isRecurring: false
        )
    }

    private func createITAcquisitionTestData() -> [AppCore.AcquisitionAggregate] {
        [
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Software Development Services",
                requirements: "Need custom software development with cloud computing and database design",
                projectDescription: "Complete IT solution including software programming, network setup, and cybersecurity",
                estimatedValue: 200_000,
                deadline: Date().addingTimeInterval(60 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Cybersecurity Infrastructure Upgrade",
                requirements: "Comprehensive cybersecurity services including network security and IT support",
                projectDescription: "Hardware and software cybersecurity implementation with database management",
                estimatedValue: 300_000,
                deadline: Date().addingTimeInterval(45 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Cloud Computing Migration",
                requirements: "Cloud migration services with software development and IT infrastructure support",
                projectDescription: "Complete cloud computing solution with network design and database migration",
                estimatedValue: 150_000,
                deadline: Date().addingTimeInterval(90 * 24 * 3600),
                isRecurring: false
            ),
            // Add more IT-focused test cases...
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Enterprise Network Hardware Procurement",
                requirements: "Network equipment and hardware for IT infrastructure with programming support",
                projectDescription: "Complete IT hardware solution including computers, network devices, and software licenses",
                estimatedValue: 400_000,
                deadline: Date().addingTimeInterval(30 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Database Management System Implementation",
                requirements: "Database design and development with cybersecurity and cloud computing integration",
                projectDescription: "Comprehensive database solution with IT support and software development services",
                estimatedValue: 250_000,
                deadline: Date().addingTimeInterval(75 * 24 * 3600),
                isRecurring: false
            ),
        ]
    }

    private func createConstructionAcquisitionTestData() -> [AppCore.AcquisitionAggregate] {
        [
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Office Building Renovation",
                requirements: "Complete building renovation including architectural design and construction management",
                projectDescription: "Facility renovation with construction services, building materials, and contractor oversight",
                estimatedValue: 500_000,
                deadline: Date().addingTimeInterval(120 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Infrastructure Construction Project",
                requirements: "New facility construction with engineering services and building system installation",
                projectDescription: "Complete infrastructure project including construction, architectural planning, and facility management",
                estimatedValue: 1_200_000,
                deadline: Date().addingTimeInterval(180 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Concrete and Steel Building Materials",
                requirements: "Construction materials procurement including concrete, steel, and building supplies",
                projectDescription: "Building materials for infrastructure project with contractor delivery services",
                estimatedValue: 300_000,
                deadline: Date().addingTimeInterval(45 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Architectural Engineering Services",
                requirements: "Professional architectural and engineering services for facility construction",
                projectDescription: "Complete engineering and architectural design for building construction project",
                estimatedValue: 400_000,
                deadline: Date().addingTimeInterval(90 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Construction Contractor Services",
                requirements: "General contractor services for building renovation and facility construction",
                projectDescription: "Comprehensive construction services including renovation, building, and infrastructure work",
                estimatedValue: 800_000,
                deadline: Date().addingTimeInterval(150 * 24 * 3600),
                isRecurring: false
            ),
        ]
    }

    private func createProfessionalServicesTestData() -> [AppCore.AcquisitionAggregate] {
        [
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Management Consulting Services",
                requirements: "Professional consulting services for advisory assistance and training programs",
                projectDescription: "Comprehensive consulting with professional services and management support",
                estimatedValue: 180_000,
                deadline: Date().addingTimeInterval(60 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Professional Training and Advisory Services",
                requirements: "Training services and advisory assistance for professional development and support",
                projectDescription: "Professional training programs with consulting and maintenance support services",
                estimatedValue: 120_000,
                deadline: Date().addingTimeInterval(90 * 24 * 3600),
                isRecurring: false
            ),
            AppCore.AcquisitionAggregate(
                id: UUID(),
                title: "Operations Management Support",
                requirements: "Professional operations management and advisory consulting services",
                projectDescription: "Comprehensive management support with professional services and operations consulting",
                estimatedValue: 220_000,
                deadline: Date().addingTimeInterval(75 * 24 * 3600),
                isRecurring: false
            ),
        ]
    }

    private func createLargeAcquisitionDataset(count: Int) -> [AppCore.AcquisitionAggregate] {
        let categories = ["IT", "Construction", "Services", "General"]
        let itKeywords = ["software", "hardware", "network", "database", "cybersecurity", "cloud"]
        let constructionKeywords = ["building", "construction", "renovation", "facility", "architectural", "contractor"]
        let serviceKeywords = ["consulting", "training", "advisory", "support", "management", "operations"]

        return (1 ... count).map { i in
            let category = categories[i % categories.count]
            let keywords: [String] = switch category {
            case "IT":
                itKeywords
            case "Construction":
                constructionKeywords
            case "Services":
                serviceKeywords
            default:
                ["general", "standard", "basic", "regular"]
            }

            let selectedKeywords = keywords.shuffled().prefix(3)
            let title = "\(category) Project \(i) - \(selectedKeywords.joined(separator: " "))"
            let requirements = "Professional \(selectedKeywords.joined(separator: ", ")) services needed for project \(i)"

            return AppCore.AcquisitionAggregate(
                id: UUID(),
                title: title,
                requirements: requirements,
                projectDescription: "Standard \(category.lowercased()) project with \(selectedKeywords.joined(separator: " and ")) requirements",
                estimatedValue: Double.random(in: 10000 ... 1_000_000),
                deadline: Date().addingTimeInterval(Double.random(in: 7 ... 180) * 24 * 3600),
                isRecurring: Bool.random()
            )
        }
    }
}

// MARK: - Test Extensions

// UrgencyLevel already conforms to Equatable in AIKO module

extension ComplexityLevel: Equatable {
    public static func == (lhs: ComplexityLevel, rhs: ComplexityLevel) -> Bool {
        switch (lhs, rhs) {
        case (.high, .high), (.medium, .medium), (.low, .low):
            true
        default:
            false
        }
    }
}
