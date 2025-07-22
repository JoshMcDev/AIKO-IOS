import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - Supporting Types for GlobalScanFeature

public enum FloatingPosition: String, CaseIterable, Equatable, Sendable {
    case topLeading = "top-leading"
    case topTrailing = "top-trailing"
    case bottomLeading = "bottom-leading"
    case bottomTrailing = "bottom-trailing"
}

// Note: ScannedDocument already exists in DocumentScannerClient.swift
public typealias GlobalScannedDocument = AppCore.ScannedDocument

@CasePathable
public enum ButtonAnimation: Equatable, Sendable {
    case pulse(duration: Int = 300)
    case bounce(duration: Int = 200)
    case shake(duration: Int = 400)
    case fadeIn(duration: Int = 250)
    case fadeOut(duration: Int = 250)

    public var duration: Int {
        switch self {
        case let .pulse(duration): duration
        case let .bounce(duration): duration
        case let .shake(duration): duration
        case let .fadeIn(duration): duration
        case let .fadeOut(duration): duration
        }
    }
}

public enum GlobalScanError: LocalizedError, Equatable, Sendable {
    case cameraPermissionDenied
    case scannerAlreadyActive
    case scannerUnavailable
    case configurationError(String)
    case scannerError(String)

    public var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            "Camera permission is required for document scanning"
        case .scannerAlreadyActive:
            "Scanner is already active"
        case .scannerUnavailable:
            "Document scanner is not available on this device"
        case let .configurationError(message):
            "Configuration error: \(message)"
        case let .scannerError(message):
            "Scanner error: \(message)"
        }
    }
}

public struct GlobalScanConfiguration: Equatable, Sendable {
    public let position: FloatingPosition
    public let isVisible: Bool
    public let scannerMode: ScannerMode
    public let enableHapticFeedback: Bool
    public let enableAnalytics: Bool

    public init(
        position: FloatingPosition = .bottomTrailing,
        isVisible: Bool = true,
        scannerMode: ScannerMode = .quickScan,
        enableHapticFeedback: Bool = true,
        enableAnalytics: Bool = true
    ) {
        self.position = position
        self.isVisible = isVisible
        self.scannerMode = scannerMode
        self.enableHapticFeedback = enableHapticFeedback
        self.enableAnalytics = enableAnalytics
    }

    public static let `default` = GlobalScanConfiguration()
}
