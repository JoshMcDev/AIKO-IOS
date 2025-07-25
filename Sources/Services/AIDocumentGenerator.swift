import AikoCompat
import AppCore
import Foundation

public struct AIDocumentGenerator: Sendable {
    public var generateDocuments: @Sendable (String, Set<DocumentType>) async throws -> [GeneratedDocument]
    public var generateDFDocuments: @Sendable (String, Set<DFDocumentType>) async throws -> [GeneratedDocument]

    public init(
        generateDocuments: @escaping @Sendable (String, Set<DocumentType>) async throws -> [GeneratedDocument],
        generateDFDocuments: @escaping @Sendable (String, Set<DFDocumentType>) async throws -> [GeneratedDocument]
    ) {
        self.generateDocuments = generateDocuments
        self.generateDFDocuments = generateDFDocuments
    }
}

public extension AIDocumentGenerator {
    static var liveValue: AIDocumentGenerator {
        AIDocumentGenerator(
            generateDocuments: { requirements, documentTypes in
                // TODO: Replace with proper dependency injection
                let templateService = StandardTemplateService.liveValue
                let userProfileService = UserProfileService.liveValue
                let cache = DocumentGenerationCacheKey.liveValue
                let spellCheckService = SpellCheckService.liveValue

                guard let aiProvider = await AIProviderFactory.defaultProvider() else {
                    throw AIDocumentGeneratorError.noProvider
                }
                var generatedDocuments: [GeneratedDocument] = []

                // Load user profile for template variables
                let profile = try? await userProfileService.loadProfile()

                for documentType in documentTypes {
                    // Check cache first
                    if let cachedContent = await cache.getCachedDocument(
                        for: documentType,
                        requirements: requirements,
                        profile: profile
                    ) {
                        let dateString = Date().formatted(date: .abbreviated, time: .omitted)
                        let title = "\(documentType.shortName) - \(dateString)"
                        let document = GeneratedDocument(
                            title: title,
                            documentType: documentType,
                            content: cachedContent
                        )
                        generatedDocuments.append(document)
                        continue
                    }

                    // Try to load template from cache or service
                    let template: String?
                    if let cachedTemplate = await cache.getCachedTemplate(for: documentType) {
                        template = cachedTemplate
                    } else if let loadedTemplate = try? await templateService.loadTemplate(documentType) {
                        await cache.cacheTemplate(loadedTemplate, for: documentType)
                        template = loadedTemplate
                    } else {
                        template = nil
                    }

                    let prompt: String
                    if let template {
                        // Replace profile variables in template
                        var processedTemplate = template
                        if let profile {
                            for (key, value) in profile.templateVariables {
                                processedTemplate = processedTemplate.replacingOccurrences(
                                    of: "{{\(key)}}",
                                    with: value
                                )
                            }
                        }

                        // Use template-based prompt
                        prompt = createTemplateBasedPrompt(
                            for: documentType,
                            requirements: requirements,
                            template: processedTemplate,
                            profile: profile
                        )
                    } else {
                        // Fall back to original prompt
                        prompt = createPrompt(for: documentType, requirements: requirements, profile: profile)
                    }

                    let messages = [
                        AIMessage.user(prompt),
                    ]

                    // Get system prompt (with caching)
                    let systemPrompt: String
                    if let cachedPrompt = await cache.getCachedSystemPrompt(for: documentType) {
                        systemPrompt = cachedPrompt
                    } else {
                        systemPrompt = getSystemPrompt(for: documentType)
                        await cache.cacheSystemPrompt(systemPrompt, for: documentType)
                    }

                    let request = AICompletionRequest(
                        messages: messages,
                        model: "claude-sonnet-4-20250514",
                        maxTokens: 4096,
                        systemPrompt: systemPrompt
                    )

                    let result = try await aiProvider.complete(request)
                    let content = result.content

                    // Spell check and correct the content
                    let correctedContent = await spellCheckService.checkAndCorrect(content)

                    // Cache the generated document
                    await cache.cacheDocument(
                        correctedContent,
                        for: documentType,
                        requirements: requirements,
                        profile: profile
                    )

                    let document = GeneratedDocument(
                        title: "\(documentType.shortName) - \(Date().formatted(date: .abbreviated, time: .omitted))",
                        documentType: documentType,
                        content: correctedContent
                    )

                    generatedDocuments.append(document)
                }

                return generatedDocuments
            },
            generateDFDocuments: { requirements, dfDocumentTypes in
                // TODO: Replace with proper dependency injection
                let dfTemplateService = DFTemplateService.liveValue
                let userProfileService = UserProfileService.liveValue
                let cache = DocumentGenerationCacheKey.liveValue
                let spellCheckService = SpellCheckService.liveValue

                guard let aiProvider = await AIProviderFactory.defaultProvider() else {
                    throw AIDocumentGeneratorError.noProvider
                }
                var generatedDocuments: [GeneratedDocument] = []

                // Load user profile for template variables
                let profile = try? await userProfileService.loadProfile()

                for dfDocumentType in dfDocumentTypes {
                    // Check cache first
                    if let cachedContent = await cache.getCachedDocument(
                        for: dfDocumentType,
                        requirements: requirements,
                        profile: profile
                    ) {
                        let document = GeneratedDocument(
                            title: "\(dfDocumentType.shortName) D&F - \(Date().formatted(date: .abbreviated, time: .omitted))",
                            dfDocumentType: dfDocumentType,
                            content: cachedContent
                        )
                        generatedDocuments.append(document)
                        continue
                    }

                    // Load the template and quick reference guide
                    let dfTemplate = try await dfTemplateService.loadTemplate(dfDocumentType)

                    // Replace profile variables in template
                    var processedTemplate = dfTemplate.template
                    if let profile {
                        for (key, value) in profile.templateVariables {
                            processedTemplate = processedTemplate.replacingOccurrences(of: "{{\(key)}}", with: value)
                        }
                    }

                    let prompt = createDFPrompt(
                        for: dfDocumentType,
                        requirements: requirements,
                        template: processedTemplate,
                        quickReference: dfTemplate.quickReferenceGuide,
                        profile: profile
                    )

                    let messages = [
                        AIMessage.user(prompt),
                    ]

                    // Get system prompt (with caching)
                    let systemPrompt: String
                    if let cachedPrompt = await cache.getCachedSystemPrompt(for: dfDocumentType) {
                        systemPrompt = cachedPrompt
                    } else {
                        systemPrompt = getDFSystemPrompt(for: dfDocumentType)
                        await cache.cacheSystemPrompt(systemPrompt, for: dfDocumentType)
                    }

                    let request = AICompletionRequest(
                        messages: messages,
                        model: "claude-sonnet-4-20250514",
                        maxTokens: 4096,
                        systemPrompt: systemPrompt
                    )

                    let result = try await aiProvider.complete(request)
                    let content = result.content

                    // Spell check and correct the content
                    let correctedContent = await spellCheckService.checkAndCorrect(content)

                    // Cache the generated document
                    await cache.cacheDocument(
                        correctedContent,
                        for: dfDocumentType,
                        requirements: requirements,
                        profile: profile
                    )

                    let document = GeneratedDocument(
                        title: "\(dfDocumentType.shortName) D&F - \(Date().formatted(date: .abbreviated, time: .omitted))",
                        dfDocumentType: dfDocumentType,
                        content: correctedContent
                    )

                    generatedDocuments.append(document)
                }

                return generatedDocuments
            }
        )
    }

    static var testValue: AIDocumentGenerator {
        AIDocumentGenerator(
            generateDocuments: { requirements, documentTypes in
                documentTypes.map { documentType in
                    GeneratedDocument(
                        title: "Test \(documentType.shortName)",
                        documentType: documentType,
                        content: "Test document content for \(documentType.rawValue)\n\nRequirements: \(requirements)"
                    )
                }
            },
            generateDFDocuments: { requirements, dfDocumentTypes in
                dfDocumentTypes.map { dfDocumentType in
                    GeneratedDocument(
                        title: "Test \(dfDocumentType.shortName) D&F",
                        dfDocumentType: dfDocumentType,
                        content: "Test D&F document content for \(dfDocumentType.rawValue)\n\nRequirements: \(requirements)"
                    )
                }
            }
        )
    }

    static func createPrompt(for documentType: DocumentType, requirements: String, profile: UserProfile?) -> String {
        // Build the requirements with user profile if available
        var fullRequirements = requirements

        if let profile {
            fullRequirements += """


            USER PROFILE INFORMATION:
            Full Name: \(profile.fullName)
            Title: \(profile.title)
            Organization: \(profile.organizationName)
            DODAAC: \(profile.organizationalDODAAC)
            Email: \(profile.email)
            Phone: \(profile.phoneNumber)
            """
        }

        // Use the government acquisition prompts for the specific document type
        return GovernmentAcquisitionPrompts.promptForDocumentType(documentType, requirements: fullRequirements)
    }

    static func getSystemPrompt(for _: DocumentType) -> String {
        // Use the government acquisition expert prompts
        GovernmentAcquisitionPrompts.systemPrompt + "\n\n" + GovernmentAcquisitionPrompts.contextPrompt
    }

    private static func getSystemPromptOld(for documentType: DocumentType) -> String {
        let formattingInstructions = """

        FORMATTING INSTRUCTIONS:
        - Use markdown-style formatting for better readability
        - Use # for main headings, ## for subheadings
        - Use **bold** for emphasis on important terms
        - Use bullet points (- ) for lists
        - Use numbered lists (1. ) for sequential steps
        - Separate sections with blank lines
        - Make the document professional and well-structured
        """

        if documentType == .requestForProposal {
            return """
            You are an expert federal contracting officer specializing in complex acquisitions and Request for
            Proposal (RFP) documents. You have extensive experience with FAR Part 15 negotiated procurements and
            understand how to structure comprehensive RFPs. Your RFPs include all required sections (A through M),
            clear evaluation criteria, and detailed instructions to offerors. You excel at crafting requirements
            that encourage innovation while ensuring fair competition. Your documents are professionally written,
            legally compliant, and designed to elicit high-quality proposals from industry.
            \(formattingInstructions)
            """
        } else if documentType == .rrd {
            return """
            You are AIKO, an expert federal contracting AI assistant conducting an interactive requirements
            refinement session. Your role is to guide the user through a structured dialogue to gather, clarify,
            and refine their procurement requirements. You should ask probing questions, identify gaps, suggest
            enhancements, and help transform vague needs into clear, actionable requirements. Use your expertise
            in federal contracting to anticipate needs, identify risks, and recommend best practices. The output
            should be a comprehensive Statement of Requirements that can serve as the foundation for all subsequent
            procurement documents. Be conversational yet professional, and always explain the reasoning behind your
            questions and recommendations to educate the user about federal procurement best practices.
            \(formattingInstructions)
            """
        } else if documentType == .evaluationPlan {
            return """
            You are an expert federal contracting officer specializing in source selection and evaluation
            procedures. You have extensive experience with FAR Part 12 commercial item acquisitions and FAR Part 15
            negotiated procurements. You understand how to develop comprehensive evaluation plans that ensure fair,
            transparent, and defensible source selections. Your evaluation plans include clear criteria, detailed
            methodologies, and structured approaches that comply with FAR 52.212-1 and FAR 52.212-2 for commercial
            items. You excel at creating evaluation factors that align with acquisition objectives while maintaining
            objectivity and consistency. Your documents are professionally written, legally compliant, and designed
            to guide evaluation teams through complex source selections.
            \(formattingInstructions)
            """
        } else if documentType == .contractScaffold {
            return """
            You are an expert federal contracting officer specializing in contract formation and award documents.
            You have extensive experience creating comprehensive contract packages that comply with all FAR requirements.
            You understand the structure and content needed for complete contract files, including all mandatory clauses,
            terms and conditions, and administrative provisions. Your contract scaffolds provide a solid foundation for
            contract awards while ensuring all legal and regulatory requirements are met. You excel at organizing contract
            documents for clarity and compliance.
            \(formattingInstructions)
            """
        } else if documentType == .corAppointment {
            return """
            You are an expert federal contracting officer with extensive experience in contract administration.
            You understand the critical role of Contracting Officer's Representatives (CORs) in ensuring successful
            contract performance. You are well-versed in FAR Part 1.604 and agency-specific COR policies.
            Your COR appointment letters clearly define roles, responsibilities, authorities, and limitations while
            ensuring proper oversight and administration of government contracts. You create comprehensive appointment
            documents that protect both the government's interests and support CORs in their duties.
            \(formattingInstructions)
            """
        } else if documentType == .analytics {
            return """
            You are an expert in federal procurement analytics and performance measurement.
            You understand key procurement metrics, spend analysis, vendor performance indicators, and contract
            compliance monitoring. You excel at creating comprehensive analytics dashboards that provide actionable
            insights for procurement professionals. Your analytics documents help identify trends, risks, and
            opportunities while supporting data-driven decision making in federal acquisitions.
            \(formattingInstructions)
            """
        } else if documentType == .otherTransactionAgreement {
            return """
            You are an expert federal contracting officer specializing in Other Transaction (OT) authorities.
            You have extensive experience with 10 U.S.C. § 2371b prototype OT agreements and understand the
            flexibility and innovation potential of OT authorities. You know how to structure OT agreements
            to encourage non-traditional contractor participation, leverage cost-sharing arrangements, and
            accelerate prototype development. Your OT agreements balance innovation with appropriate government
            oversight while maintaining compliance with statutory requirements. You excel at crafting milestone-based
            payment structures and intellectual property arrangements that benefit both government and industry partners.

            Based on the requirements context, determine the most appropriate OT variation:
            - Research OT: For basic/applied research with universities or labs
            - Prototype OT: For demonstration and testing of new capabilities
            - Production OT: Follow-on from successful prototypes
            - Consortium OT: Multiple performers working collaboratively
            - Traditional Contractor OT: Defense contractors with cost sharing
            - Non-Traditional OT: Commercial entities with simplified terms
            - Dual-Use OT: Both military and commercial applications
            - SBIR/STTR OT: Small business innovation and technology transfer
            \(formattingInstructions)
            """
        }
        return """
        You are an expert federal contracting officer with extensive experience in creating \(documentType.rawValue) documents.
        Your documents must be professional, compliant with FAR regulations, and suitable for government contracting purposes.
        \(formattingInstructions)
        Always structure your response as a complete, well-formatted document with appropriate sections and professional language.
        """
    }

    private static func getSpecificRequirements(for documentType: DocumentType) -> String {
        switch documentType {
        case .sow:
            """
            1. Clear scope of work description
            2. Detailed deliverables list
            3. Timeline and milestones
            4. Acceptance criteria
            5. Performance standards
            """

        case .soo:
            """
            1. High-level program objectives
            2. Purpose and mission requirements
            3. Key performance parameters
            4. Desired outcomes and end states
            5. Constraints and boundaries
            6. Flexibility for contractor innovation
            """

        case .pws:
            """
            1. Performance objectives
            2. Measurable performance standards
            3. Quality metrics
            4. Surveillance methods
            5. Incentive structure (if applicable)
            6. Service Level Agreements (SLA) - including:
               - System uptime requirements (e.g., 99.5% availability)
               - Scheduled maintenance windows
               - Maximum unplanned downtime allowances
               - Response time requirements
               - Throughput and concurrent user requirements
               - Remedies for SLA violations
               - Credit structures and escalation processes
               - Reporting frequency and requirements
            """

        case .qasp:
            """
            1. Quality standards framework
            2. Surveillance methods and frequency
            3. Performance metrics
            4. Corrective action procedures
            5. Reporting requirements
            """

        case .costEstimate:
            """
            1. Detailed cost breakdown by category
            2. Labor cost estimates with rates
            3. Material and equipment costs
            4. Overhead and profit calculations
            5. Basis of estimate documentation
            """

        case .marketResearch:
            """
            1. Industry analysis and market conditions
            2. Vendor capability assessment
            3. Price analysis and cost comparisons
            4. Small business participation opportunities
            5. Recommended acquisition strategy based on findings
            6. Sources sought synopsis results (if applicable)
            """

        case .acquisitionPlan:
            """
            1. Acquisition background and objectives
            2. Market research summary
            3. Acquisition strategy and contract type
            4. Source selection procedures
            5. Milestone schedule and deliverables
            6. Risk assessment and mitigation
            7. Cost/budget estimates
            8. Small business participation plan
            """

        case .evaluationPlan:
            """
            1. Evaluation factors and subfactors with relative weights
            2. Technical evaluation criteria and scoring methodology
            3. Past performance assessment approach
            4. Price evaluation methodology and reasonableness determination
            5. Source selection procedures and authority
            6. Evaluation team composition and responsibilities
            7. Timeline for evaluation phases
            8. Quality assurance and compliance procedures
            9. Competitive range determination process
            10. Best value trade-off methodology
            """

        case .fiscalLawReview:
            """
            1. Funding source identification and availability
            2. Fiscal year appropriation analysis
            3. Purpose statute compliance review
            4. Time statute compliance (bona fide need)
            5. Amount statute compliance
            6. Anti-Deficiency Act considerations
            7. Recommendations and legal opinion
            """

        case .opsecReview:
            """
            1. Critical information identification
            2. Threat assessment and vulnerabilities
            3. Risk analysis and impact assessment
            4. OPSEC measures and countermeasures
            5. Implementation plan and procedures
            6. Monitoring and effectiveness measures
            """

        case .industryRFI:
            """
            1. Project background and objectives
            2. Current challenges and capability gaps
            3. Specific information requested from industry
            4. Technical requirements overview
            5. Response format and submission instructions
            6. Key dates and points of contact
            7. Evaluation criteria for responses
            """

        case .sourcesSought:
            """
            1. Synopsis of requirement
            2. Capability requirements and specifications
            3. Small business set-aside considerations
            4. Minimum qualifications for sources
            5. Response format and required information
            6. Submission deadline and instructions
            7. Government point of contact
            8. Notice that this is NOT a solicitation
            """

        case .justificationApproval:
            """
            1. Contracting action description and value
            2. Authority being cited (FAR 6.302-X)
            3. Reason for other than full and open competition
            4. Market research conducted
            5. Determination that only one source available
            6. Actions to increase competition in future
            7. Contracting officer certification
            8. Legal and technical review
            """

        case .codes:
            """
            1. Detailed analysis of requirement scope
            2. Primary NAICS code determination with justification
            3. Applicable PSC code selection
            4. Small business size standard identification
            5. Market composition analysis
            6. Set-aside recommendations based on Rule of Two
            7. Qualified sources identification with contact information
            8. Compliance with socioeconomic goals
            """

        case .competitionAnalysis:
            """
            1. Comprehensive evaluation of all competition options
            2. Market research data integration and analysis
            3. Full and open competition viability assessment
            4. Small business set-aside analysis (all categories)
            5. Sole source justification evaluation
            6. Risk assessment for each competition approach
            7. Socioeconomic goal impact analysis
            8. Clear recommendation with supporting rationale
            9. Implementation timeline and next steps
            """

        case .procurementSourcing:
            """
            1. Search SAM.gov for active registrations matching NAICS/PSC codes
            2. Integrate findings from market research and codes reports
            3. Identify qualified vendors with complete contact information
            4. Verify business size and socioeconomic status
            5. Assess past performance and contract history
            6. Evaluate technical capabilities and relevant experience
            7. Analyze contract vehicle availability (GSA, GWACs, etc.)
            8. Provide detailed contact information for key personnel
            9. Rank vendors by qualification level and readiness
            10. Consider teaming arrangements and joint ventures
            11. Verify no exclusions or debarments
            12. Recommend engagement strategy for top vendors
            """

        case .rrd:
            """
            1. Begin with open-ended questions to understand the general requirement
            2. Progressively drill down into specific details through targeted questions
            3. Identify and probe for missing critical information
            4. Suggest related requirements the user may not have considered
            5. Clarify technical specifications and performance standards
            6. Determine budget constraints and timeline requirements
            7. Assess market conditions and potential competition strategies
            8. Identify risks and recommend mitigation approaches
            9. Transform user inputs into clear, measurable requirements
            10. Provide expert recommendations based on federal contracting best practices
            11. Create a comprehensive Statement of Requirements as the final output
            12. Recommend next steps and which AIKO documents to generate
            """

        case .requestForQuoteSimplified:
            """
            1. Brief description of what is needed
            2. Quantity required
            3. When needed (delivery date)
            4. Where to deliver
            5. How to submit quote (email/phone)
            6. Quote deadline
            7. Contact information
            Keep it to ONE PAGE maximum - this is for simple, straightforward purchases only.
            """

        case .requestForQuote:
            """
            1. Clear description of items or services required
            2. Quantity, specifications, and delivery requirements
            3. Pricing structure and format for quote submission
            4. Terms and conditions applicable to the quote
            5. Evaluation criteria for quote selection
            6. Submission deadline and instructions
            7. Point of contact information
            8. Required certifications and representations
            9. Delivery location and schedule
            10. Payment terms and invoicing requirements
            """

        case .requestForProposal:
            """
            1. Background and purpose of the procurement
            2. Detailed technical requirements and specifications
            3. Evaluation factors and their relative importance
            4. Proposal submission format and requirements
            5. Instructions to offerors (Section L)
            6. Evaluation criteria (Section M)
            7. Statement of work or performance requirements
            8. Contract terms and conditions
            9. Past performance requirements
            10. Technical proposal requirements
            11. Cost/price proposal requirements
            12. Key personnel and staffing requirements
            13. Schedule and milestone requirements
            14. Security and compliance requirements
            """

        case .contractScaffold:
            """
            1. Cover page with contract number and basic information
            2. Contract sections structure (A through M)
            3. Section A - Solicitation/Contract Form (SF-33 or equivalent)
            4. Section B - Supplies or Services and Prices/Costs
            5. Section C - Description/Specifications/Statement of Work
            6. Section D - Packaging and Marking
            7. Section E - Inspection and Acceptance
            8. Section F - Deliveries or Performance
            9. Section G - Contract Administration Data
            10. Section H - Special Contract Requirements
            11. Section I - Contract Clauses
            12. Section J - List of Attachments
            13. Required FAR clauses based on contract type and value
            14. Signature blocks and authorization
            """

        case .corAppointment:
            """
            1. COR name and contact information
            2. Contract number and contractor information
            3. Period of appointment
            4. Specific delegated authorities
            5. Limitations on COR authority
            6. Technical responsibilities
            7. Administrative responsibilities
            8. Reporting requirements and frequency
            9. File documentation requirements
            10. Training and certification requirements
            11. Potential conflicts of interest disclosure
            12. Acknowledgment of appointment section
            13. Contracting Officer signature block
            14. COR acceptance signature block
            """

        case .analytics:
            """
            1. Executive dashboard summary
            2. Key procurement metrics and KPIs
            3. Spend analysis by category and vendor
            4. Contract performance metrics
            5. Small business utilization statistics
            6. Competition metrics and sole source analysis
            7. Contract cycle time analysis
            8. Cost savings and cost avoidance
            9. Vendor performance scorecards
            10. Risk indicators and mitigation status
            11. Compliance monitoring results
            12. Trend analysis and forecasting
            13. Recommendations for improvement
            14. Data sources and methodology
            """

        case .otherTransactionAgreement:
            """
            Core Requirements (All OT Types):
            1. OT Agreement title and number
            2. Statutory authority (10 U.S.C. § 2371b)
            3. Parties to the agreement (Government and Performer)
            4. Purpose and prototype project description
            5. Technical objectives and success criteria
            6. Milestone schedule with deliverables
            7. Payment structure (milestone-based or expenditure-based)
            8. Cost sharing arrangements and percentages
            9. Intellectual property and data rights provisions
            10. Government oversight and access rights
            11. Dispute resolution procedures
            12. Termination provisions
            13. Follow-on production considerations
            14. Non-traditional contractor participation
            15. Reporting requirements and formats
            16. Key personnel and points of contact
            17. Special terms and conditions
            18. Signature blocks for agreements officer and performer

            For Research OT Agreements, also include:
            - Basic/applied research objectives and methodology
            - Publication rights and academic freedom provisions
            - Government purpose rights timeline (typically 5 years)
            - Collaboration terms with universities/labs
            - Research data management plan
            - Scientific review board requirements

            For Production OT Agreements, also include:
            - Quantity commitments and unit pricing
            - Quality assurance and testing provisions
            - Delivery schedules and logistics requirements
            - Warranty and sustainment terms
            - Configuration management procedures
            - Production readiness reviews

            For Consortium OT Agreements, also include:
            - Consortium management structure and governance
            - Member roles, responsibilities, and work share
            - IP allocation and background IP provisions
            - New member admission process and criteria
            - Inter-member collaboration agreements
            - Common fund management

            For Non-Traditional Contractor OT, also include:
            - Commercial item definitions and practices
            - Reduced oversight and reporting requirements
            - Commercial pricing and payment terms
            - Flexible IP arrangements favoring contractor
            - Streamlined dispute resolution
            - Commercial warranty terms

            For Dual-Use OT Agreements, also include:
            - Commercial and government application descriptions
            - Market rights and exclusivity provisions
            - Dual-use development milestones
            - Commercial sales reporting requirements
            - Government license rights for commercial versions
            - Export control considerations

            For SBIR/STTR OT Agreements, also include:
            - SBIR/STTR phase identification (I, II, or III)
            - Commercialization plan requirements
            - Small business protections and data rights
            - Mentor-protege arrangements (if applicable)
            - Transition to Phase III considerations
            - Success fee structures
            """

        case .farUpdates:
            """
            1. Summary of recent FAR/DFAR changes
            2. Effective dates for each change
            3. Impact analysis on current contracts
            4. Action items for compliance
            5. References to Federal Register citations
            """
        }
    }

    static func createDFPrompt(
        for dfDocumentType: DFDocumentType,
        requirements: String,
        template: String,
        quickReference: String,
        profile _: UserProfile?
    ) -> String {
        """
        You are creating a Determination and Findings (D&F) document for: \(dfDocumentType.rawValue)

        REQUIREMENTS PROVIDED BY USER:
        \(requirements)

        QUICK REFERENCE GUIDE:
        \(quickReference)

        TEMPLATE TO FOLLOW:
        \(template)

        INSTRUCTIONS:
        1. Fill in the template with specific information based on the requirements
        2. Replace all placeholder text (in {{BRACKETS}}) with appropriate content
        3. Ensure all checkboxes are properly marked based on the requirements
        4. Follow the guidance from the quick reference guide
        5. Ensure compliance with \(dfDocumentType.farReference)
        6. Maintain professional government contracting language throughout

        Generate a complete, ready-to-use D&F document based on the template and requirements.
        """
    }

    static func getDFSystemPrompt(for dfDocumentType: DFDocumentType) -> String {
        let formattingInstructions = """

        FORMATTING INSTRUCTIONS:
        - Use markdown-style formatting for better readability
        - Use # for main headings, ## for subheadings
        - Use **bold** for emphasis on important terms
        - Use bullet points (- ) for lists
        - Use numbered lists (1. ) for sequential steps
        - Separate sections with blank lines
        - Make the document professional and well-structured
        """

        return """
        You are an expert federal contracting officer specializing in Determination and Findings (D&F) documents.
        You have extensive experience with \(dfDocumentType.rawValue) documents and \(dfDocumentType.farReference) requirements.
        Your documents must be legally sound, compliant with all federal regulations, and suitable for official government use.
        Always provide complete, well-reasoned justifications and ensure all required elements are addressed.
        \(formattingInstructions)
        """
    }

    static func createTemplateBasedPrompt(
        for documentType: DocumentType,
        requirements: String,
        template: String,
        profile _: UserProfile?
    ) -> String {
        """
        Create a \(documentType.rawValue) document based on the following requirements and template.

        PROJECT REQUIREMENTS:
        \(requirements)

        TEMPLATE TO FOLLOW:
        \(template)

        INSTRUCTIONS:
        1. Fill in the template with specific information based on the requirements
        2. Replace all placeholder text (in {{BRACKETS}}) with appropriate content
        3. Ensure all sections are properly completed based on the requirements
        4. Maintain professional government contracting language throughout
        5. Follow FAR compliance requirements
        6. Make sure the document is complete and ready for official use

        Generate a complete, ready-to-use \(documentType.shortName) document based on the template and requirements.
        Do not include any explanatory text before or after the document.
        """
    }
}

public enum AIDocumentGeneratorError: Error {
    case noContent
    case invalidResponse
    case rateLimitExceeded
    case insufficientCredits
    case noProvider
}
