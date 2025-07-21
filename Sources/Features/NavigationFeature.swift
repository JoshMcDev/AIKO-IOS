import ComposableArchitecture
import Foundation

/// Handles app-wide navigation state and actions
@Reducer
public struct NavigationFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var currentView: NavigationView = .home
        public var showingMenu: Bool = false
        public var selectedMenuItem: MenuItem?
        public var navigationHistory: [NavigationView] = [.home]
        public var isTransitioning: Bool = false

        public init(
            currentView: NavigationView = .home,
            showingMenu: Bool = false,
            selectedMenuItem: MenuItem? = nil
        ) {
            self.currentView = currentView
            self.showingMenu = showingMenu
            self.selectedMenuItem = selectedMenuItem
            navigationHistory = [currentView]
        }
    }

    // MARK: - Action

    public enum Action: Equatable {
        case navigate(to: NavigationDestination)
        case navigateBack
        case toggleMenu(Bool)
        case selectMenuItem(MenuItem?)
        case clearHistory
        case setTransitioning(Bool)
    }

    // MARK: - Reducer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .navigate(destination):
                guard !state.isTransitioning else { return .none }

                state.isTransitioning = true
                let previousView = state.currentView

                switch destination {
                case .home:
                    state.currentView = .home
                case .profile:
                    state.currentView = .profile
                case .acquisitions:
                    state.currentView = .myAcquisitions
                case .userGuide:
                    state.currentView = .userGuide
                case .searchTemplates:
                    state.currentView = .searchTemplates
                case .settings:
                    state.currentView = .settings
                case .acquisitionChat:
                    state.currentView = .acquisitionChat
                case .samGovLookup:
                    state.currentView = .samGovLookup
                case .smartDefaultsDemo:
                    state.currentView = .smartDefaultsDemo
                case let .view(appView):
                    state.currentView = appView
                }

                // Update navigation history
                if previousView != state.currentView {
                    state.navigationHistory.append(state.currentView)
                    // Keep history limited
                    if state.navigationHistory.count > 10 {
                        state.navigationHistory.removeFirst()
                    }
                }

                state.showingMenu = false
                state.selectedMenuItem = nil

                return .run { send in
                    // Small delay for transition
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    await send(.setTransitioning(false))
                }

            case .navigateBack:
                guard state.navigationHistory.count > 1,
                      !state.isTransitioning else { return .none }

                state.isTransitioning = true
                state.navigationHistory.removeLast()
                state.currentView = state.navigationHistory.last ?? .home
                state.showingMenu = false

                return .run { send in
                    try await Task.sleep(nanoseconds: 100_000_000)
                    await send(.setTransitioning(false))
                }

            case let .toggleMenu(show):
                state.showingMenu = show
                if !show {
                    state.selectedMenuItem = nil
                }
                return .none

            case let .selectMenuItem(item):
                state.selectedMenuItem = item
                return .none

            case .clearHistory:
                state.navigationHistory = [state.currentView]
                return .none

            case let .setTransitioning(transitioning):
                state.isTransitioning = transitioning
                return .none
            }
        }
    }
}

// MARK: - Navigation Models

public enum NavigationDestination: Equatable, Sendable {
    case home
    case profile
    case acquisitions
    case userGuide
    case searchTemplates
    case settings
    case acquisitionChat
    case samGovLookup
    case smartDefaultsDemo
    case view(NavigationView)
}

public enum NavigationView: String, CaseIterable, Equatable, Sendable {
    case home = "Home"
    case profile = "Profile"
    case myAcquisitions = "My Acquisitions"
    case searchTemplates = "Search Templates"
    case userGuide = "User Guide"
    case settings = "Settings"
    case samGovLookup = "SAM.gov Lookup"
    case acquisitionChat = "Acquisition Chat"
    case smartDefaultsDemo = "Smart Defaults Demo"
    case loading = "Loading"

    public var iconName: String {
        switch self {
        case .home:
            "house"
        case .profile:
            "person.circle"
        case .myAcquisitions:
            "doc.text"
        case .searchTemplates:
            "magnifyingglass"
        case .userGuide:
            "book"
        case .settings:
            "gear"
        case .samGovLookup:
            "building.2"
        case .acquisitionChat:
            "message"
        case .smartDefaultsDemo:
            "wand.and.stars"
        case .loading:
            "hourglass"
        }
    }
}

public struct MenuItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let destination: NavigationDestination

    public init(id: String, title: String, icon: String, destination: NavigationDestination) {
        self.id = id
        self.title = title
        self.icon = icon
        self.destination = destination
    }

    public static let defaultMenuItems: [MenuItem] = [
        MenuItem(id: "profile", title: "My Profile", icon: "person.circle", destination: .profile),
        MenuItem(id: "acquisitions", title: "My Acquisitions", icon: "doc.text", destination: .acquisitions),
        MenuItem(id: "chat", title: "Acquisition Chat", icon: "message", destination: .acquisitionChat),
        MenuItem(id: "templates", title: "Search Templates", icon: "magnifyingglass", destination: .searchTemplates),
        MenuItem(id: "sam", title: "SAM.gov Lookup", icon: "building.2", destination: .samGovLookup),
        MenuItem(id: "smartDefaults", title: "Smart Defaults Demo", icon: "wand.and.stars", destination: .smartDefaultsDemo),
        MenuItem(id: "guide", title: "User Guide", icon: "book", destination: .userGuide),
        MenuItem(id: "settings", title: "Settings", icon: "gear", destination: .settings)
    ]
}

// MARK: - Extensions

public extension NavigationFeature.State {
    /// Check if currently at home
    var isAtHome: Bool {
        currentView == .home
    }

    /// Check if can navigate back
    var canNavigateBack: Bool {
        navigationHistory.count > 1 && !isTransitioning
    }

    /// Get previous view if available
    var previousView: NavigationView? {
        guard navigationHistory.count > 1 else { return nil }
        return navigationHistory[navigationHistory.count - 2]
    }
}
