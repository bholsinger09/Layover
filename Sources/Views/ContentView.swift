//
//  ContentView.swift
//  LayoverKit
//
//  Main app view with authentication
//

import SwiftUI
import AuthenticationServices
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Main app view with navigation for tvOS
public struct ContentView: View {
    @StateObject var authViewModel = AuthenticationViewModel(authService: AuthenticationService())
    @State var libraryService = LibraryService()
    @StateObject private var navigationCoordinator = AppNavigationCoordinator()
    
    // Guest user for non-account-based access
    private var guestUser: User {
        User(username: "Guest", email: nil)
    }
    
    // Current user (authenticated or guest)
    private var currentUser: User {
        authViewModel.currentUser ?? guestUser
    }
    
    // Check if user is in guest mode
    private var isGuestMode: Bool {
        authViewModel.currentUser == nil
    }
    
    public init() {}
    public var body: some View {
        mainAppView(currentUser: currentUser)
            .sheet(item: $navigationCoordinator.presentedSheet) { sheet in
                sheetView(for: sheet)
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    navigationCoordinator.dismissSheet()
                }
            }
            .task {
                await authViewModel.checkAuthenticationState()
            }
    }
    
    @ViewBuilder
    private func sheetView(for sheet: AppSheet) -> some View {
        switch sheet {
        case .signIn:
            PlatformSignInView(viewModel: authViewModel)
        case .library:
            LibraryView(libraryService: libraryService)
        case .profile:
            TVProfileView(
                currentUser: currentUser,
                authViewModel: authViewModel
            )
        case .globalFeatures:
            GlobalFeaturesHubView()
        case .languageExchange:
            LanguageExchangeView(
                room: Room(
                    id: UUID(),
                    name: "Language Practice Room",
                    hostID: currentUser.id,
                    participants: [currentUser],
                    activityType: .appleMusic,
                    maxParticipants: 10,
                    isPrivate: false,
                    languageExchangeEnabled: true
                ),
                currentUser: currentUser
            )
        case .shareSession:
            ChessView(
                room: Room(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                    name: "Chess",
                    hostID: currentUser.id,
                    activityType: .chess,
                    maxParticipants: 2,
                    isPrivate: false
                ),
                currentUser: currentUser
            )
        case .gameSetup:
            GamesLauncherView(currentUser: currentUser)
        case .settings:
            Text("Settings View")  // Placeholder
        case .manualSignIn:
            TVManualSignInView(viewModel: authViewModel)
        case .registration:
            TVRegistrationView(viewModel: authViewModel)
        }
    }

    private func mainAppView(currentUser: User) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                #if os(tvOS)
                tvTopBar(currentUser: currentUser)
                #elseif os(macOS)
                macTopBar(currentUser: currentUser)
                #else
                iOSTopBar(currentUser: currentUser)
                #endif
                
                // Home Screen Content
                homeScreenContent(currentUser: currentUser)
            }
            .background(
                Image("airport-lounge")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            )
            #if os(tvOS)
            .navigationTitle("ShareALayover")
            #elseif os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ShareALayover")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            #endif
            #if os(tvOS)
            #else
            #endif
        }
    }
    
    @ViewBuilder
    private func homeScreenContent(currentUser: User) -> some View {
        #if os(iOS)
        ScrollView {
            iOSHomeContent(currentUser: currentUser)
        }
        #else
        VStack(spacing: 40) {
            // Guest mode banner
            if isGuestMode {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)
                    Text("Guest Mode · Sign in to access SharePlay and sync features")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        navigationCoordinator.present(.signIn)
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 60)
            }
            
            Spacer()
            
            // App Title and Welcome
            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 80))
                    .foregroundStyle(.cyan.gradient)
                    .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 8)
                
                Text("Welcome to ShareALayover")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 12, x: 0, y: 6)
                
                Text("Your Personal Social Entertainment Hub")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.9), radius: 10, x: 0, y: 5)
                
                Text("Watch, Listen, and Play in Perfect Harmony")
                    .font(.system(size: 20))
                    .foregroundStyle(.cyan)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.9), radius: 10, x: 0, y: 5)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 60)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.75)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)

            // Home Screen Buttons
            VStack(spacing: 24) {
                HomeButtonView.largeBlueButton(
                    title: "Play Games",
                    subtitle: "Chess, Checkers & Connect Four",
                    action: { navigationCoordinator.present(.gameSetup) }
                )

                HomeButtonView.purpleButton(
                    title: "My Media Library",
                    subtitle: "Curated collection ready to share",
                    action: { navigationCoordinator.present(.library) }
                )

                HomeButtonView.greenButton(
                    title: "Global Features",
                    subtitle: "Worldwide rooms, events & scheduling",
                    badge: "NEW",
                    action: { navigationCoordinator.present(.globalFeatures) }
                )

                HomeButtonView.magentaButton(
                    title: "Language Exchange",
                    subtitle: "Practice with real-time translation",
                    badge: "NEW",
                    action: { navigationCoordinator.present(.languageExchange) }
                )
            }
            
            Spacer()
        }
        .focusSection()
        #endif
    }
    
    // iOS-optimized home content
    @ViewBuilder
    private func iOSHomeContent(currentUser: User) -> some View {
        VStack(spacing: 20) {
            // Guest mode banner
            if isGuestMode {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Guest Mode")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        navigationCoordinator.present(.signIn)
                    } label: {
                        Text("Sign In")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 16)
            }
            
            // App Title and Welcome
            VStack(spacing: 12) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 50))
                    .foregroundStyle(.cyan.gradient)
                    .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
                
                Text("Welcome to ShareALayover")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.9), radius: 8, x: 0, y: 4)
                
                Text("Your Personal Social Entertainment Hub")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 3)
                
                Text("Watch, Listen, and Play in Perfect Harmony")
                    .font(.system(size: 12))
                    .foregroundStyle(.cyan)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 3)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.75)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Connection Options
            VStack(spacing: 16) {
                HomeButtonView.cyanButton(
                    title: "SharePlay Session",
                    subtitle: isGuestMode ? "Account required" : "Real-time synchronized experience",
                    action: {
                        if isGuestMode {
                            navigationCoordinator.present(.signIn)
                        } else {
                            navigationCoordinator.present(.shareSession)
                        }
                    }
                )

                HomeButtonView.purpleButton(
                    title: "My Media Library",
                    subtitle: "Curated collection ready to share",
                    action: { navigationCoordinator.present(.library) }
                )

                HomeButtonView.orangeButton(
                    title: "Play Games",
                    subtitle: "Chess, Checkers & Connect Four",
                    action: { navigationCoordinator.present(.gameSetup) }
                )

                HomeButtonView.greenButton(
                    title: "Global Features",
                    subtitle: "Worldwide rooms, events & scheduling",
                    badge: "NEW",
                    action: { navigationCoordinator.present(.globalFeatures) }
                )

                HomeButtonView.magentaButton(
                    title: "Language Exchange",
                    subtitle: "Practice with real-time translation",
                    badge: "NEW",
                    action: { navigationCoordinator.present(.languageExchange) }
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    
    // MARK: - Platform-Specific Top Bars
    
    @ViewBuilder
    private func tvTopBar(currentUser: User) -> some View {
        HStack(spacing: 30) {
            // Profile or Sign In Button
            Button {
                if isGuestMode {
                    navigationCoordinator.present(.signIn)
                } else {
                    navigationCoordinator.present(.profile)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isGuestMode ? "person.crop.circle.badge.plus" : "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    Text(isGuestMode ? "Sign In" : currentUser.username)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.85))
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.75),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        #if os(tvOS)
        .focusSection()
        #endif
    }
    
    @ViewBuilder
    private func macTopBar(currentUser: User) -> some View {
        HStack(spacing: 12) {
            // Profile Button (only shown when authenticated)
            if !isGuestMode {
                Button {
                    navigationCoordinator.present(.profile)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                        Text(currentUser.username)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        #else
        .background(Color.gray.opacity(0.1))
        #endif
    }
    
    @ViewBuilder
    private func iOSTopBar(currentUser: User) -> some View {
        HStack(spacing: 12) {
            // Profile Button (only shown when authenticated)
            if !isGuestMode {
                Button {
                    navigationCoordinator.present(.profile)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                        Text(currentUser.username)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        #if os(iOS)
        .background(Color(.systemBackground))
        #elseif os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(white: 0.1))
        #endif
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }
}

// Platform-responsive Profile View
