import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - GlobalScanFeature State Extensions

public extension GlobalScanFeature.State {
    // MARK: - Computed Properties

    var effectivePosition: FloatingPosition {
        // Apply drag offset to position calculation
        guard isDragging && dragOffset != .zero else { return position }

        // Calculate adjusted position based on drag offset
        let threshold: CGFloat = 50.0
        let adjustedPosition = position

        // If drag is significant, potentially adjust position
        if abs(dragOffset.width) > threshold || abs(dragOffset.height) > threshold {
            // For now, maintain current position during drag
            // Full implementation would calculate screen-relative positioning
            return position
        }

        return adjustedPosition
    }

    var shouldShowButton: Bool {
        isVisible && !isScannerActive
    }

    var buttonOpacity: Double {
        isDragging ? 0.8 : opacity
    }
}
