import Foundation

// MARK: - Media Metadata Types

/// Represents a metadata field that can be extracted from media
public struct MetadataField: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let type: MetadataFieldType
    public let value: String
    public let confidence: Double
    public let source: MetadataSource

    public init(
        id: UUID = UUID(),
        name: String,
        type: MetadataFieldType,
        value: String,
        confidence: Double = 1.0,
        source: MetadataSource
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.value = value
        self.confidence = confidence
        self.source = source
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: MetadataField, rhs: MetadataField) -> Bool {
        lhs.id == rhs.id
    }
}

/// Types of metadata fields
public enum MetadataFieldType: String, Sendable, CaseIterable {
    case text
    case number
    case date
    case location
    case dimension
    case duration
    case boolean
    case url
    case identifier
    case custom

    public var displayName: String {
        switch self {
        case .text: "Text"
        case .number: "Number"
        case .date: "Date"
        case .location: "Location"
        case .dimension: "Dimension"
        case .duration: "Duration"
        case .boolean: "Boolean"
        case .url: "URL"
        case .identifier: "Identifier"
        case .custom: "Custom"
        }
    }
}

/// Source of metadata extraction
public enum MetadataSource: String, Sendable, CaseIterable {
    case exif
    case ocr
    case faceDetection
    case objectDetection
    case manual
    case ai
    case system

    public var displayName: String {
        switch self {
        case .exif: "EXIF Data"
        case .ocr: "OCR"
        case .faceDetection: "Face Detection"
        case .objectDetection: "Object Detection"
        case .manual: "Manual"
        case .ai: "AI Analysis"
        case .system: "System"
        }
    }
}

/// Text extracted from media using OCR
public struct ExtractedText: Sendable, Identifiable {
    public let id: UUID
    public let text: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let language: String?
    public let fontSize: Double?
    public let font: String?

    public init(
        id: UUID = UUID(),
        text: String,
        confidence: Double,
        boundingBox: CGRect,
        language: String? = nil,
        fontSize: Double? = nil,
        font: String? = nil
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.language = language
        self.fontSize = fontSize
        self.font = font
    }
}

/// Face detected in media
public struct DetectedFace: Sendable, Identifiable {
    public let id: UUID
    public let boundingBox: CGRect
    public let confidence: Double
    public let landmarks: [FaceLandmark]
    public let emotions: [EmotionAnalysis]
    public let ageEstimate: Int?
    public let genderEstimate: String?

    public init(
        id: UUID = UUID(),
        boundingBox: CGRect,
        confidence: Double,
        landmarks: [FaceLandmark] = [],
        emotions: [EmotionAnalysis] = [],
        ageEstimate: Int? = nil,
        genderEstimate: String? = nil
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.landmarks = landmarks
        self.emotions = emotions
        self.ageEstimate = ageEstimate
        self.genderEstimate = genderEstimate
    }
}

/// Face landmark point
public struct FaceLandmark: Sendable {
    public let type: LandmarkType
    public let position: CGPoint
    public let confidence: Double

    public init(type: LandmarkType, position: CGPoint, confidence: Double) {
        self.type = type
        self.position = position
        self.confidence = confidence
    }
}

/// Types of face landmarks
public enum LandmarkType: String, Sendable, CaseIterable {
    case leftEye
    case rightEye
    case nose
    case mouth
    case leftEyebrow
    case rightEyebrow
    case chin
    case forehead

    public var displayName: String {
        switch self {
        case .leftEye: "Left Eye"
        case .rightEye: "Right Eye"
        case .nose: "Nose"
        case .mouth: "Mouth"
        case .leftEyebrow: "Left Eyebrow"
        case .rightEyebrow: "Right Eyebrow"
        case .chin: "Chin"
        case .forehead: "Forehead"
        }
    }
}

/// Emotion analysis result
public struct EmotionAnalysis: Sendable {
    public let emotion: Emotion
    public let confidence: Double

    public init(emotion: Emotion, confidence: Double) {
        self.emotion = emotion
        self.confidence = confidence
    }
}

/// Detected emotions
public enum Emotion: String, Sendable, CaseIterable {
    case happy
    case sad
    case angry
    case surprised
    case fearful
    case disgusted
    case neutral

    public var displayName: String {
        switch self {
        case .happy: "Happy"
        case .sad: "Sad"
        case .angry: "Angry"
        case .surprised: "Surprised"
        case .fearful: "Fearful"
        case .disgusted: "Disgusted"
        case .neutral: "Neutral"
        }
    }
}

/// Comprehensive image analysis result
public struct ImageAnalysis: Sendable {
    public let extractedText: [ExtractedText]
    public let detectedFaces: [DetectedFace]
    public let detectedObjects: [DetectedObject]
    public let sceneClassification: [SceneLabel]
    public let dominantColors: [ColorInfo]
    public let qualityMetrics: ImageQualityMetrics

    public init(
        extractedText: [ExtractedText] = [],
        detectedFaces: [DetectedFace] = [],
        detectedObjects: [DetectedObject] = [],
        sceneClassification: [SceneLabel] = [],
        dominantColors: [ColorInfo] = [],
        qualityMetrics: ImageQualityMetrics = ImageQualityMetrics()
    ) {
        self.extractedText = extractedText
        self.detectedFaces = detectedFaces
        self.detectedObjects = detectedObjects
        self.sceneClassification = sceneClassification
        self.dominantColors = dominantColors
        self.qualityMetrics = qualityMetrics
    }
}

/// Detected object in image
public struct DetectedObject: Sendable, Identifiable {
    public let id: UUID
    public let label: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let category: ObjectCategory

    public init(
        id: UUID = UUID(),
        label: String,
        confidence: Double,
        boundingBox: CGRect,
        category: ObjectCategory
    ) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.category = category
    }
}

/// Categories of detected objects
public enum ObjectCategory: String, Sendable, CaseIterable {
    case person
    case animal
    case vehicle
    case building
    case food
    case plant
    case technology
    case furniture
    case clothing
    case other

    public var displayName: String {
        switch self {
        case .person: "Person"
        case .animal: "Animal"
        case .vehicle: "Vehicle"
        case .building: "Building"
        case .food: "Food"
        case .plant: "Plant"
        case .technology: "Technology"
        case .furniture: "Furniture"
        case .clothing: "Clothing"
        case .other: "Other"
        }
    }
}

/// Scene classification label
public struct SceneLabel: Sendable {
    public let label: String
    public let confidence: Double

    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}

/// Color information
public struct ColorInfo: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    public let percentage: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0, percentage: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.percentage = percentage
    }
}

/// Image quality metrics
public struct ImageQualityMetrics: Sendable {
    public let sharpness: Double
    public let brightness: Double
    public let contrast: Double
    public let saturation: Double
    public let noiseLevel: Double
    public let overallQuality: Double

    public init(
        sharpness: Double = 0.0,
        brightness: Double = 0.0,
        contrast: Double = 0.0,
        saturation: Double = 0.0,
        noiseLevel: Double = 0.0,
        overallQuality: Double = 0.0
    ) {
        self.sharpness = sharpness
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.noiseLevel = noiseLevel
        self.overallQuality = overallQuality
    }
}
