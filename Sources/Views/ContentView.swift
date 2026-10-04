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
    @State var showingLanguageExchange = false
    
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
            .sheet(isPresented: $showingLanguageExchange) {
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
                
                // Language Exchange Button with custom design
                Button {
                    showingLanguageExchange = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "message.badge.waveform.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Language Exchange")
                                    .font(.system(size: 32, weight: .bold))
                                Text("NEW")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.yellow.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            Text("Practice languages with real-time translation")
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
                                            Color(red: 0.9, green: 0.3, blue: 0.5),
                                            Color(red: 0.7, green: 0.2, blue: 0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        }
                        .shadow(color: .pink.opacity(0.6), radius: 25, x: 0, y: 12)
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
                
                // Language Exchange Button
                Button {
                    showingLanguageExchange = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "message.badge.waveform.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Language Exchange")
                                    .font(.system(size: 18, weight: .bold))
                                Text("NEW")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                            }
                            Text("Practice with real-time translation")
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
                                            Color(red: 0.9, green: 0.3, blue: 0.5),
                                            Color(red: 0.7, green: 0.2, blue: 0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        }
                        .shadow(color: .pink.opacity(0.6), radius: 15, x: 0, y: 8)
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
