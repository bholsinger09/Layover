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
    @State var showingLibrary = false
    @State var showingProfile = false
    @State var showingSharePlaySession = false
    @State var showingGamesLauncher = false
    @State var showingSignIn = false
    @State var showingGlobalFeatures = false
    
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
            .sheet(isPresented: $showingSignIn) {
                PlatformSignInView(viewModel: authViewModel)
            }
            .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    showingSignIn = false
                }
            }
            .task {
                await authViewModel.checkAuthenticationState()
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
            .sheet(isPresented: $showingLibrary) {
                LibraryView(libraryService: libraryService)
            }
            .sheet(isPresented: $showingProfile) {
                TVProfileView(
                    currentUser: currentUser,
                    authViewModel: authViewModel
                )
            }
            .sheet(isPresented: $showingGlobalFeatures) {
                GlobalFeaturesHubView()
            }
            #if os(tvOS)
            .fullScreenCover(isPresented: $showingSharePlaySession) {
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
            }
            .fullScreenCover(isPresented: $showingGamesLauncher) {
                GamesLauncherView(currentUser: currentUser)
            }
            #else
            .sheet(isPresented: $showingSharePlaySession) {
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
            }
            .sheet(isPresented: $showingGamesLauncher) {
                GamesLauncherView(currentUser: currentUser)
            }
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
                        showingSignIn = true
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
            
            // Connection Options with unique styling
            VStack(spacing: 24) {
                // Connect to SharePlay Button with custom design
                Button {
                    // Allow all users (including guests) to access games
                    // Sign-in will be prompted only if they select SharePlay mode
                    showingGamesLauncher = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Play Games")
                                .font(.system(size: 32, weight: .bold))
                            Text("Chess, Checkers & Connect Four")
                                .font(.system(size: 18))
                                .opacity(0.9)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 700)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 40)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.2, green: 0.4, blue: 0.9),
                                            Color(red: 0.1, green: 0.6, blue: 0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        }
                        .shadow(color: .cyan.opacity(0.6), radius: 25, x: 0, y: 12)
                    )
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #else
                .buttonStyle(.plain)
                #endif
                
                // Browse Library Button with custom design
                Button {
                    showingLibrary = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Media Library")
                                .font(.system(size: 32, weight: .bold))
                            Text("Curated collection ready to share")
                                .font(.system(size: 18))
                                .opacity(0.9)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 700)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 40)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.5, green: 0.2, blue: 0.8),
                                            Color(red: 0.7, green: 0.3, blue: 0.9)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        }
                        .shadow(color: .purple.opacity(0.6), radius: 25, x: 0, y: 12)
                    )
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #else
                .buttonStyle(.plain)
                #endif
                
                // Global Features Button with custom design
                Button {
                    showingGlobalFeatures = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Global Features")
                                    .font(.system(size: 32, weight: .bold))
                                Text("NEW")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.yellow.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            Text("World-wide rooms, events & scheduling")
                                .font(.system(size: 18))
                                .opacity(0.9)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 700)
                    .padding(.vertical, 28)
                    .padding(.horizontal, 40)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.1, green: 0.6, blue: 0.4),
                                            Color(red: 0.2, green: 0.7, blue: 0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        }
                        .shadow(color: .green.opacity(0.6), radius: 25, x: 0, y: 12)
                    )
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #else
                .buttonStyle(.plain)
                #endif
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
                        showingSignIn = true
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
                // Connect to SharePlay Button
                Button {
                    // For guests, prompt sign-in for SharePlay-specific features
                    // Single-player features are available via the "Play Chess" button below
                    if isGuestMode {
                        showingSignIn = true
                    } else {
                        showingSharePlaySession = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "shareplay")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SharePlay Session")
                                .font(.system(size: 18, weight: .bold))
                            if isGuestMode {
                                Text("Account required")
                                    .font(.system(size: 12))
                                    .opacity(0.9)
                            } else {
                                Text("Real-time synchronized experience")
                                    .font(.system(size: 12))
                                    .opacity(0.9)
                            }
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.2, green: 0.4, blue: 0.9),
                                            Color(red: 0.1, green: 0.6, blue: 0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        }
                        .shadow(color: .cyan.opacity(0.6), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
                
                // Browse Library Button
                Button {
                    showingLibrary = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("My Media Library")
                                .font(.system(size: 18, weight: .bold))
                            Text("Curated collection ready to share")
                                .font(.system(size: 12))
                                .opacity(0.9)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.5, green: 0.2, blue: 0.8),
                                            Color(red: 0.7, green: 0.3, blue: 0.9)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        }
                        .shadow(color: .purple.opacity(0.6), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
                
                // Play Games Button (Single Player - No Sign In Required)
                Button {
                    showingGamesLauncher = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Play Games")
                                .font(.system(size: 18, weight: .bold))
                            Text("Chess, Checkers & Connect Four")
                                .font(.system(size: 12))
                                .opacity(0.9)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.8, green: 0.3, blue: 0.3),
                                            Color(red: 0.9, green: 0.5, blue: 0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        }
                        .shadow(color: .orange.opacity(0.6), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
                
                // Global Features Button
                Button {
                    showingGlobalFeatures = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Global Features")
                                    .font(.system(size: 18, weight: .bold))
                                Text("NEW")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                            }
                            Text("Worldwide rooms, events & scheduling")
                                .font(.system(size: 12))
                                .opacity(0.9)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.1, green: 0.6, blue: 0.4),
                                            Color(red: 0.2, green: 0.7, blue: 0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        }
                        .shadow(color: .green.opacity(0.6), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
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
                    showingSignIn = true
                } else {
                    showingProfile = true
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
                    showingProfile = true
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
                    showingProfile = true
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
public struct TVProfileView: View {
    let currentUser: User
    @ObservedObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: profileSpacing) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: profileIconSize))
                    .foregroundStyle(.blue)
                
                Text(currentUser.username)
                    .font(profileNameFont)
                    .fontWeight(.bold)
                
                Text(currentUser.email ?? "No email")
                    .font(profileEmailFont)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(spacing: buttonSpacing) {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.signOut()
                            dismiss()
                        }
                    } label: {
                        Text("Sign Out")
                            .font(.system(size: signOutButtonFontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: signOutButtonMaxWidth)
                            .frame(height: signOutButtonHeight)
                            .background(Color.orange)
                            .cornerRadius(signOutButtonCornerRadius)
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete Account")
                            .font(.system(size: deleteButtonFontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: deleteButtonMaxWidth)
                            .frame(height: deleteButtonHeight)
                            .background(Color.red)
                            .cornerRadius(deleteButtonCornerRadius)
                    }
                }
                .padding(.bottom, signOutButtonBottomPadding)
            }
            .padding(profilePadding)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                        dismiss()
                    }
                }
            } message: {
                Text(deleteAccountMessage)
            }
        }
    }
    
    private var deleteAccountMessage: String {
        """
        This will permanently delete your account and all associated data.
        
        • Your profile and preferences will be removed
        • Your game history will be deleted
        • This action cannot be undone
        
        If you have any active subscriptions or in-app purchases, you'll need to cancel them separately through your Apple ID settings.
        """
    }
    
    // Platform-specific styling
    #if os(tvOS)
    private var profileIconSize: CGFloat { 100 }
    private var profileNameFont: Font { .largeTitle }
    private var profileEmailFont: Font { .title3 }
    private var profileSpacing: CGFloat { 30 }
    private var buttonSpacing: CGFloat { 20 }
    private var signOutButtonFontSize: CGFloat { 38 }
    private var signOutButtonMaxWidth: CGFloat { 900 }
    private var signOutButtonHeight: CGFloat { 100 }
    private var signOutButtonCornerRadius: CGFloat { 16 }
    private var deleteButtonFontSize: CGFloat { 38 }
    private var deleteButtonMaxWidth: CGFloat { 900 }
    private var deleteButtonHeight: CGFloat { 100 }
    private var deleteButtonCornerRadius: CGFloat { 16 }
    private var signOutButtonBottomPadding: CGFloat { 60 }
    private var profilePadding: CGFloat { 40 }
    #elseif os(macOS)
    private var profileIconSize: CGFloat { 60 }
    private var profileNameFont: Font { .title }
    private var profileEmailFont: Font { .body }
    private var profileSpacing: CGFloat { 20 }
    private var buttonSpacing: CGFloat { 12 }
    private var signOutButtonFontSize: CGFloat { 16 }
    private var signOutButtonMaxWidth: CGFloat { 300 }
    private var signOutButtonHeight: CGFloat { 44 }
    private var signOutButtonCornerRadius: CGFloat { 8 }
    private var deleteButtonFontSize: CGFloat { 16 }
    private var deleteButtonMaxWidth: CGFloat { 300 }
    private var deleteButtonHeight: CGFloat { 44 }
    private var deleteButtonCornerRadius: CGFloat { 8 }
    private var signOutButtonBottomPadding: CGFloat { 30 }
    private var profilePadding: CGFloat { 40 }
    #else
    private var profileIconSize: CGFloat { 80 }
    private var profileNameFont: Font { .largeTitle }
    private var profileEmailFont: Font { .body }
    private var profileSpacing: CGFloat { 24 }
    private var buttonSpacing: CGFloat { 16 }
    private var signOutButtonFontSize: CGFloat { 18 }
    private var signOutButtonMaxWidth: CGFloat { .infinity }
    private var signOutButtonHeight: CGFloat { 50 }
    private var signOutButtonCornerRadius: CGFloat { 10 }
    private var deleteButtonFontSize: CGFloat { 18 }
    private var deleteButtonMaxWidth: CGFloat { .infinity }
    private var deleteButtonHeight: CGFloat { 50 }
    private var deleteButtonCornerRadius: CGFloat { 10 }
    private var signOutButtonBottomPadding: CGFloat { 40 }
    private var profilePadding: CGFloat { 24 }
    #endif
}

// Platform-responsive Sign In View
public struct PlatformSignInView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showManualSignIn = false
    @State private var showRegistration = false
    
    public var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: platformSpacing) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: titleSpacing) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: logoSize))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.9),
                                    Color.cyan.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 5)
                    
                    Text("ShareALayover")
                        .font(.system(size: titleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 12, x: 0, y: 4)
                    
                    Text("Experience Entertainment Together")
                        .font(subtitleFont)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Powered by Real-Time Sync Technology")
                        .font(.caption)
                        .foregroundColor(.cyan.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, sectionBottomPadding)
                
                Spacer()
            
            // Authentication Options
            VStack(spacing: buttonSpacing) {
                // Sign In with Apple Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await viewModel.signInWithApple()
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(maxWidth: buttonMaxWidth)
                .frame(height: buttonHeight)
                .cornerRadius(buttonCornerRadius)
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            
                // Manual Sign In Button
                Button {
                    showManualSignIn = true
                } label: {
                    Text("Sign In with Email")
                        .font(.system(size: buttonFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: buttonMaxWidth)
                        .frame(height: buttonHeight)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.8),
                                    Color(red: 0.2, green: 0.8, blue: 0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .green.opacity(0.5), radius: 8, x: 0, y: 4)
                        #if os(tvOS)
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .stroke(Color.yellow, lineWidth: 8)
                        )
                        #endif
                }
                .buttonStyle(.plain)
            
                // Register Button
                Button {
                    showRegistration = true
                } label: {
                    Text("Create Account")
                        .font(.system(size: buttonFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: buttonMaxWidth)
                        .frame(height: buttonHeight)
                        .background(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.9),
                                            Color.cyan.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: buttonBorderWidth
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                // Continue as Guest Button
                Button {
                    dismiss()
                } label: {
                    Text("Continue as Guest")
                        .font(.system(size: buttonFontSize, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: buttonMaxWidth)
                        .frame(height: buttonHeight)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .stroke(Color.white.opacity(0.4), lineWidth: guestButtonBorderWidth)
                        )
                }
                .buttonStyle(.plain)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(progressScale)
                        .padding(.top, 20)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: errorFontSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: buttonMaxWidth)
                        .padding(.top, 20)
                }
            }
            .padding(.bottom, finalBottomPadding)
            .padding(.horizontal, horizontalPadding)
            }
        }
        .sheet(isPresented: $showManualSignIn) {
            TVManualSignInView(viewModel: viewModel, isPresented: $showManualSignIn)
        }
        .sheet(isPresented: $showRegistration) {
            TVRegistrationView(viewModel: viewModel, isPresented: $showRegistration)
        }
    }
    
    // Platform-specific sizing
    #if os(tvOS)
    private var logoSize: CGFloat { 120 }
    private var titleSize: CGFloat { 72 }
    private var subtitleFont: Font { .title }
    private var titleSpacing: CGFloat { 20 }
    private var platformSpacing: CGFloat { 50 }
    private var sectionBottomPadding: CGFloat { 40 }
    private var buttonMaxWidth: CGFloat { 1000 }
    private var buttonHeight: CGFloat { 120 }
    private var buttonCornerRadius: CGFloat { 16 }
    private var buttonFontSize: CGFloat { 36 }
    private var buttonSpacing: CGFloat { 40 }
    private var buttonBorderWidth: CGFloat { 4 }
    private var guestButtonBorderWidth: CGFloat { 3 }
    private var progressScale: CGFloat { 2 }
    private var errorFontSize: CGFloat { 28 }
    private var finalBottomPadding: CGFloat { 120 }
    private var horizontalPadding: CGFloat { 0 }
    #elseif os(macOS)
    private var logoSize: CGFloat { 60 }
    private var titleSize: CGFloat { 42 }
    private var subtitleFont: Font { .title3 }
    private var titleSpacing: CGFloat { 12 }
    private var platformSpacing: CGFloat { 30 }
    private var sectionBottomPadding: CGFloat { 30 }
    private var buttonMaxWidth: CGFloat { 400 }
    private var buttonHeight: CGFloat { 50 }
    private var buttonCornerRadius: CGFloat { 10 }
    private var buttonFontSize: CGFloat { 16 }
    private var buttonSpacing: CGFloat { 16 }
    private var buttonBorderWidth: CGFloat { 2 }
    private var guestButtonBorderWidth: CGFloat { 2 }
    private var progressScale: CGFloat { 1 }
    private var errorFontSize: CGFloat { 14 }
    private var finalBottomPadding: CGFloat { 40 }
    private var horizontalPadding: CGFloat { 40 }
    #else // iOS
    private var logoSize: CGFloat { 80 }
    private var titleSize: CGFloat { 48 }
    private var subtitleFont: Font { .title3 }
    private var titleSpacing: CGFloat { 16 }
    private var platformSpacing: CGFloat { 30 }
    private var sectionBottomPadding: CGFloat { 40 }
    private var buttonMaxWidth: CGFloat { .infinity }
    private var buttonHeight: CGFloat { 50 }
    private var buttonCornerRadius: CGFloat { 8 }
    private var buttonFontSize: CGFloat { 18 }
    private var buttonSpacing: CGFloat { 20 }
    private var buttonBorderWidth: CGFloat { 2 }
    private var guestButtonBorderWidth: CGFloat { 1.5 }
    private var progressScale: CGFloat { 1 }
    private var errorFontSize: CGFloat { 14 }
    private var finalBottomPadding: CGFloat { 60 }
    private var horizontalPadding: CGFloat { 40 }
    #endif
}

// Platform-responsive Manual Sign In View
public struct TVManualSignInView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    public enum Field {
        case email, password
    }
    
    public var body: some View {
        NavigationStack {
            #if os(tvOS)
            tvContent
            #else
            standardContent
            #endif
        }
    }
    
    @ViewBuilder
    private var tvContent: some View {
        VStack(spacing: 40) {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            formFields
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
    }
    
    @ViewBuilder
    private var standardContent: some View {
        ScrollView {
            VStack(spacing: standardSpacing) {
                Text("Sign In")
                    .font(standardTitleFont)
                    .fontWeight(.bold)
                    .padding(.top, standardTopPadding)
                
                formFields
                
                Spacer(minLength: 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
        }
    }
    
    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: fieldSpacing) {
            // Email Field
            VStack(alignment: .leading, spacing: labelSpacing) {
                Text("Email")
                    .font(labelFont)
                    .fontWeight(.medium)
                
                TextField("Enter your email", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    #endif
                    #if os(macOS) || os(tvOS)
                    .autocorrectionDisabled()
                    #endif
                    .padding(fieldPadding)
                    .font(fieldFont)
                    .foregroundStyle(fieldTextColor)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: labelSpacing) {
                Text("Password")
                    .font(labelFont)
                    .fontWeight(.medium)
                
                SecureField("Enter your password", text: $password)
                    .textContentType(.password)
                    .padding(fieldPadding)
                    .font(fieldFont)
                    .foregroundStyle(fieldTextColor)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .focused($focusedField, equals: .password)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(errorFont)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Sign In Button
            Button {
                Task {
                    await viewModel.signIn(email: email, password: password)
                    if viewModel.isAuthenticated {
                        isPresented = false
                    }
                }
            } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(progressScale)
                    } else {
                        Text("Sign In")
                            .font(.system(size: signInButtonFontSize, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: signInButtonMaxWidth)
                .frame(height: signInButtonHeight)
                .background(email.isEmpty || password.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                .cornerRadius(signInButtonCornerRadius)
            }
            .buttonStyle(.plain)
            .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, formHorizontalPadding)
    }
    
    // Platform-specific styling
    #if os(tvOS)
    private var standardSpacing: CGFloat { 40 }
    private var standardTitleFont: Font { .largeTitle }
    private var standardTopPadding: CGFloat { 60 }
    private var fieldSpacing: CGFloat { 30 }
    private var labelSpacing: CGFloat { 12 }
    private var labelFont: Font { .title3 }
    private var fieldPadding: CGFloat { 20 }
    private var fieldFont: Font { .title3 }
    private var fieldTextColor: Color { .white }
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.15))
    }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
    }
    private var errorFont: Font { .title3 }
    private var progressScale: CGFloat { 1.5 }
    private var signInButtonFontSize: CGFloat { 36 }
    private var signInButtonMaxWidth: CGFloat { 900 }
    private var signInButtonHeight: CGFloat { 100 }
    private var signInButtonCornerRadius: CGFloat { 16 }
    private var formHorizontalPadding: CGFloat { 100 }
    #elseif os(macOS)
    private var standardSpacing: CGFloat { 24 }
    private var standardTitleFont: Font { .title }
    private var standardTopPadding: CGFloat { 30 }
    private var fieldSpacing: CGFloat { 20 }
    private var labelSpacing: CGFloat { 8 }
    private var labelFont: Font { .headline }
    private var fieldPadding: CGFloat { 12 }
    private var fieldFont: Font { .body }
    private var fieldTextColor: Color { .primary }
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor))
    }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    private var errorFont: Font { .callout }
    private var progressScale: CGFloat { 1.0 }
    private var signInButtonFontSize: CGFloat { 16 }
    private var signInButtonMaxWidth: CGFloat { .infinity }
    private var signInButtonHeight: CGFloat { 44 }
    private var signInButtonCornerRadius: CGFloat { 8 }
    private var formHorizontalPadding: CGFloat { 40 }
    #else // iOS
    private var standardSpacing: CGFloat { 24 }
    private var standardTitleFont: Font { .largeTitle }
    private var standardTopPadding: CGFloat { 20 }
    private var fieldSpacing: CGFloat { 20 }
    private var labelSpacing: CGFloat { 8 }
    private var labelFont: Font { .headline }
    private var fieldPadding: CGFloat { 16 }
    private var fieldFont: Font { .body }
    private var fieldTextColor: Color { .primary }
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
    }
    private var fieldBorder: some View {
        EmptyView()
    }
    private var errorFont: Font { .callout }
    private var progressScale: CGFloat { 1.0 }
    private var signInButtonFontSize: CGFloat { 18 }
    private var signInButtonMaxWidth: CGFloat { .infinity }
    private var signInButtonHeight: CGFloat { 50 }
    private var signInButtonCornerRadius: CGFloat { 10 }
    private var formHorizontalPadding: CGFloat { 24 }
    #endif
}

// Platform-responsive Registration View
public struct TVRegistrationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Binding var isPresented: Bool
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localErrorMessage: String?
    @FocusState private var focusedField: Field?
    
    public enum Field {
        case username, email, password, confirmPassword
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: contentSpacing) {
                    Text("Create Account")
                        .font(titleFont)
                        .fontWeight(.bold)
                        .padding(.top, topPadding)
                    
                    VStack(spacing: fieldSpacing) {
                        // Username Field
                        VStack(alignment: .leading, spacing: labelSpacing) {
                            Text("Username")
                                .font(labelFont)
                                .fontWeight(.medium)
                            
                            TextField("Choose a username", text: $username)
                                .textContentType(.username)
                                #if os(iOS)
                                .autocapitalization(.none)
                                #endif
                                #if os(macOS) || os(tvOS)
                                .autocorrectionDisabled()
                                #endif
                                .padding(fieldPadding)
                                .font(fieldFont)
                                .foregroundStyle(fieldTextColor)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: labelSpacing) {
                            Text("Email")
                                .font(labelFont)
                                .fontWeight(.medium)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                #if os(iOS)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                #endif
                                #if os(macOS) || os(tvOS)
                                .autocorrectionDisabled()
                                #endif
                                .padding(fieldPadding)
                                .font(fieldFont)
                                .foregroundStyle(fieldTextColor)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: labelSpacing) {
                            Text("Password")
                                .font(labelFont)
                                .fontWeight(.medium)
                            
                            SecureField("Create a password", text: $password)
                                .textContentType(.newPassword)
                                .padding(fieldPadding)
                                .font(fieldFont)
                                .foregroundStyle(fieldTextColor)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                                .focused($focusedField, equals: .password)
                            
                            Text("Must be at least 6 characters")
                                .font(hintFont)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: labelSpacing) {
                            Text("Confirm Password")
                                .font(labelFont)
                                .fontWeight(.medium)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding(fieldPadding)
                                .font(fieldFont)
                                .foregroundStyle(fieldTextColor)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                                .focused($focusedField, equals: .confirmPassword)
                        }
                        
                        if let errorMessage = localErrorMessage ?? viewModel.errorMessage {
                            Text(errorMessage)
                                .font(errorFont)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Register Button
                        Button {
                            Task {
                                await register()
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(progressScale)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: registerButtonFontSize, weight: .semibold))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: registerButtonMaxWidth)
                        .frame(height: registerButtonHeight)
                        .background(!isFormValid ? Color.blue.opacity(0.5) : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(registerButtonCornerRadius)
                        .disabled(!isFormValid || viewModel.isLoading)
                    }
                    .padding(.horizontal, formHorizontalPadding)
                    
                    Spacer(minLength: bottomSpacing)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6 && password == confirmPassword
    }
    
    private func register() async {
        localErrorMessage = nil
        
        guard password == confirmPassword else {
            localErrorMessage = "Passwords do not match"
            return
        }
        
        await viewModel.register(username: username, email: email, password: password)
        if viewModel.isAuthenticated {
            isPresented = false
        }
    }
    
    // Platform-specific styling
    #if os(tvOS)
    private var contentSpacing: CGFloat { 40 }
    private var titleFont: Font { .largeTitle }
    private var topPadding: CGFloat { 40 }
    private var fieldSpacing: CGFloat { 30 }
    private var labelSpacing: CGFloat { 12 }
    private var labelFont: Font { .title3 }
    private var fieldPadding: CGFloat { 20 }
    private var fieldFont: Font { .title3 }
    private var fieldTextColor: Color { .white }
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.15))
    }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
    }
    private var hintFont: Font { .caption }
    private var errorFont: Font { .title3 }
    private var progressScale: CGFloat { 1.5 }
    private var registerButtonFontSize: CGFloat { 36 }
    private var registerButtonMaxWidth: CGFloat { 900 }
    private var registerButtonHeight: CGFloat { 100 }
    private var registerButtonCornerRadius: CGFloat { 16 }
    private var formHorizontalPadding: CGFloat { 100 }
    private var bottomSpacing: CGFloat { 40 }
    #elseif os(macOS)
    private var contentSpacing: CGFloat { 30 }
    private var titleFont: Font { .title }
    private var topPadding: CGFloat { 30 }
    private var fieldSpacing: CGFloat { 20 }
    private var labelSpacing: CGFloat { 8 }
    private var labelFont: Font { .headline }
    private var fieldPadding: CGFloat { 12 }
    private var fieldFont: Font { .body }
    private var fieldTextColor: Color { .primary }
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor))
    }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    private var hintFont: Font { .caption }
    private var errorFont: Font { .callout }
    private var progressScale: CGFloat { 1.0 }
    private var registerButtonFontSize: CGFloat { 16 }
    private var registerButtonMaxWidth: CGFloat { .infinity }
    private var registerButtonHeight: CGFloat { 44 }
    private var registerButtonCornerRadius: CGFloat { 8 }
    private var formHorizontalPadding: CGFloat { 40 }
    private var bottomSpacing: CGFloat { 30 }
    #else // iOS
    private var contentSpacing: CGFloat { 30 }
    private var titleFont: Font { .largeTitle }
    private var topPadding: CGFloat { 20 }
    private var fieldSpacing: CGFloat { 20 }
    private var labelSpacing: CGFloat { 8 }
    private var labelFont: Font { .headline }
    private var fieldPadding: CGFloat { 16 }
    private var fieldFont: Font { .body }
    private var fieldTextColor: Color { .primary }
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray6))
    }
    private var fieldBorder: some View {
        EmptyView()
    }
    private var hintFont: Font { .caption }
    private var errorFont: Font { .callout }
    private var progressScale: CGFloat { 1.0 }
    private var registerButtonFontSize: CGFloat { 18 }
    private var registerButtonMaxWidth: CGFloat { .infinity }
    private var registerButtonHeight: CGFloat { 50 }
    private var registerButtonCornerRadius: CGFloat { 10 }
    private var formHorizontalPadding: CGFloat { 24 }
    private var bottomSpacing: CGFloat { 30 }
    #endif
}

#Preview {
    ContentView()
}
