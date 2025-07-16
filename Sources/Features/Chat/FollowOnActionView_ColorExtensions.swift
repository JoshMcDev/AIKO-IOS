import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Platform-specific Colors for FollowOnActionView

extension View {
    var backgroundGroupedColor: Color {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(.controlBackgroundColor)
        #endif
    }
    
    var backgroundGroupedSecondaryColor: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemGroupedBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }
    
    var backgroundGroupedTertiaryColor: Color {
        #if os(iOS)
        Color(UIColor.tertiarySystemGroupedBackground)
        #else
        Color(.controlBackgroundColor).opacity(0.5)
        #endif
    }
}