import Foundation

public struct WorkflowPrediction {
    public let id: UUID
    public let nextSteps: [String]
    public let confidence: Double
    public let reasoning: String
    public let alternativeSteps: [String]
    public let estimatedDuration: TimeInterval?
    public let requiredResources: [String]
    public let riskFactors: [String]
}

public struct PredictionPrivacySettings {
    public let enablePredictions: Bool
    public let dataRetentionDays: Int
    public let allowAnalytics: Bool
}

public struct WorkflowPredictionFeatureFlags {
    public let enablePredictions: Bool
    public let enableAutoExecution: Bool
    public let maxPredictions: Int
}

public struct WorkflowPredictionFeedback {
    public let predictionId: UUID
    public let userAction: PredictionFeedbackAction
    public let actualNextStep: String
    public let confidence: Double
    public let timestamp: Date
}

public enum PredictionFeedbackAction {
    case accepted
    case rejected
    case modified
    case ignored
}

public struct PatternWorkflowState {
    public let currentStep: String
    public let completedSteps: [String]
    public let documentType: String
    public let metadata: [String: Any]
}

public struct PredictionOutcome {
    public let prediction: String
    public let actual: String
    public let correct: Bool
}

public struct WorkflowPattern {
    public let sequence: [String]
    public let context: [String: Any]
    public let frequency: Int
    public let successRate: Double
}

public enum ExpertiseLevel {
    case novice, low, intermediate, high, advanced, expert
}

public enum WorkflowStyle {
    case systematic, adaptive, efficient, thorough
}

public struct UserExpertiseProfile {
    public let acquisitionExperience: ExpertiseLevel
    public let domainKnowledge: [String: ExpertiseLevel]
    public let successHistory: Double
    public let averageTaskTime: Double
    public let preferredWorkflowStyle: WorkflowStyle
}

public struct WorkflowPredictionRequest {
    public let currentStep: String
    public let documentType: String
    public let domain: String
    public let estimatedComplexity: ExpertiseLevel
    public let requiredExpertise: ExpertiseLevel
}

public struct TemporalFactor {
    public let timestamp: Date
    public let relevance: Double
    public let context: String
}

public struct ConfidenceComponents {
    public let historicalAccuracy: Double
    public let patternStrength: Double
    public let contextSimilarity: Double
    public let userProfileAlignment: Double
    public let temporalRelevance: Double
}

public struct CalibrationDataPoint {
    public let predictedConfidence: Double
    public let actualOutcome: Bool
}

public struct WeeklyCalibrationData {
    public let week: Date
    public let calibrationPoints: [CalibrationDataPoint]
}

public struct PredictionData {
    public let confidence: Double
    public let features: [Double]
}

public struct OutcomeData {
    public let success: Bool
    public let actualValue: Double
}

public struct CalibrationPlotPoint {
    public let binCenter: Double
    public let observedFrequency: Double
    public let sampleSize: Int
}

public struct ReliabilityDataPoint {
    public let confidenceBin: ClosedRange<Double>
    public let accuracy: Double
    public let sampleSize: Int
}

public struct CalibrationPlot {
    public let points: [CalibrationPlotPoint]
    public let rSquared: Double
}

public struct ReliabilityDiagram {
    public let points: [ReliabilityDataPoint]
    public let overallAccuracy: Double
}

public struct StatePrediction {
    public let nextState: PredictionWorkflowState
    public let probability: Double
    public let confidence: Double
    public let reasoning: String
    public let estimatedDuration: TimeInterval?
}

public struct PredictionWorkflowState {
    public let phase: String
    public let currentStep: String
    public let documentType: String
    public let metadata: [String: Any]
}