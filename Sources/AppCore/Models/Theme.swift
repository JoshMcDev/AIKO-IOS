import SwiftUI

/// Shared theme constants for AIKO application
public enum Theme {
    // MARK: - Colors

    public enum Colors {
        public static let aikoBackground = Color.black
        public static let aikoCard = Color.black.opacity(0.8)
        public static let aikoSecondary = Color(white: 0.1)
        public static let aikoTertiary = Color(white: 0.15)
        public static let aikoPrimary = Color.blue
        public static let aikoPrimaryGradientStart = Color.blue
        public static let aikoPrimaryGradientEnd = Color.purple
        public static let aikoSuccess = Color.green
        public static let aikoWarning = Color.yellow
        public static let aikoError = Color.red
        public static let aikoAccent = Color.purple
    }

    // MARK: - Typography

    public enum Typography {
        public static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        public static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        public static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        public static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        public static let body = Font.system(size: 17, weight: .regular, design: .default)
        public static let callout = Font.system(size: 16, weight: .regular, design: .default)
        public static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        public static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        public static let caption = Font.system(size: 12, weight: .regular, design: .default)
        public static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let extraSmall: CGFloat = 4
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let extraLarge: CGFloat = 32
        public static let xxl: CGFloat = 40
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let extraLarge: CGFloat = 24
        
        // Backward compatibility aliases
        public static let sm: CGFloat = small
        public static let md: CGFloat = medium
        public static let lg: CGFloat = large
        public static let xl: CGFloat = extraLarge
    }
}
