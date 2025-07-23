import Foundation

// MARK: - Dynamic Question Generator

public final class DynamicQuestionGenerator: @unchecked Sendable {
    public init() {}

    public func generateQuestions(
        for type: APEAcquisitionType,
        with context: ExtractedContext?,
        historicalData: [HistoricalAcquisition]
    ) async -> [DynamicQuestion] {
        var questions: [DynamicQuestion] = []

        // Start with critical questions based on acquisition type
        questions.append(contentsOf: getCriticalQuestions(for: type))

        // Add questions based on what we DON'T have from context
        if let context {
            questions.append(contentsOf: getGapFillingQuestions(context: context, type: type))
        } else {
            // No context, need all standard questions
            questions.append(contentsOf: getStandardQuestions(for: type))
        }

        // Adjust questions based on historical patterns
        questions = adjustQuestionsFromHistory(questions, history: historicalData)

        // Smart ordering - put related questions together
        questions = smartOrderQuestions(questions)

        return questions
    }

    // MARK: - Private Methods

    private func getCriticalQuestions(for type: APEAcquisitionType) -> [DynamicQuestion] {
        var questions: [DynamicQuestion] = []

        // Project title is always critical
        questions.append(DynamicQuestion(
            field: .projectTitle,
            prompt: "What would you like to call this acquisition? (e.g., 'Office Supplies Q1 2025')",
            responseType: .text,
            validation: ValidationRule(
                type: .minLength(3),
                errorMessage: "Please provide a meaningful title"
            ),
            priority: .critical
        ))

        // Type-specific critical questions
        switch type {
        case .supplies:
            questions.append(DynamicQuestion(
                field: .description,
                prompt: "What supplies are you looking to acquire? Please describe the items.",
                responseType: .text,
                validation: ValidationRule(
                    type: .minLength(10),
                    errorMessage: "Please provide more detail about the supplies"
                ),
                priority: .critical
            ))

        case .services:
            questions.append(DynamicQuestion(
                field: .description,
                prompt: "What services do you need? Please describe the scope of work.",
                responseType: .text,
                validation: ValidationRule(
                    type: .minLength(20),
                    errorMessage: "Please provide a detailed description of services needed"
                ),
                priority: .critical
            ))

        case .construction:
            questions.append(contentsOf: [
                DynamicQuestion(
                    field: .description,
                    prompt: "Describe the construction project and its requirements.",
                    responseType: .text,
                    validation: ValidationRule(
                        type: .minLength(50),
                        errorMessage: "Construction projects require detailed descriptions"
                    ),
                    priority: .critical
                ),
                DynamicQuestion(
                    field: .performanceLocation,
                    prompt: "Where will the construction take place? (Full address required)",
                    responseType: .text,
                    validation: ValidationRule(type: .required, errorMessage: "Location is required for construction"),
                    priority: .critical
                ),
            ])

        case .researchAndDevelopment:
            questions.append(DynamicQuestion(
                field: .description,
                prompt: "Describe the R&D objectives and expected deliverables.",
                responseType: .text,
                validation: ValidationRule(
                    type: .minLength(30),
                    errorMessage: "Please provide detailed R&D objectives"
                ),
                priority: .critical
            ))
        }

        return questions
    }

    private func getGapFillingQuestions(context: ExtractedContext, type: APEAcquisitionType) -> [DynamicQuestion] {
        var questions: [DynamicQuestion] = []
        let confidence = context.confidence

        // Check estimated value
        if confidence[.estimatedValue] ?? 0 < 0.8 {
            questions.append(DynamicQuestion(
                field: .estimatedValue,
                prompt: context.pricing?.totalPrice != nil ?
                    "We found a price of $\(context.pricing?.totalPrice ?? 0). Is this the total acquisition value?" :
                    "What is the estimated total value of this acquisition?",
                responseType: .numeric,
                validation: ValidationRule(
                    type: .range(min: 0, max: 999_999_999),
                    errorMessage: "Please enter a valid amount"
                ),
                priority: .high
            ))
        }

        // Check required date
        if confidence[.requiredDate] ?? 0 < 0.8 {
            questions.append(DynamicQuestion(
                field: .requiredDate,
                prompt: context.dates?.deliveryDate != nil ?
                    "We found a delivery date of \(formatDate(context.dates?.deliveryDate ?? Date())). Is this correct?" :
                    "When do you need this delivered or completed by?",
                responseType: .date,
                validation: ValidationRule(
                    type: .futureDate,
                    errorMessage: "Please select a future date"
                ),
                priority: .high
            ))
        }

        // Check vendor info
        if context.vendorInfo == nil || confidence[.vendorName] ?? 0 < 0.8 {
            questions.append(DynamicQuestion(
                field: .vendorName,
                prompt: "Which vendor/supplier will you be working with?",
                responseType: .text,
                priority: .medium
            ))
        }

        // Technical specs if not enough extracted
        if context.technicalDetails.count < 3, type == .supplies || type == .services {
            questions.append(DynamicQuestion(
                field: .technicalSpecs,
                prompt: "Are there any specific technical requirements or specifications? (Optional)",
                responseType: .text,
                priority: .low
            ))
        }

        // Special conditions
        if context.specialTerms.isEmpty {
            questions.append(DynamicQuestion(
                field: .specialConditions,
                prompt: "Any special terms, conditions, or notes for this acquisition? (Optional)",
                responseType: .text,
                priority: .low
            ))
        }

        return questions
    }

    private func getStandardQuestions(for type: APEAcquisitionType) -> [DynamicQuestion] {
        var questions: [DynamicQuestion] = []

        // Common questions for all types
        questions.append(contentsOf: [
            DynamicQuestion(
                field: .estimatedValue,
                prompt: "What is the estimated total value of this acquisition?",
                responseType: .numeric,
                validation: ValidationRule(
                    type: .range(min: 0, max: 999_999_999),
                    errorMessage: "Please enter a valid amount"
                ),
                priority: .high
            ),
            DynamicQuestion(
                field: .requiredDate,
                prompt: "When do you need this delivered or completed by?",
                responseType: .date,
                validation: ValidationRule(
                    type: .futureDate,
                    errorMessage: "Please select a future date"
                ),
                priority: .high
            ),
            DynamicQuestion(
                field: .vendorName,
                prompt: "Do you have a preferred vendor? (Leave blank if not)",
                responseType: .text,
                priority: .medium
            ),
        ])

        // Type-specific additional questions
        switch type {
        case .services, .construction:
            questions.append(DynamicQuestion(
                field: .performanceLocation,
                prompt: "Where will the work be performed?",
                responseType: .text,
                priority: .medium
            ))

        case .supplies:
            questions.append(DynamicQuestion(
                field: .technicalSpecs,
                prompt: "Any specific brands, models, or specifications?",
                responseType: .text,
                priority: .low
            ))

        case .researchAndDevelopment:
            questions.append(DynamicQuestion(
                field: .contractType,
                prompt: "What type of contract is preferred?",
                responseType: .selection,
                options: ["Fixed Price", "Cost Plus", "Time & Materials", "Other"],
                priority: .medium
            ))
        }

        // Always ask about special conditions last
        questions.append(DynamicQuestion(
            field: .specialConditions,
            prompt: "Any special requirements or conditions we should know about?",
            responseType: .text,
            priority: .low
        ))

        return questions
    }

    private func adjustQuestionsFromHistory(_ questions: [DynamicQuestion], history: [HistoricalAcquisition]) -> [DynamicQuestion] {
        guard !history.isEmpty else { return questions }

        var adjustedQuestions = questions

        // Analyze patterns in historical data
        let recentHistory = history.suffix(10) // Last 10 acquisitions

        // Check if user always uses same vendor
        let vendorNames = recentHistory.compactMap { $0.vendor?.name }
        let uniqueVendors = Set(vendorNames)

        if uniqueVendors.count == 1, let commonVendor = uniqueVendors.first {
            // Adjust vendor question to suggest the common vendor
            if let index = adjustedQuestions.firstIndex(where: { $0.field == .vendorName }) {
                adjustedQuestions[index] = DynamicQuestion(
                    field: .vendorName,
                    prompt: "Will you be using \(commonVendor) again for this acquisition?",
                    responseType: .selection,
                    options: ["Yes", "No, different vendor"],
                    priority: .medium
                )
            }
        }

        // Check if certain fields are never used
        let hasSpecialConditions = recentHistory.contains { !$0.data.specialConditions.isEmpty }
        if !hasSpecialConditions {
            // Lower priority of special conditions question
            if let index = adjustedQuestions.firstIndex(where: { $0.field == .specialConditions }) {
                adjustedQuestions[index] = DynamicQuestion(
                    field: adjustedQuestions[index].field,
                    prompt: adjustedQuestions[index].prompt,
                    responseType: adjustedQuestions[index].responseType,
                    priority: .low
                )
            }
        }

        return adjustedQuestions
    }

    private func smartOrderQuestions(_ questions: [DynamicQuestion]) -> [DynamicQuestion] {
        // Group questions by logical flow
        let criticalQuestions = questions.filter { $0.priority == .critical }
        let highQuestions = questions.filter { $0.priority == .high }
        let mediumQuestions = questions.filter { $0.priority == .medium }
        let lowQuestions = questions.filter { $0.priority == .low }

        var orderedQuestions: [DynamicQuestion] = []

        // Start with title and description
        if let title = criticalQuestions.first(where: { $0.field == .projectTitle }) {
            orderedQuestions.append(title)
        }
        if let desc = criticalQuestions.first(where: { $0.field == .description }) {
            orderedQuestions.append(desc)
        }

        // Then other critical questions
        orderedQuestions.append(contentsOf: criticalQuestions.filter {
            $0.field != .projectTitle && $0.field != .description
        })

        // Value and date together
        if let value = highQuestions.first(where: { $0.field == .estimatedValue }) {
            orderedQuestions.append(value)
        }
        if let date = highQuestions.first(where: { $0.field == .requiredDate }) {
            orderedQuestions.append(date)
        }

        // Other high priority
        orderedQuestions.append(contentsOf: highQuestions.filter {
            $0.field != .estimatedValue && $0.field != .requiredDate
        })

        // Medium priority
        orderedQuestions.append(contentsOf: mediumQuestions)

        // Low priority last
        orderedQuestions.append(contentsOf: lowQuestions)

        return orderedQuestions
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
