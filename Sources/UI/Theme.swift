import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum Theme {
    // MARK: - Colors
    public enum Colors {
        #if canImport(UIKit)
        public static let aikoBackground = Color.black
        public static let aikoCard = Color(UIColor.systemGray6)
        public static let aikoSecondary = Color(UIColor.systemGray6)
        public static let aikoTertiary = Color(UIColor.systemGray5)
        #elseif canImport(AppKit)
        public static let aikoBackground = Color(NSColor.controlBackgroundColor)
        public static let aikoCard = Color(NSColor.controlColor)
        public static let aikoSecondary = Color(NSColor.controlBackgroundColor)
        public static let aikoTertiary = Color(NSColor.separatorColor)
        #else
        public static let aikoBackground = Color.primary
        public static let aikoCard = Color.secondary
        public static let aikoSecondary = Color.gray
        public static let aikoTertiary = Color.gray
        #endif
        
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
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    public enum CornerRadius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
    }
}

// MARK: - Button Styles
public struct AIKOButtonStyle: ButtonStyle {
    let variant: Variant
    let size: Size
    
    public enum Variant {
        case primary
        case secondary
        case ghost
        case destructive
    }
    
    public enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }
    }
    
    public init(variant: Variant = .primary, size: Size = .medium) {
        self.variant = variant
        self.size = size
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(size.padding)
            .frame(height: size.height)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(Theme.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return Theme.Colors.aikoAccent
        case .ghost: return .primary
        case .destructive: return .white
        }
    }
    
    private var backgroundColor: some View {
        Group {
            switch variant {
            case .primary:
                Theme.Colors.aikoPrimary
            case .secondary:
                Theme.Colors.aikoSecondary
            case .ghost:
                Color.clear
            case .destructive:
                Theme.Colors.aikoError
            }
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .primary, .destructive: return .clear
        case .secondary: return Theme.Colors.aikoAccent
        case .ghost: return .gray.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        switch variant {
        case .primary, .destructive: return 0
        case .secondary, .ghost: return 1
        }
    }
}

// MARK: - Card Modifier
public struct AIKOCardModifier: ViewModifier {
    let padding: EdgeInsets
    let shadow: Bool
    
    public init(padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), shadow: Bool = true) {
        self.padding = padding
        self.shadow = shadow
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.Colors.aikoCard)
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(
                color: shadow ? .black.opacity(0.1) : .clear,
                radius: shadow ? 8 : 0,
                x: 0,
                y: shadow ? 2 : 0
            )
    }
}

// MARK: - Loading View
public struct AIKOLoadingView: View {
    let message: String
    
    public init(message: String = "Loading...") {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.aikoAccent))
                .scaleEffect(1.5)
            
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.aikoBackground)
    }
}

// MARK: - Navigation Bar Hidden Modifier
public struct NavigationBarHiddenModifier: ViewModifier {
    public func body(content: Content) -> some View {
        #if os(iOS)
        content.navigationBarHidden(true)
        #else
        content
        #endif
    }
}

// MARK: - Dark Navigation Bar Modifier
public struct DarkNavigationBarModifier: ViewModifier {
    public func body(content: Content) -> some View {
        #if os(iOS)
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .black
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
        #else
        content
        #endif
    }
}

// MARK: - View Extensions
extension View {
    public func aikoCard(padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), shadow: Bool = true) -> some View {
        modifier(AIKOCardModifier(padding: padding, shadow: shadow))
    }
    
    public func aikoButton(variant: AIKOButtonStyle.Variant = .primary, size: AIKOButtonStyle.Size = .medium) -> some View {
        buttonStyle(AIKOButtonStyle(variant: variant, size: size))
    }
    
    @ViewBuilder
    public func aikoSheet() -> some View {
        #if os(iOS)
        if #available(iOS 16.4, *) {
            self
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark)
                .presentationBackground(Color.black)
                .modifier(DarkNavigationBarModifier())
        } else {
            self
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark)
                .modifier(DarkNavigationBarModifier())
        }
        #else
        self
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
            .modifier(DarkNavigationBarModifier())
        #endif
    }
}