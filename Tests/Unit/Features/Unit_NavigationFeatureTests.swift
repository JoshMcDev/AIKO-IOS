import XCTest
@testable import AIKO
import ComposableArchitecture

@MainActor
final class NavigationFeatureTests: XCTestCase {
    
    func testInitialState() {
        let state = NavigationFeature.State()
        
        XCTAssertEqual(state.currentView, .home)
        XCTAssertFalse(state.showingMenu)
        XCTAssertNil(state.selectedMenuItem)
        XCTAssertEqual(state.navigationHistory, [.home])
        XCTAssertFalse(state.isTransitioning)
    }
    
    func testNavigation() async {
        let store = TestStore(
            initialState: NavigationFeature.State()
        ) {
            NavigationFeature()
        }
        
        // Navigate to profile
        await store.send(.navigate(to: .profile)) {
            $0.isTransitioning = true
            $0.currentView = .profile
            $0.navigationHistory = [.home, .profile]
            $0.showingMenu = false
            $0.selectedMenuItem = nil
        }
        
        // Wait for transition to complete
        await store.receive(.setTransitioning(false)) {
            $0.isTransitioning = false
        }
        
        // Navigate to settings
        await store.send(.navigate(to: .settings)) {
            $0.isTransitioning = true
            $0.currentView = .settings
            $0.navigationHistory = [.home, .profile, .settings]
        }
        
        await store.receive(.setTransitioning(false)) {
            $0.isTransitioning = false
        }
    }
    
    func testNavigateBack() async {
        let store = TestStore(
            initialState: NavigationFeature.State(
                currentView: .settings,
                navigationHistory: [.home, .profile, .settings]
            )
        ) {
            NavigationFeature()
        }
        
        // Navigate back
        await store.send(.navigateBack) {
            $0.isTransitioning = true
            $0.navigationHistory = [.home, .profile]
            $0.currentView = .profile
            $0.showingMenu = false
        }
        
        await store.receive(.setTransitioning(false)) {
            $0.isTransitioning = false
        }
        
        // Navigate back again
        await store.send(.navigateBack) {
            $0.isTransitioning = true
            $0.navigationHistory = [.home]
            $0.currentView = .home
        }
        
        await store.receive(.setTransitioning(false)) {
            $0.isTransitioning = false
        }
        
        // Can't navigate back from home
        await store.send(.navigateBack)
        // No state change expected
    }
    
    func testNavigationHistoryLimit() async {
        let store = TestStore(
            initialState: NavigationFeature.State()
        ) {
            NavigationFeature()
        }
        
        // Navigate through more than 10 views
        let views: [NavigationDestination] = [
            .profile, .acquisitions, .settings, .userGuide,
            .searchTemplates, .samGovLookup, .acquisitionChat,
            .home, .profile, .acquisitions, .settings
        ]
        
        for destination in views {
            await store.send(.navigate(to: destination))
            await store.receive(.setTransitioning(false))
        }
        
        // History should be limited to 10 items
        XCTAssertLessThanOrEqual(store.state.navigationHistory.count, 10)
    }
    
    func testMenuToggle() async {
        let store = TestStore(
            initialState: NavigationFeature.State()
        ) {
            NavigationFeature()
        }
        
        // Open menu
        await store.send(.toggleMenu(true)) {
            $0.showingMenu = true
        }
        
        // Select menu item
        let menuItem = MenuItem.defaultMenuItems.first!
        await store.send(.selectMenuItem(menuItem)) {
            $0.selectedMenuItem = menuItem
        }
        
        // Close menu
        await store.send(.toggleMenu(false)) {
            $0.showingMenu = false
            $0.selectedMenuItem = nil
        }
    }
    
    func testNavigationWhileTransitioning() async {
        let store = TestStore(
            initialState: NavigationFeature.State(
                isTransitioning: true
            )
        ) {
            NavigationFeature()
        }
        
        // Navigation should be ignored while transitioning
        await store.send(.navigate(to: .profile))
        // No state change expected
        
        await store.send(.navigateBack)
        // No state change expected
    }
    
    func testClearHistory() async {
        let store = TestStore(
            initialState: NavigationFeature.State(
                currentView: .settings,
                navigationHistory: [.home, .profile, .settings]
            )
        ) {
            NavigationFeature()
        }
        
        await store.send(.clearHistory) {
            $0.navigationHistory = [.settings]
        }
    }
    
    func testNavigationStateHelpers() {
        var state = NavigationFeature.State()
        XCTAssertTrue(state.isAtHome)
        XCTAssertFalse(state.canNavigateBack)
        XCTAssertNil(state.previousView)
        
        state.currentView = .profile
        state.navigationHistory = [.home, .profile]
        XCTAssertFalse(state.isAtHome)
        XCTAssertTrue(state.canNavigateBack)
        XCTAssertEqual(state.previousView, .home)
        
        state.isTransitioning = true
        XCTAssertFalse(state.canNavigateBack)
    }
    
    func testMenuItemNavigation() async {
        let store = TestStore(
            initialState: NavigationFeature.State()
        ) {
            NavigationFeature()
        }
        
        // Select menu item
        let profileMenuItem = MenuItem.defaultMenuItems.first { $0.id == "profile" }!
        await store.send(.selectMenuItem(profileMenuItem)) {
            $0.selectedMenuItem = profileMenuItem
        }
        
        // Clear selection
        await store.send(.selectMenuItem(nil)) {
            $0.selectedMenuItem = nil
        }
    }
}

// MARK: - AppView Tests

final class AppViewTests: XCTestCase {
    
    func testAllCasesHaveIcons() {
        for view in AppView.allCases {
            XCTAssertFalse(view.iconName.isEmpty, "AppView case \(view) should have an icon")
        }
    }
    
    func testIconNames() {
        XCTAssertEqual(AppView.home.iconName, "house")
        XCTAssertEqual(AppView.profile.iconName, "person.circle")
        XCTAssertEqual(AppView.myAcquisitions.iconName, "doc.text")
        XCTAssertEqual(AppView.searchTemplates.iconName, "magnifyingglass")
        XCTAssertEqual(AppView.userGuide.iconName, "book")
        XCTAssertEqual(AppView.settings.iconName, "gear")
        XCTAssertEqual(AppView.samGovLookup.iconName, "building.2")
        XCTAssertEqual(AppView.acquisitionChat.iconName, "message")
        XCTAssertEqual(AppView.loading.iconName, "hourglass")
    }
}

// MARK: - MenuItem Tests

final class MenuItemTests: XCTestCase {
    
    func testDefaultMenuItems() {
        let menuItems = MenuItem.defaultMenuItems
        
        XCTAssertEqual(menuItems.count, 7)
        
        // Verify all expected items exist
        let itemIds = Set(menuItems.map { $0.id })
        let expectedIds: Set<String> = [
            "profile", "acquisitions", "chat", "templates",
            "sam", "guide", "settings"
        ]
        XCTAssertEqual(itemIds, expectedIds)
    }
    
    func testMenuItemProperties() {
        let profileItem = MenuItem.defaultMenuItems.first { $0.id == "profile" }!
        
        XCTAssertEqual(profileItem.title, "My Profile")
        XCTAssertEqual(profileItem.icon, "person.circle")
        XCTAssertEqual(profileItem.destination, .profile)
    }
}