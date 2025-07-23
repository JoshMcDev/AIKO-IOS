import ComposableArchitecture
import SwiftUI

/// Shared MenuView that delegates to platform-specific implementations
public struct MenuView: View {
    public let store: StoreOf<AppFeature>
    @Binding public var isShowing: Bool
    @Binding public var selectedMenuItem: AppFeature.MenuItem?

    public init(
        store: StoreOf<AppFeature>,
        isShowing: Binding<Bool>,
        selectedMenuItem: Binding<AppFeature.MenuItem?>
    ) {
        self.store = store
        _isShowing = isShowing
        _selectedMenuItem = selectedMenuItem
    }

    public var body: some View {
        #if os(iOS)
            iOSMenuView(
                store: store,
                isShowing: $isShowing,
                selectedMenuItem: $selectedMenuItem
            )
        #elseif os(macOS)
            MacOSMenuView(
                store: store,
                isShowing: $isShowing,
                selectedMenuItem: $selectedMenuItem
            )
        #endif
    }
}

/// Shared menu item row component
public struct MenuItemRow: View {
    public let item: AppFeature.MenuItem
    public let isSelected: Bool
    public let action: () -> Void

    public init(
        item: AppFeature.MenuItem,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.action = action
    }

    @ViewBuilder
    var rowContent: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.aikoPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)

                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, Theme.Spacing.small)
        .padding(.horizontal, Theme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }

    public var body: some View {
        Button(action: action) {
            rowContent
        }
        .buttonStyle(.plain)
    }
}
