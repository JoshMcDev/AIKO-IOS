import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - GlobalScanFeature State Extensions

extension GlobalScanFeature.State {
    // MARK: - Computed Properties
    
    public var effectivePosition: FloatingPosition {
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

    public var shouldShowButton: Bool {
        isVisible && !isScannerActive
    }

    public var buttonOpacity: Double {
        isDragging ? 0.8 : opacity
    }
}