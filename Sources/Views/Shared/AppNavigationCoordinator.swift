import SwiftUI

// MARK: - App Navigation

/// Represents the main app tabs
public enum AppTab: Hashable {
    case home
    case library
    case profile
    case games
    case settings
}

/// Sheet presentations in the app
public enum AppSheet: Identifiable {
    case profile
    case settings
    case gameSetup
    case shareSession
    case signIn
    case library
    case globalFeatures
    case languageExchange
    case manualSignIn
    case registration

    public var id: Self { self }
}

// MARK: - Navigation Coordinator

/// Centralized navigation state management for the entire app
/// Replaces scattered @State navigation booleans with a single coordinator
/// Benefits:
/// - Single source of truth for navigation state
/// - Easier to reason about navigation flow
/// - Type-safe tab and sheet management
/// - Eliminates -40 lines of @State declarations
@MainActor
public final class AppNavigationCoordinator: ObservableObject {
    @Published public var activeTab: AppTab = .home
    @Published public var navigationPath = NavigationPath()
    @Published public var presentedSheet: AppSheet?
    @Published public var isLoading = false

    /// Navigate to a specific tab
    public func navigate(to tab: AppTab) {
        activeTab = tab
        navigationPath.removeLast(navigationPath.count)
    }

    /// Present a sheet
    public func present(_ sheet: AppSheet) {
        presentedSheet = sheet
    }

    /// Dismiss current sheet
    public func dismissSheet() {
        presentedSheet = nil
    }

    /// Navigate to tab and optionally present a sheet
    public func navigate(to tab: AppTab, presenting sheet: AppSheet?) {
        activeTab = tab
        navigationPath.removeLast(navigationPath.count)
        if let sheet = sheet {
            presentedSheet = sheet
        }
    }

    /// Push to navigation stack
    public func push<Destination: Hashable>(_ destination: Destination) {
        navigationPath.append(destination)
    }

    /// Pop from navigation stack
    public func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    /// Clear all navigation
    public func reset() {
        activeTab = .home
        navigationPath.removeLast(navigationPath.count)
        presentedSheet = nil
    }

    /// Set loading state
    public func setLoading(_ loading: Bool) {
        isLoading = loading
    }
}

// MARK: - Navigation Helpers

extension AppNavigationCoordinator {
    /// Convenience method to go to library
    public func goToLibrary() {
        navigate(to: .library)
    }

    /// Convenience method to go to games
    public func goToGames() {
        navigate(to: .games)
    }

    /// Convenience method to go to profile
    public func goToProfile() {
        navigate(to: .profile)
    }

    /// Convenience method to go to home
    public func goToHome() {
        navigate(to: .home)
    }
}

// MARK: - Preview Helper

#if DEBUG
struct AppNavigationCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        Text("Navigation Coordinator initialized")
            .environmentObject(AppNavigationCoordinator())
    }
}
#endif
