import XCTest
@testable import GraphRAG
import Foundation
import CryptoKit

/// ACQ Security Compliance Test Suite - TDD RED Phase
/// Tests designed to FAIL initially, implementing government data security standards
/// Critical: FISMA compliance, data encryption, access controls, audit trails, PII protection
@available(iOS 17.0, *)
final class ACQSecurityComplianceTests: XCTestCase {

    private var templateProcessor: MemoryConstrainedTemplateProcessor?
    private var hybridSearchService: HybridSearchService?
    private var objectBoxIndex: ObjectBoxSemanticIndex?
    private var securityManager: SecurityManager?
    private var auditLogger: AuditLogger?

    override func setUpWithError() throws {
        // These will fail due to unimplemented components - RED phase intended behavior
        templateProcessor = MemoryConstrainedTemplateProcessor()
        hybridSearchService = HybridSearchService()
        objectBoxIndex = ObjectBoxSemanticIndex.shared
        securityManager = SecurityManager()
        auditLogger = AuditLogger()
    }

    override func tearDownWithError() throws {
        auditLogger = nil
        securityManager = nil
        objectBoxIndex = nil
        hybridSearchService = nil
        templateProcessor = nil
    }

    // MARK: - Government Data Encryption Tests

    /// Test encryption-at-rest for stored embeddings using iOS file protection
    /// CRITICAL: This test MUST FAIL initially until encryption is implemented
    
    func testEncryptionAtRestForTemplateEmbeddings() async throws {
        let objectBoxIndex = try unwrapService(objectBoxIndex)
        let securityManager = try unwrapService(securityManager)

        // Create sensitive government template data
        let sensitiveContent = createSensitiveGovernmentContent()
        let classifiedMetadata = createClassifiedMetadata()
        let embedding = generateTestEmbedding(dimensions: 384)

        // Store with encryption enabled
        try await objectBoxIndex.storeTemplateEmbedding(
            content: sensitiveContent,
            embedding: embedding,
            metadata: classifiedMetadata,
            encryptionLevel: .complete
        )

        // Verify file protection is applied
        let storageLocation = await objectBoxIndex.getStorageLocation(for: classifiedMetadata.templateId)
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: storageLocation.path)

        XCTAssertEqual(fileAttributes[.protectionKey] as? FileProtectionType, .complete,
                      "Classified data should use Complete file protection")

        // Verify encryption key management
        let encryptionKeyExists = await securityManager.hasEncryptionKey(for: classifiedMetadata.templateId)
        XCTAssertTrue(encryptionKeyExists, "Encryption key should be stored in keychain")

        // Verify data cannot be read without proper decryption
        let rawFileData = try Data(contentsOf: storageLocation)
        let isDataEncrypted = await securityManager.isDataEncrypted(rawFileData)
        XCTAssertTrue(isDataEncrypted, "Stored data should be encrypted")

        // Verify authorized retrieval works
        let retrievedResults = try await objectBoxIndex.findSimilar(
            to: embedding,
            limit: 5,
            namespace: "classified_templates",
            requiredClearance: .secret
        )

        XCTAssertGreaterThan(retrievedResults.count, 0, "Authorized retrieval should succeed")
    }

    /// Test secure keychain integration for sensitive metadata storage
    /// This test WILL FAIL until keychain integration is implemented
    
    func testSecureKeychainIntegration() async throws {
        let securityManager = try unwrapService(securityManager)
        let auditLogger = try unwrapService(auditLogger)

        let sensitiveMetadata = createSensitiveKeyData()
        let templateId = "classified-template-001"

        await auditLogger.logSecurityEvent(.keychainAccess, templateId: templateId, action: "store_attempt")

        // Store sensitive metadata in keychain
        try await securityManager.storeSecureMetadata(
            templateId: templateId,
            metadata: sensitiveMetadata,
            accessGroup: "com.aiko.classified"
        )

        // Verify keychain storage
        let keychainQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "AIKO-Templates",
            kSecAttrAccount: templateId,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQuery, &result)

        XCTAssertEqual(status, errSecSuccess, "Keychain storage should succeed")
        XCTAssertNotNil(result, "Stored data should be retrievable")

        // Verify data is encrypted in keychain
        guard let storedData = result as? Data else {
            XCTFail("Expected result to be Data type")
            return
        }
        let isEncrypted = await securityManager.isDataEncrypted(storedData)
        XCTAssertTrue(isEncrypted, "Keychain data should be encrypted")

        // Test authorized retrieval
        let retrievedMetadata = try await securityManager.retrieveSecureMetadata(
            templateId: templateId,
            requiredClearance: .secret
        )

        XCTAssertEqual(retrievedMetadata.classificationLevel, sensitiveMetadata.classificationLevel)

        await auditLogger.logSecurityEvent(.keychainAccess, templateId: templateId, action: "retrieve_success")
    }

    /// Test data transmission encryption with TLS 1.3+
    /// This test WILL FAIL until secure transmission is implemented
    
    func testSecureDataTransmissionEncryption() async throws {
        let securityManager = try unwrapService(securityManager)
        let auditLogger = try unwrapService(auditLogger)

        // Simulate secure template synchronization
        let sensitiveTemplate = createSensitiveGovernmentTemplate()

        await auditLogger.logSecurityEvent(.dataTransmission, templateId: sensitiveTemplate.metadata.templateId, action: "transmission_start")

        // Verify TLS configuration
        let tlsConfiguration = await securityManager.getTLSConfiguration()
        XCTAssertEqual(tlsConfiguration.minimumVersion, .tlsv13, "Should require TLS 1.3 minimum")
        XCTAssertTrue(tlsConfiguration.certificatePinningEnabled, "Certificate pinning should be enabled")

        // Test encrypted transmission
        let transmissionResult = try await securityManager.secureTransmit(
            template: sensitiveTemplate,
            destination: "secure.government.api",
            encryption: .endToEnd
        )

        XCTAssertTrue(transmissionResult.encrypted, "Transmission should be encrypted")
        XCTAssertNotNil(transmissionResult.integrityHash, "Should include integrity verification")
        XCTAssertEqual(transmissionResult.encryptionAlgorithm, "AES-256-GCM", "Should use strong encryption")

        // Verify transmission audit trail
        let auditEntries = await auditLogger.getSecurityEvents(for: sensitiveTemplate.metadata.templateId)
        let transmissionEvents = auditEntries.filter { $0.eventType == .dataTransmission }

        XCTAssertGreaterThan(transmissionEvents.count, 0, "Should log transmission events")

        await auditLogger.logSecurityEvent(.dataTransmission, templateId: sensitiveTemplate.metadata.templateId, action: "transmission_complete")
    }

    // MARK: - Access Control and Authentication Tests

    /// Test role-based access control for template retrieval
    /// This test WILL FAIL until RBAC system is implemented
    
    func testRoleBasedAccessControl() async throws {
        let hybridSearchService = try unwrapService(hybridSearchService)
        let securityManager = try unwrapService(securityManager)
        let auditLogger = try unwrapService(auditLogger)

        // Create templates with different classification levels
        let publicTemplate = createPublicTemplate()
        let confidentialTemplate = createConfidentialTemplate()
        let secretTemplate = createSecretTemplate()
        let topSecretTemplate = createTopSecretTemplate()

        let templates = [publicTemplate, confidentialTemplate, secretTemplate, topSecretTemplate]

        for template in templates {
            try await hybridSearchService.addTemplate(template)
        }

        // Test access with different user roles
        let testUsers = [
            TestUser(clearanceLevel: .public, roles: ["contractor"]),
            TestUser(clearanceLevel: .confidential, roles: ["government_employee"]),
            TestUser(clearanceLevel: .secret, roles: ["security_officer"]),
            TestUser(clearanceLevel: .topSecret, roles: ["intelligence_analyst"])
        ]

        for user in testUsers {
            await auditLogger.logSecurityEvent(.accessAttempt, templateId: "rbac_test", action: "user_\(user.clearanceLevel.rawValue)_search")

            // Authenticate user
            let authResult = try await securityManager.authenticateUser(user)
            XCTAssertTrue(authResult.success, "User authentication should succeed")

            // Perform search with user context
            await hybridSearchService.hybridSearch(
                query: "classified government contract",
                category: nil,
                limit: 10,
                userContext: UserSecurityContext(user: user, session: authResult.sessionToken)
            )

            let searchResults = hybridSearchService.searchResults

            // Verify access control enforcement
            for result in searchResults {
                let templateClearance = result.template.classificationLevel ?? .public
                XCTAssertLessThanOrEqual(templateClearance, user.clearanceLevel,
                                       "User should only access templates at or below their clearance level")
            }

            // Log successful access
            await auditLogger.logSecurityEvent(.accessGranted, templateId: "rbac_test", action: "search_completed_\(user.clearanceLevel.rawValue)")
        }

        // Test unauthorized access attempt
        let unauthorizedUser = TestUser(clearanceLevel: .public, roles: ["visitor"])

        await auditLogger.logSecurityEvent(.accessAttempt, templateId: secretTemplate.metadata.templateId, action: "unauthorized_access_attempt")

        do {
            _ = try await securityManager.authorizeTemplateAccess(
                templateId: secretTemplate.metadata.templateId,
                user: unauthorizedUser
            )
            XCTFail("Unauthorized access should be denied")
        } catch SecurityError.insufficientClearance {
            // Expected behavior
            await auditLogger.logSecurityEvent(.accessDenied, templateId: secretTemplate.metadata.templateId, action: "insufficient_clearance")
        }
    }

    /// Test multi-factor authentication for sensitive operations
    /// This test WILL FAIL until MFA system is implemented
    
    func testMultiFactorAuthentication() async throws {
        let securityManager = try unwrapService(securityManager)
        let auditLogger = try unwrapService(auditLogger)

        let sensitiveUser = TestUser(clearanceLevel: .topSecret, roles: ["intelligence_analyst"])

        await auditLogger.logSecurityEvent(.authenticationAttempt, templateId: "mfa_test", action: "primary_auth_start")

        // Step 1: Primary authentication (username/password)
        let primaryAuthResult = try await securityManager.authenticateUser(sensitiveUser)
        XCTAssertTrue(primaryAuthResult.success, "Primary authentication should succeed")
        XCTAssertTrue(primaryAuthResult.requiresMFA, "Should require MFA for sensitive operations")

        await auditLogger.logSecurityEvent(.authenticationStep, templateId: "mfa_test", action: "primary_auth_success")

        // Step 2: Biometric authentication (Face ID/Touch ID)
        let biometricResult = try await securityManager.performBiometricAuthentication(
            challenge: primaryAuthResult.mfaChallenge
        )

        XCTAssertTrue(biometricResult.success, "Biometric authentication should succeed")
        XCTAssertNotNil(biometricResult.biometricHash, "Should provide biometric verification hash")

        await auditLogger.logSecurityEvent(.authenticationStep, templateId: "mfa_test", action: "biometric_auth_success")

        // Step 3: Hardware token or TOTP (time-based one-time password)
        let totpCode = generateMockTOTP()
        let totpResult = try await securityManager.verifyTOTP(
            code: totpCode,
            userSession: primaryAuthResult.sessionToken
        )

        XCTAssertTrue(totpResult.success, "TOTP verification should succeed")

        await auditLogger.logSecurityEvent(.authenticationStep, templateId: "mfa_test", action: "totp_verification_success")

        // Complete MFA process
        let completeAuthResult = try await securityManager.completeMFAAuthentication(
            primaryToken: primaryAuthResult.sessionToken,
            biometricToken: biometricResult.token,
            totpToken: totpResult.token
        )

        XCTAssertTrue(completeAuthResult.success, "Complete MFA should succeed")
        XCTAssertNotNil(completeAuthResult.elevatedAccessToken, "Should provide elevated access token")
        XCTAssertGreaterThan(completeAuthResult.tokenExpirationTime, Date(), "Token should have future expiration")

        await auditLogger.logSecurityEvent(.authenticationComplete, templateId: "mfa_test", action: "mfa_complete_success")

        // Verify elevated access works
        let sensitiveTemplate = createTopSecretTemplate()
        let accessResult = try await securityManager.authorizeTemplateAccess(
            templateId: sensitiveTemplate.metadata.templateId,
            elevatedToken: completeAuthResult.elevatedAccessToken
        )

        XCTAssertTrue(accessResult.authorized, "Elevated access should be granted after MFA")

        await auditLogger.logSecurityEvent(.elevatedAccess, templateId: sensitiveTemplate.metadata.templateId, action: "access_granted_post_mfa")
    }

    // MARK: - PII Detection and Data Protection Tests

    /// Test PII detection and redaction in template content processing
    /// This test WILL FAIL until PII protection system is implemented
    
    func testPIIDetectionAndRedaction() async throws {
        let templateProcessor = try unwrapService(templateProcessor)
        let securityManager = try unwrapService(securityManager)
        let auditLogger = try unwrapService(auditLogger)

        // Create template content containing various PII types
        let piiContent = """
        Government Contract for John Smith (SSN: 123-45-6789)

        Contact Information:
        - Email: john.smith@government.gov
        - Phone: (555) 123-4567
        - Address: 1234 Government Way, Washington, DC 20001

        Credit Card: 4532-1234-5678-9012
        Driver's License: D123456789

        Bank Account: 987654321 (Routing: 021000021)
        Medical Record ID: MR-2023-001234

        Employee ID: EMP123456
        Security Badge: BADGE-TOP-SECRET-7890
        """

        let metadata = createTestMetadata()

        await auditLogger.logSecurityEvent(.piiProcessing, templateId: metadata.templateId, action: "pii_scan_start")

        // Process template with PII detection enabled
        let processedTemplate = try await templateProcessor.processTemplate(
            content: Data(piiContent.utf8),
            metadata: metadata,
            enablePIIDetection: true
        )

        // Verify PII was detected
        let piiReport = await securityManager.getPIIReport(for: metadata.templateId)
        XCTAssertGreaterThan(piiReport.detectedPIITypes.count, 0, "Should detect PII types")

        let expectedPIITypes: Set<PIIType> = [.ssn, .email, .phone, .address, .creditCard, .driverLicense, .bankAccount, .medicalRecord]
        for piiType in expectedPIITypes {
            XCTAssertTrue(piiReport.detectedPIITypes.contains(piiType), "Should detect \(piiType)")
        }

        // Verify PII was properly redacted in processed content
        let processedContent = processedTemplate.chunks.map { $0.content }.joined(separator: " ")

        XCTAssertFalse(processedContent.contains("123-45-6789"), "SSN should be redacted")
        XCTAssertFalse(processedContent.contains("john.smith@government.gov"), "Email should be redacted")
        XCTAssertFalse(processedContent.contains("4532-1234-5678-9012"), "Credit card should be redacted")
        XCTAssertFalse(processedContent.contains("987654321"), "Bank account should be redacted")

        // Verify redaction markers are present
        XCTAssertTrue(processedContent.contains("[PII-SSN-REDACTED]"), "Should have SSN redaction marker")
        XCTAssertTrue(processedContent.contains("[PII-EMAIL-REDACTED]"), "Should have email redaction marker")
        XCTAssertTrue(processedContent.contains("[PII-CREDIT-CARD-REDACTED]"), "Should have credit card redaction marker")

        // Verify original PII is securely stored (if needed for authorized access)
        let authorizedUser = TestUser(clearanceLevel: .topSecret, roles: ["pii_access_officer"])
        let originalContent = try await securityManager.retrieveOriginalContent(
            templateId: metadata.templateId,
            user: authorizedUser,
            justification: "Security audit review"
        )

        XCTAssertNotNil(originalContent, "Authorized user should access original content")
        XCTAssertTrue(originalContent!.contains("123-45-6789"), "Original content should contain unredacted PII")

        await auditLogger.logSecurityEvent(.piiProcessing, templateId: metadata.templateId, action: "pii_scan_complete")
        await auditLogger.logSecurityEvent(.piiAccess, templateId: metadata.templateId, action: "original_content_accessed")
    }

    /// Test secure memory scrubbing after sensitive data processing
    /// This test WILL FAIL until memory scrubbing is implemented
    
    func testSecureMemoryScrubbing() async throws {
        let templateProcessor = try unwrapService(templateProcessor)
        let securityManager = try unwrapService(securityManager)

        // Create highly sensitive content
        let sensitiveContent = createTopSecretContent()
        let metadata = createClassifiedMetadata()

        // Process sensitive template
        let processedTemplate = try await templateProcessor.processTemplate(
            content: Data(sensitiveContent.utf8),
            metadata: metadata
        )

        XCTAssertNotNil(processedTemplate, "Template should be processed successfully")

        // Verify sensitive data exists in memory initially
        let memoryContainsSensitiveData = await securityManager.scanMemoryForSensitiveData(sensitiveContent)
        XCTAssertTrue(memoryContainsSensitiveData, "Sensitive data should be present in memory during processing")

        // Trigger secure memory scrubbing
        await templateProcessor.performSecureMemoryCleanup()

        // Force garbage collection to ensure cleanup
        for _ in 0..<5 {
            autoreleasepool {
                _ = Data(count: 1024 * 1024)  // Allocate temporary memory to trigger GC
            }
        }

        // Wait for cleanup to complete
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms

        // Verify sensitive data has been scrubbed from memory
        let memoryStillContainsSensitiveData = await securityManager.scanMemoryForSensitiveData(sensitiveContent)
        XCTAssertFalse(memoryStillContainsSensitiveData, "Sensitive data should be scrubbed from memory")

        // Verify memory pattern overwriting
        let memoryPattern = await securityManager.verifyMemoryOverwritePattern()
        XCTAssertEqual(memoryPattern.overwritePattern, .zerosAndRandom, "Memory should be overwritten with secure pattern")
        XCTAssertGreaterThan(memoryPattern.overwritePasses, 2, "Should perform multiple overwrite passes")

        // Verify processed template is still accessible (not corrupted by cleanup)
        XCTAssertEqual(processedTemplate.chunks.count, 1, "Processed template should remain intact")
    }

    // MARK: - Audit Trail and Compliance Tests

    /// Test comprehensive audit trail generation for compliance
    /// This test WILL FAIL until audit system is implemented
    
    func testComprehensiveAuditTrailGeneration() async throws {
        let templateProcessor = try unwrapService(templateProcessor)
        let hybridSearchService = try unwrapService(hybridSearchService)
        let auditLogger = try unwrapService(auditLogger)

        let testUser = TestUser(clearanceLevel: .secret, roles: ["security_analyst"])
        let template = createSensitiveGovernmentTemplate()

        // Simulate complete workflow with audit logging

        // 1. Template ingestion
        await auditLogger.logSecurityEvent(.templateIngestion, templateId: template.metadata.templateId, action: "ingestion_start", user: testUser)

        let processed = try await templateProcessor.processTemplate(
            content: Data(template.chunks[0].content.utf8),
            metadata: template.metadata
        )

        await auditLogger.logSecurityEvent(.templateProcessing, templateId: template.metadata.templateId, action: "processing_complete", user: testUser)

        // 2. Template indexing
        try await hybridSearchService.addTemplate(processed)

        await auditLogger.logSecurityEvent(.templateIndexing, templateId: template.metadata.templateId, action: "indexing_complete", user: testUser)

        // 3. Search operations
        await auditLogger.logSecurityEvent(.searchQuery, templateId: "search_session", action: "search_start", user: testUser)

        await hybridSearchService.hybridSearch(
            query: "sensitive government contract",
            category: .contract,
            limit: 5,
            userContext: UserSecurityContext(user: testUser, session: "session-123")
        )

        await auditLogger.logSecurityEvent(.searchResults, templateId: "search_session", action: "results_returned", user: testUser)

        // 4. Template access
        await auditLogger.logSecurityEvent(.templateAccess, templateId: template.metadata.templateId, action: "content_viewed", user: testUser)

        // Verify comprehensive audit trail
        let allAuditEvents = await auditLogger.getAllSecurityEvents()
        let templateEvents = allAuditEvents.filter { $0.templateId == template.metadata.templateId }

        XCTAssertGreaterThanOrEqual(templateEvents.count, 4, "Should have multiple audit events for template")

        // Verify required audit fields are present
        for event in templateEvents {
            XCTAssertNotNil(event.timestamp, "Audit event should have timestamp")
            XCTAssertNotNil(event.userId, "Audit event should have user ID")
            XCTAssertNotNil(event.sessionId, "Audit event should have session ID")
            XCTAssertNotNil(event.ipAddress, "Audit event should have IP address")
            XCTAssertNotNil(event.userAgent, "Audit event should have user agent")
            XCTAssertNotNil(event.eventType, "Audit event should have event type")
            XCTAssertNotNil(event.action, "Audit event should have specific action")
            XCTAssertNotNil(event.outcome, "Audit event should have outcome")
        }

        // Verify audit trail integrity
        let auditIntegrityResult = await auditLogger.verifyAuditIntegrity()
        XCTAssertTrue(auditIntegrityResult.valid, "Audit trail should maintain integrity")
        XCTAssertNil(auditIntegrityResult.tamperedEvents, "No events should be tampered with")

        // Test audit export for compliance reporting
        let complianceReport = try await auditLogger.generateComplianceReport(
            timeRange: DateInterval(start: Date().addingTimeInterval(-3600), end: Date()),
            includeEvents: [.templateAccess, .searchQuery, .authenticationAttempt]
        )

        XCTAssertNotNil(complianceReport, "Should generate compliance report")
        XCTAssertGreaterThan(complianceReport.eventCount, 0, "Compliance report should contain events")
        XCTAssertTrue(complianceReport.isDigitallySigned, "Report should be digitally signed")
    }

    /// Test data retention policy enforcement with automatic cleanup
    /// This test WILL FAIL until retention policy system is implemented
    
    func testDataRetentionPolicyEnforcement() async throws {
        let securityManager = try unwrapService(securityManager)
        let auditLogger = try unwrapService(auditLogger)

        // Create templates with different retention requirements
        let shortRetentionTemplate = createTemplateWithRetention(days: 30)
        let standardRetentionTemplate = createTemplateWithRetention(days: 365)
        let longRetentionTemplate = createTemplateWithRetention(days: 2555) // 7 years

        let templates = [shortRetentionTemplate, standardRetentionTemplate, longRetentionTemplate]

        // Set template creation dates to simulate age
        for template in templates {
            let retentionDays = template.metadata.retentionPolicy?.retentionDays ?? 365
            let creationDate = Date().addingTimeInterval(-TimeInterval(retentionDays + 1) * 24 * 60 * 60) // 1 day past retention

            try await securityManager.setTemplateCreationDate(
                templateId: template.metadata.templateId,
                creationDate: creationDate
            )
        }

        // Trigger retention policy enforcement
        await auditLogger.logSecurityEvent(.retentionPolicyCheck, templateId: "system", action: "policy_enforcement_start")

        let retentionResults = try await securityManager.enforceRetentionPolicy()

        await auditLogger.logSecurityEvent(.retentionPolicyEnforcement, templateId: "system", action: "policy_enforcement_complete")

        // Verify retention policy enforcement results
        XCTAssertEqual(retentionResults.templatesEvaluated, templates.count, "Should evaluate all templates")
        XCTAssertEqual(retentionResults.templatesDeleted, 3, "All templates should be past retention")
        XCTAssertEqual(retentionResults.templatesArchived, 0, "No templates should be archived in this test")

        // Verify secure deletion
        for template in templates {
            let exists = await securityManager.templateExists(templateId: template.metadata.templateId)
            XCTAssertFalse(exists, "Expired template should be deleted: \(template.metadata.templateId)")

            // Verify deletion audit trail
            let deletionEvents = await auditLogger.getSecurityEvents(for: template.metadata.templateId)
            let deletionEvent = deletionEvents.first { $0.eventType == .templateDeletion }

            XCTAssertNotNil(deletionEvent, "Should log deletion event for \(template.metadata.templateId)")
            XCTAssertEqual(deletionEvent?.outcome, .success, "Deletion should be successful")
        }

        // Verify retention policy documentation
        let retentionReport = try await securityManager.generateRetentionPolicyReport()
        XCTAssertNotNil(retentionReport, "Should generate retention policy report")
        XCTAssertGreaterThan(retentionReport.policiesEnforced, 0, "Should have enforced retention policies")
        XCTAssertEqual(retentionReport.complianceStatus, .compliant, "Should be in compliance after enforcement")
    }

    // MARK: - Test Helper Methods

    private func createSensitiveGovernmentContent() -> String {
        """
        CLASSIFIED GOVERNMENT CONTRACT - SECRET LEVEL

        This document contains sensitive information related to national security
        operations and should only be accessed by personnel with appropriate
        security clearance.

        Contract Details:
        - Project: Advanced Cybersecurity Initiative
        - Classification: SECRET//NOFORN
        - Compartment: SPECIAL ACCESS PROGRAM
        - Originator: Department of Defense
        """
    }

    private func createClassifiedMetadata() -> TemplateMetadata {
        TemplateMetadata(
            templateId: "classified-template-001",
            fileName: "classified-contract.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Department of Defense",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 2048,
            checksum: "classified-checksum-001",
            classificationLevel: .secret,
            compartments: ["SAP", "NOFORN"],
            retentionPolicy: RetentionPolicy(retentionDays: 2555, deletionMethod: .secureOverwrite)
        )
    }

    private func createSensitiveKeyData() -> SensitiveMetadata {
        SensitiveMetadata(
            encryptionKey: "AES256-GCM-KEY-12345",
            classificationLevel: .secret,
            accessControlList: ["security_officer", "intelligence_analyst"],
            compartments: ["SAP"],
            handlingInstructions: "DESTROY AFTER READING"
        )
    }

    private func createSensitiveGovernmentTemplate() -> ProcessedTemplate {
        let content = createSensitiveGovernmentContent()
        let chunk = TemplateChunk(
            content: content,
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
            isMemoryMapped: false
        )

        return ProcessedTemplate(
            chunks: [chunk],
            category: .contract,
            metadata: createClassifiedMetadata(),
            processingMode: .normal
        )
    }

    private func createPublicTemplate() -> ProcessedTemplate {
        let metadata = TemplateMetadata(
            templateId: "public-template-001",
            fileName: "public-contract.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "General Services Administration",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 1024,
            checksum: "public-checksum-001",
            classificationLevel: .public
        )

        let content = "Public procurement contract template for commercial IT services."
        let chunk = TemplateChunk(
            content: content,
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
            isMemoryMapped: false
        )

        return ProcessedTemplate(chunks: [chunk], category: .contract, metadata: metadata, processingMode: .normal)
    }

    private func createConfidentialTemplate() -> ProcessedTemplate {
        let metadata = TemplateMetadata(
            templateId: "confidential-template-001",
            fileName: "confidential-contract.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Department of Homeland Security",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 1536,
            checksum: "confidential-checksum-001",
            classificationLevel: .confidential
        )

        let content = "CONFIDENTIAL - Cybersecurity services contract with sensitive implementation details."
        let chunk = TemplateChunk(
            content: content,
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
            isMemoryMapped: false
        )

        return ProcessedTemplate(chunks: [chunk], category: .contract, metadata: metadata, processingMode: .normal)
    }

    private func createSecretTemplate() -> ProcessedTemplate {
        let metadata = TemplateMetadata(
            templateId: "secret-template-001",
            fileName: "secret-contract.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "National Security Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 2048,
            checksum: "secret-checksum-001",
            classificationLevel: .secret
        )

        let content = "SECRET - Advanced intelligence platform development contract with classified specifications."
        let chunk = TemplateChunk(
            content: content,
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
            isMemoryMapped: false
        )

        return ProcessedTemplate(chunks: [chunk], category: .contract, metadata: metadata, processingMode: .normal)
    }

    private func createTopSecretTemplate() -> ProcessedTemplate {
        let metadata = TemplateMetadata(
            templateId: "topsecret-template-001",
            fileName: "topsecret-contract.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Central Intelligence Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 4096,
            checksum: "topsecret-checksum-001",
            classificationLevel: .topSecret,
            compartments: ["SAP", "SCI"]
        )

        let content = "TOP SECRET//SCI - Covert operations support system development with special access program requirements."
        let chunk = TemplateChunk(
            content: content,
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
            isMemoryMapped: false
        )

        return ProcessedTemplate(chunks: [chunk], category: .contract, metadata: metadata, processingMode: .normal)
    }

    private func createTopSecretContent() -> String {
        """
        TOP SECRET//SCI//SAP

        SPECIAL ACCESS PROGRAM
        COMPARTMENT: QUANTUM SECURITY INITIATIVE

        This document contains information about advanced cryptographic systems
        and quantum computing applications for national security purposes.

        Sensitive Details:
        - Quantum key distribution protocols
        - Advanced encryption algorithms
        - Personnel with Q clearance access only
        - Destroy after reading

        Classification Authority: NSA
        Declassification: 25X1, 25X2
        """
    }

    private func createTestMetadata() -> TemplateMetadata {
        TemplateMetadata(
            templateId: "pii-test-template-001",
            fileName: "pii-test.pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Test Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 2048,
            checksum: "pii-test-checksum-001"
        )
    }

    private func createTemplateWithRetention(days: Int) -> ProcessedTemplate {
        let metadata = TemplateMetadata(
            templateId: "retention-template-\(days)d",
            fileName: "retention-template-\(days).pdf",
            fileType: "PDF",
            category: .contract,
            agency: "Test Agency",
            effectiveDate: Date(),
            lastModified: Date(),
            fileSize: 1024,
            checksum: "retention-checksum-\(days)",
            retentionPolicy: RetentionPolicy(retentionDays: days, deletionMethod: .secureOverwrite)
        )

        let content = "Test template with \(days) day retention policy."
        let chunk = TemplateChunk(
            content: content,
            chunkIndex: 0,
            overlap: "",
            metadata: ChunkMetadata(startOffset: 0, endOffset: content.count, tokens: content.split(separator: " ").count),
            isMemoryMapped: false
        )

        return ProcessedTemplate(chunks: [chunk], category: .contract, metadata: metadata, processingMode: .normal)
    }

    private func generateTestEmbedding(dimensions: Int) -> [Float] {
        var embedding = [Float](repeating: 0.0, count: dimensions)

        for i in 0..<dimensions {
            embedding[i] = Float.random(in: -1.0...1.0) * 0.1
        }

        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    private func generateMockTOTP() -> String {
        let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return String((0..<6).map { _ in digits.randomElement()! })
    }
}

// MARK: - Supporting Security Types (Will fail until implemented)

enum SecurityClearanceLevel: Int, Comparable {
    case publicLevel = 0
    case confidential = 1
    case secret = 2
    case topSecret = 3

    static func < (lhs: SecurityClearanceLevel, rhs: SecurityClearanceLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum SecurityEventType {
    case keychainAccess
    case dataTransmission
    case accessAttempt
    case accessGranted
    case accessDenied
    case authenticationAttempt
    case authenticationStep
    case authenticationComplete
    case elevatedAccess
    case piiProcessing
    case piiAccess
    case templateIngestion
    case templateProcessing
    case templateIndexing
    case templateAccess
    case templateDeletion
    case searchQuery
    case searchResults
    case retentionPolicyCheck
    case retentionPolicyEnforcement
}

enum SecurityError: Error {
    case insufficientClearance
    case authenticationFailed
    case mfaRequired
    case accessDenied
    case encryptionFailed
    case keyNotFound
}

enum PIIType {
    case ssn
    case email
    case phone
    case address
    case creditCard
    case driverLicense
    case bankAccount
    case medicalRecord
}

enum EncryptionLevel {
    case none
    case basic
    case complete
}

enum OutcomeType {
    case success
    case failure
    case denied
}

enum ComplianceStatus {
    case compliant
    case nonCompliant
    case unknown
}

enum DeletionMethod {
    case standard
    case secureOverwrite
    case cryptographicDestruction
}

enum OverwritePattern {
    case zeros
    case random
    case zerosAndRandom
}

struct TestUser {
    let clearanceLevel: SecurityClearanceLevel
    let roles: [String]
    let userId: String

    init(clearanceLevel: SecurityClearanceLevel, roles: [String]) {
        self.clearanceLevel = clearanceLevel
        self.roles = roles
        self.userId = "user_\(clearanceLevel.rawValue)_\(UUID().uuidString.prefix(8))"
    }
}

struct UserSecurityContext {
    let user: TestUser
    let session: String
}

struct SensitiveMetadata {
    let encryptionKey: String
    let classificationLevel: SecurityClearanceLevel
    let accessControlList: [String]
    let compartments: [String]
    let handlingInstructions: String
}

struct RetentionPolicy {
    let retentionDays: Int
    let deletionMethod: DeletionMethod
}

struct PIIReport {
    let detectedPIITypes: Set<PIIType>
    let redactionCount: Int
    let confidenceScore: Double
}

struct TLSConfiguration {
    let minimumVersion: TLSVersion
    let certificatePinningEnabled: Bool
    let allowedCipherSuites: [String]
}

enum TLSVersion {
    case tlsv12
    case tlsv13
}

struct TransmissionResult {
    let encrypted: Bool
    let integrityHash: String?
    let encryptionAlgorithm: String
}

struct AuthenticationResult {
    let success: Bool
    let requiresMFA: Bool
    let sessionToken: String
    let mfaChallenge: String?
}

struct BiometricResult {
    let success: Bool
    let biometricHash: String?
    let token: String
}

struct TOTPResult {
    let success: Bool
    let token: String
}

struct CompleteAuthResult {
    let success: Bool
    let elevatedAccessToken: String?
    let tokenExpirationTime: Date
}

struct AccessAuthorizationResult {
    let authorized: Bool
    let reason: String?
}

struct SecurityEvent {
    let timestamp: Date
    let templateId: String?
    let userId: String?
    let sessionId: String?
    let ipAddress: String?
    let userAgent: String?
    let eventType: SecurityEventType
    let action: String
    let outcome: OutcomeType?
}

struct AuditIntegrityResult {
    let valid: Bool
    let tamperedEvents: [String]?
}

struct ComplianceReport {
    let eventCount: Int
    let timeRange: DateInterval
    let isDigitallySigned: Bool
}

struct RetentionResults {
    let templatesEvaluated: Int
    let templatesDeleted: Int
    let templatesArchived: Int
}

struct RetentionPolicyReport {
    let policiesEnforced: Int
    let complianceStatus: ComplianceStatus
}

struct MemoryOverwritePattern {
    let overwritePattern: OverwritePattern
    let overwritePasses: Int
}

// Placeholder implementations that will fail
class SecurityManager {
    func hasEncryptionKey(for templateId: String) async -> Bool {
        fatalError("SecurityManager.hasEncryptionKey not implemented - RED phase")
    }

    func isDataEncrypted(_ data: Data) async -> Bool {
        fatalError("SecurityManager.isDataEncrypted not implemented - RED phase")
    }

    func storeSecureMetadata(templateId: String, metadata: SensitiveMetadata, accessGroup: String) async throws {
        fatalError("SecurityManager.storeSecureMetadata not implemented - RED phase")
    }

    func retrieveSecureMetadata(templateId: String, requiredClearance: SecurityClearanceLevel) async throws -> SensitiveMetadata {
        fatalError("SecurityManager.retrieveSecureMetadata not implemented - RED phase")
    }

    func getTLSConfiguration() async -> TLSConfiguration {
        fatalError("SecurityManager.getTLSConfiguration not implemented - RED phase")
    }

    func secureTransmit(template: ProcessedTemplate, destination: String, encryption: EncryptionLevel) async throws -> TransmissionResult {
        fatalError("SecurityManager.secureTransmit not implemented - RED phase")
    }

    func authenticateUser(_ user: TestUser) async throws -> AuthenticationResult {
        fatalError("SecurityManager.authenticateUser not implemented - RED phase")
    }

    func authorizeTemplateAccess(templateId: String, user: TestUser) async throws -> AccessAuthorizationResult {
        fatalError("SecurityManager.authorizeTemplateAccess not implemented - RED phase")
    }

    func authorizeTemplateAccess(templateId: String, elevatedToken: String) async throws -> AccessAuthorizationResult {
        fatalError("SecurityManager.authorizeTemplateAccess not implemented - RED phase")
    }

    func performBiometricAuthentication(challenge: String?) async throws -> BiometricResult {
        fatalError("SecurityManager.performBiometricAuthentication not implemented - RED phase")
    }

    func verifyTOTP(code: String, userSession: String) async throws -> TOTPResult {
        fatalError("SecurityManager.verifyTOTP not implemented - RED phase")
    }

    func completeMFAAuthentication(primaryToken: String, biometricToken: String, totpToken: String) async throws -> CompleteAuthResult {
        fatalError("SecurityManager.completeMFAAuthentication not implemented - RED phase")
    }

    func getPIIReport(for templateId: String) async -> PIIReport {
        fatalError("SecurityManager.getPIIReport not implemented - RED phase")
    }

    func retrieveOriginalContent(templateId: String, user: TestUser, justification: String) async throws -> String? {
        fatalError("SecurityManager.retrieveOriginalContent not implemented - RED phase")
    }

    func scanMemoryForSensitiveData(_ content: String) async -> Bool {
        fatalError("SecurityManager.scanMemoryForSensitiveData not implemented - RED phase")
    }

    func verifyMemoryOverwritePattern() async -> MemoryOverwritePattern {
        fatalError("SecurityManager.verifyMemoryOverwritePattern not implemented - RED phase")
    }

    func setTemplateCreationDate(templateId: String, creationDate: Date) async throws {
        fatalError("SecurityManager.setTemplateCreationDate not implemented - RED phase")
    }

    func enforceRetentionPolicy() async throws -> RetentionResults {
        fatalError("SecurityManager.enforceRetentionPolicy not implemented - RED phase")
    }

    func templateExists(templateId: String) async -> Bool {
        fatalError("SecurityManager.templateExists not implemented - RED phase")
    }

    func generateRetentionPolicyReport() async throws -> RetentionPolicyReport {
        fatalError("SecurityManager.generateRetentionPolicyReport not implemented - RED phase")
    }
}

class AuditLogger {
    func logSecurityEvent(_ eventType: SecurityEventType, templateId: String, action: String, user: TestUser? = nil) async {
        fatalError("AuditLogger.logSecurityEvent not implemented - RED phase")
    }

    func getSecurityEvents(for templateId: String) async -> [SecurityEvent] {
        fatalError("AuditLogger.getSecurityEvents not implemented - RED phase")
    }

    func getAllSecurityEvents() async -> [SecurityEvent] {
        fatalError("AuditLogger.getAllSecurityEvents not implemented - RED phase")
    }

    func verifyAuditIntegrity() async -> AuditIntegrityResult {
        fatalError("AuditLogger.verifyAuditIntegrity not implemented - RED phase")
    }

    func generateComplianceReport(timeRange: DateInterval, includeEvents: [SecurityEventType]) async throws -> ComplianceReport {
        fatalError("AuditLogger.generateComplianceReport not implemented - RED phase")
    }
}

// Extensions to existing types for security testing
extension TemplateMetadata {
    var classificationLevel: SecurityClearanceLevel? { nil }
    var compartments: [String]? { nil }
    var retentionPolicy: RetentionPolicy? { nil }

    init(templateId: String, fileName: String, fileType: String, category: TemplateCategory?, agency: String?, effectiveDate: Date?, lastModified: Date, fileSize: Int64, checksum: String, classificationLevel: SecurityClearanceLevel? = nil, compartments: [String]? = nil, retentionPolicy: RetentionPolicy? = nil) {
        self.init(templateId: templateId, fileName: fileName, fileType: fileType, category: category, agency: agency, effectiveDate: effectiveDate, lastModified: lastModified, fileSize: fileSize, checksum: checksum)
    }
}

extension MemoryConstrainedTemplateProcessor {
    func processTemplate(content: Data, metadata: TemplateMetadata, enablePIIDetection: Bool) async throws -> ProcessedTemplate {
        fatalError("MemoryConstrainedTemplateProcessor.processTemplate with PII detection not implemented - RED phase")
    }

    func performSecureMemoryCleanup() async {
        fatalError("MemoryConstrainedTemplateProcessor.performSecureMemoryCleanup not implemented - RED phase")
    }
}

extension HybridSearchService {
    func hybridSearch(query: String, category: TemplateCategory?, limit: Int, userContext: UserSecurityContext) async {
        fatalError("HybridSearchService.hybridSearch with security context not implemented - RED phase")
    }
}

extension ObjectBoxSemanticIndex {
    func storeTemplateEmbedding(content: String, embedding: [Float], metadata: TemplateMetadata, encryptionLevel: EncryptionLevel) async throws {
        fatalError("ObjectBoxSemanticIndex.storeTemplateEmbedding with encryption not implemented - RED phase")
    }

    func getStorageLocation(for templateId: String) async -> URL {
        fatalError("ObjectBoxSemanticIndex.getStorageLocation not implemented - RED phase")
    }

    func findSimilar(to embedding: [Float], limit: Int, namespace: String, requiredClearance: SecurityClearanceLevel) async throws -> [TemplateSearchResult] {
        fatalError("ObjectBoxSemanticIndex.findSimilar with clearance not implemented - RED phase")
    }
}
