//
//  ContentView.swift
//  LayoverKit
//
//  Main app view with authentication
//

import SwiftUI
import LayoverKit
import AuthenticationServices
#if os(iOS) || os(tvOS)
import UIKit
#endif

/// Main app view with navigation for tvOS
public struct ContentView: View {
    @StateObject var authViewModel = AuthenticationViewModel(authService: AuthenticationService())
    @State var viewModel = RoomListViewModel(
        roomService: RoomService(),
        sharePlayService: SharePlayService()
    )
    @State var showingCreateRoom = false
    @State var editingRoom: Room?
    @State var navigationPath = NavigationPath()
    @State var sharePlayReceivedRoom: Room?
    @State var libraryService = LibraryService()
    @State var showingLibrary = false
    @State var showingProfile = false
    @State var showingFaceTimeInstructions = false
    
    public init() {}
    public var body: some View {
        Group {
            if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                mainAppView(currentUser: user)
            } else {
                TVSignInView(viewModel: authViewModel)
            }
        }
        .task {
            await authViewModel.checkAuthenticationState()
        }
    }

    private func mainAppView(currentUser: User) -> some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                #if os(tvOS)
                tvTopBar(currentUser: currentUser)
                #elseif os(macOS)
                macTopBar(currentUser: currentUser)
                #else
                iOSTopBar(currentUser: currentUser)
                #endif
                
                // SharePlay status banner
                if viewModel.isSharePlayActive {
                    HStack {
                        Image(systemName: "shareplay")
                            .font(sharePlayIconFont)
                            .foregroundStyle(.green)
                        Text("SharePlay Active - Sharing with FaceTime participants")
                            .font(sharePlayTextFont)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, sharePlayHPadding)
                    .padding(.vertical, sharePlayVPadding)
                    .background(Color.green.opacity(0.1))
                }

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading rooms...")
                    } else {
                        roomsList
                    }
                }
            }
            .navigationTitle("LayoverLounge")
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomView(
                    currentUser: currentUser,
                    onCreate: { name, activityType in
                        await viewModel.createRoom(
                            name: name,
                            host: currentUser,
                            activityType: activityType
                        )
                        showingCreateRoom = false
                    }
                )
            }
            .sheet(item: $editingRoom) { room in
                EditRoomView(room: room) { name, isPrivate, maxParticipants in
                    await viewModel.updateRoom(
                        room,
                        name: name,
                        isPrivate: isPrivate,
                        maxParticipants: maxParticipants
                    )
                }
            }
            .sheet(isPresented: $showingLibrary) {
                LibraryView(libraryService: libraryService)
            }
            .sheet(isPresented: $showingProfile) {
                TVProfileView(
                    currentUser: currentUser,
                    authViewModel: authViewModel
                )
            }
            .task {
                await viewModel.loadRooms()

                // Setup navigation when SharePlay room is received
                viewModel.onRoomReceivedForNavigation = { room in
                    print("🚀 Auto-navigating to SharePlay room: \(room.name)")
                    sharePlayReceivedRoom = room
                    navigationPath.append(room)
                }
            }
            .navigationDestination(for: Room.self) { room in
                roomDetailView(for: room, currentUser: currentUser)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .alert("FaceTime Setup", isPresented: $showingFaceTimeInstructions) {
                Button("OK") {
                    showingFaceTimeInstructions = false
                }
                #if !targetEnvironment(simulator)
                Button("Try Again") {
                    showingFaceTimeInstructions = false
                    openFaceTime()
                }
                #if os(tvOS) || os(iOS)
                Button("Open App Store") {
                    showingFaceTimeInstructions = false
                    tryOpenAppStoreForFaceTime()
                }
                #endif
                #endif
            } message: {
                #if os(tvOS)
                #if targetEnvironment(simulator)
                Text("⚠️ Simulator Testing\n\nFaceTime can't launch from simulator, but you can test SharePlay:\n\n1. Start FaceTime on your iPhone (same Apple ID)\n2. Ensure iPhone & Mac are on same WiFi\n3. SharePlay sessions should appear here automatically\n\nOR test on physical Apple TV 4K (2nd gen+)")
                #else
                Text("FaceTime couldn't be launched.\n\nOptions:\n• Tap 'Open App Store' to download FaceTime\n• Say \"Hey Siri, FaceTime [contact]\"\n• Press Home → select FaceTime\n\nReturn to Layover once in a call for SharePlay.")
                #endif
                #else
                Text("FaceTime couldn't be launched automatically.\n\nTap 'Open App Store' to download FaceTime, or say \"Hey Siri, open FaceTime\".\n\nOnce you're in a FaceTime call, return to Layover and shared rooms will appear automatically.")
                #endif
            }
        }
    }
    
    // MARK: - Platform-Specific Top Bars
    
    @ViewBuilder
    private func tvTopBar(currentUser: User) -> some View {
        HStack(spacing: 30) {
            // Profile Button
            Button {
                showingProfile = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    Text(currentUser.username)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Join FaceTime Button
            Button {
                openFaceTime()
            } label: {
                Label("Join FaceTime", systemImage: "video.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Refresh Button
            Button {
                Task {
                    await viewModel.loadRooms()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // My Library Button
            Button {
                showingLibrary = true
            } label: {
                Label("My Library", systemImage: "books.vertical")
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Create Room Button
            Button {
                showingCreateRoom = true
            } label: {
                Label("Create Room", systemImage: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(Color(white: 0.1))
    }
    
    @ViewBuilder
    private func macTopBar(currentUser: User) -> some View {
        HStack(spacing: 12) {
            // Profile Button
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
            
            Spacer()
            
            // Refresh Button
            Button {
                Task {
                    await viewModel.loadRooms()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // My Library Button
            Button {
                showingLibrary = true
            } label: {
                Label("My Library", systemImage: "books.vertical")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Create Room Button
            Button {
                showingCreateRoom = true
            } label: {
                Label("Create Room", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
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
        VStack(spacing: 0) {
            // Top row with profile and create room
            HStack(spacing: 12) {
                // Profile Button
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
                
                Spacer()
                
                // Create Room Button
                Button {
                    showingCreateRoom = true
                } label: {
                    Label("Create Room", systemImage: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Bottom row with utility buttons
            HStack(spacing: 12) {
                // Refresh Button
                Button {
                    Task {
                        await viewModel.loadRooms()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // My Library Button
                Button {
                    showingLibrary = true
                } label: {
                    Label("My Library", systemImage: "books.vertical")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        #if os(iOS)
        .background(Color(.systemBackground))
        #elseif os(macOS)
        .background(Color(NSColor.windowBackgroundColor))
        #else
        .background(Color(white: 0.1))
        #endif
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Helper Functions
    
    private func openFaceTime() {
        #if os(tvOS) || os(iOS)
        print("🎥 ========== FACETIME LAUNCH DEBUG ==========")
        
        // Print device/simulator info
        #if targetEnvironment(simulator)
        print("📱 Running on SIMULATOR")
        #else
        print("📱 Running on PHYSICAL DEVICE")
        #endif
        
        #if os(tvOS)
        print("📺 Platform: tvOS")
        print("⚠️ NOTE: FaceTime on Apple TV requires:")
        print("   - tvOS 17.0 or later")
        print("   - Physical Apple TV device (4K 2nd gen or later)")
        print("   - FaceTime app may not be available in Simulator")
        #else
        print("📱 Platform: iOS")
        #endif
        
        print("🎥 Attempting to open FaceTime automatically...")
        
        // First, check if we can query the URL
        if let url = URL(string: "facetime://") {
            let canOpen = UIApplication.shared.canOpenURL(url)
            print("🎥 URL created: facetime://")
            print("🎥 canOpenURL check: \(canOpen ? "✅ YES" : "❌ NO (FaceTime may not be installed or URL scheme not registered)")")
            
            if !canOpen {
                print("⚠️ FaceTime URL scheme is NOT available on this device")
                print("⚠️ Possible reasons:")
                print("   - FaceTime is not installed (not available in tvOS simulator)")
                print("   - FaceTime is disabled in Settings")
                print("   - Running on unsupported device/simulator")
                print("   - Device doesn't support FaceTime (Apple TV 4K 2nd gen+ only)")
            }
            
            print("🎥 Attempting to open URL anyway...")
            UIApplication.shared.open(url, options: [:]) { success in
                DispatchQueue.main.async {
                    print("🎥 UIApplication.open callback received")
                    print("🎥 Success parameter: \(success)")
                    if success {
                        print("✅ FaceTime launched successfully!")
                    } else {
                        print("❌ UIApplication.open returned FALSE")
                        print("❌ FaceTime could not be launched via facetime:// URL scheme")
                        // Try alternative methods
                        self.tryAlternativeFaceTimeLaunch()
                    }
                }
            }
        } else {
            print("❌ CRITICAL: Could not create URL from 'facetime://'")
            tryAlternativeFaceTimeLaunch()
        }
        #endif
    }
    
    #if os(tvOS) || os(iOS)
    private func tryAlternativeFaceTimeLaunch() {
        print("🔄 Trying alternative FaceTime launch methods...")
        
        // Try alternative URL schemes
        let alternativeSchemes = [
            "facetime-prompt://",
            "facetime-audio://",
            "com.apple.facetime://"
        ]
        
        var launched = false
        for scheme in alternativeSchemes {
            print("🔍 Testing scheme: \(scheme)")
            
            if let url = URL(string: scheme) {
                let canOpen = UIApplication.shared.canOpenURL(url)
                print("   canOpenURL: \(canOpen ? "✅ YES" : "❌ NO")")
                
                if canOpen {
                    print("   Attempting to open...")
                    UIApplication.shared.open(url, options: [:]) { success in
                        print("   Result: \(success ? "✅ SUCCESS" : "❌ FAILED")")
                        if success {
                            print("✅ FaceTime launched with alternate scheme: \(scheme)")
                            launched = true
                        }
                    }
                    if launched { break }
                } else {
                    print("   ⏭️  Skipping (not available)")
                }
            } else {
                print("   ❌ Could not create URL from scheme")
            }
        }
        
        // Try opening App Store to download FaceTime
        if !launched {
            print("🔄 Attempting to open App Store for FaceTime download...")
            tryOpenAppStoreForFaceTime()
        }
    }
    
    private func tryOpenAppStoreForFaceTime() {
        // FaceTime App Store URLs
        let appStoreURLs = [
            "itms-apps://apps.apple.com/app/facetime/id1110145091", // FaceTime app ID
            "itms-appss://apps.apple.com/app/facetime/id1110145091",
            "itms-apps://apps.apple.com/app/id1110145091",
            "itms-apps://itunes.apple.com/app/id1110145091"
        ]
        
        var appStoreOpened = false
        
        for urlString in appStoreURLs {
            print("🔍 Testing App Store URL: \(urlString)")
            
            if let url = URL(string: urlString) {
                let canOpen = UIApplication.shared.canOpenURL(url)
                print("   canOpenURL: \(canOpen ? "✅ YES" : "❌ NO")")
                
                if canOpen {
                    print("   Attempting to open App Store...")
                    UIApplication.shared.open(url, options: [:]) { success in
                        DispatchQueue.main.async {
                            if success {
                                print("✅ App Store opened for FaceTime download")
                                appStoreOpened = true
                            } else {
                                print("❌ Failed to open App Store")
                            }
                        }
                    }
                    if appStoreOpened { break }
                } else {
                    print("   ⏭️  Skipping (not available)")
                }
            }
        }
        
        // If all methods failed, show instructions
        if !appStoreOpened {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("❌ ========== ALL LAUNCH METHODS FAILED ==========")
                
                #if targetEnvironment(simulator)
                print("⚠️ SIMULATOR LIMITATION DETECTED")
                print("⚠️ FaceTime is NOT available in tvOS/iOS Simulator")
                print("⚠️ App Store is also NOT available in Simulator")
                print("⚠️ Solutions:")
                print("   1. Test on a PHYSICAL Apple TV device (Apple TV 4K 2nd gen or later)")
                print("   2. Test on a PHYSICAL iPhone/iPad")
                print("   3. For simulator testing, the alert will guide users to manual setup")
                #else
                print("❌ FaceTime not available on this physical device")
                print("❌ App Store could not be opened")
                print("❌ Please check:")
                print("   - FaceTime is installed and enabled in Settings")
                print("   - Device supports FaceTime")
                print("   - Running tvOS 17.0+ on Apple TV 4K (2nd gen or later)")
                print("   - App Store is accessible")
                #endif
                
                print("❌ Summary:")
                print("   - Primary facetime:// scheme: FAILED")
                print("   - Alternative schemes: FAILED")
                print("   - App Store launch: FAILED")
                print("   - Showing user instructions")
                print("🎥 ============================================")
                self.showingFaceTimeInstructions = true
            }
        } else {
            print("✅ ========== APP STORE OPENED ==========")
        }
    }
    #endif
    
    // Platform-specific SharePlay banner properties
    #if os(tvOS)
    private var sharePlayIconFont: Font { .system(size: 32) }
    private var sharePlayTextFont: Font { .system(size: 28) }
    private var sharePlayHPadding: CGFloat { 40 }
    private var sharePlayVPadding: CGFloat { 8 }
    #elseif os(macOS)
    private var sharePlayIconFont: Font { .system(size: 16) }
    private var sharePlayTextFont: Font { .system(size: 13) }
    private var sharePlayHPadding: CGFloat { 16 }
    private var sharePlayVPadding: CGFloat { 6 }
    #else
    private var sharePlayIconFont: Font { .system(size: 20) }
    private var sharePlayTextFont: Font { .system(size: 14) }
    private var sharePlayHPadding: CGFloat { 16 }
    private var sharePlayVPadding: CGFloat { 8 }
    #endif

    private var roomsList: some View {
        List {
            if viewModel.rooms.isEmpty {
                ContentUnavailableView(
                    "No Rooms Yet",
                    systemImage: "rectangle.3.group",
                    description: Text("Create a room or join a FaceTime call to see shared rooms")
                )
            } else {
                ForEach(viewModel.rooms) { room in
                    Group {
                        #if os(macOS)
                        Button {
                            print("🖱️ macOS: Room button clicked: \(room.name)")
                            navigationPath.append(room)
                        } label: {
                            RoomRowView(room: room)
                        }
                        .buttonStyle(.plain)
                        #else
                        NavigationLink(value: room) {
                            RoomRowView(room: room)
                        }
                        #endif
                    }
                    .contextMenu {
                        Button {
                            editingRoom = room
                        } label: {
                            Label("Edit Room", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteRoom(room)
                            }
                        } label: {
                            Label("Delete Room", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadRooms()
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }

    @ViewBuilder
    private func roomDetailView(for room: Room, currentUser: User) -> some View {
        let _ = print("🏠 Navigating to room: \(room.name), type: \(room.activityType)")
        let _ = print("   Current user ID: \(currentUser.id)")

        switch room.activityType {
        case .appleTVPlus:
            AppleTVView(room: room, currentUser: currentUser, sharePlayService: viewModel.sharePlayService, libraryService: libraryService)
        case .appleMusic:
            AppleMusicView(room: room, currentUser: currentUser, sharePlayService: viewModel.sharePlayService)
        case .texasHoldem:
            TexasHoldemView(room: room, currentUser: currentUser)
        case .chess:
            Text("Chess - Coming Soon")
        }
    }
}

// Platform-responsive Profile View
public struct TVProfileView: View {
    let currentUser: User
    @ObservedObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
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
                        .background(Color.red)
                        .cornerRadius(signOutButtonCornerRadius)
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
        }
    }
    
    // Platform-specific styling
    #if os(tvOS)
    private var profileIconSize: CGFloat { 100 }
    private var profileNameFont: Font { .largeTitle }
    private var profileEmailFont: Font { .title3 }
    private var profileSpacing: CGFloat { 30 }
    private var signOutButtonFontSize: CGFloat { 38 }
    private var signOutButtonMaxWidth: CGFloat { 900 }
    private var signOutButtonHeight: CGFloat { 100 }
    private var signOutButtonCornerRadius: CGFloat { 16 }
    private var signOutButtonBottomPadding: CGFloat { 60 }
    private var profilePadding: CGFloat { 40 }
    #elseif os(macOS)
    private var profileIconSize: CGFloat { 60 }
    private var profileNameFont: Font { .title }
    private var profileEmailFont: Font { .body }
    private var profileSpacing: CGFloat { 20 }
    private var signOutButtonFontSize: CGFloat { 16 }
    private var signOutButtonMaxWidth: CGFloat { 300 }
    private var signOutButtonHeight: CGFloat { 44 }
    private var signOutButtonCornerRadius: CGFloat { 8 }
    private var signOutButtonBottomPadding: CGFloat { 30 }
    private var profilePadding: CGFloat { 40 }
    #else
    private var profileIconSize: CGFloat { 80 }
    private var profileNameFont: Font { .largeTitle }
    private var profileEmailFont: Font { .body }
    private var profileSpacing: CGFloat { 24 }
    private var signOutButtonFontSize: CGFloat { 18 }
    private var signOutButtonMaxWidth: CGFloat { .infinity }
    private var signOutButtonHeight: CGFloat { 50 }
    private var signOutButtonCornerRadius: CGFloat { 10 }
    private var signOutButtonBottomPadding: CGFloat { 40 }
    private var profilePadding: CGFloat { 24 }
    #endif
}

// Platform-responsive Sign In View
public struct TVSignInView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showManualSignIn = false
    @State private var showRegistration = false
    
    public var body: some View {
        VStack(spacing: platformSpacing) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: titleSpacing) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: logoSize))
                    .foregroundStyle(.blue.gradient)
                
                Text("Layover")
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                
                Text("Connect, Watch, Play Together")
                    .font(subtitleFont)
                    .foregroundColor(.secondary)
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
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: buttonMaxWidth)
                .frame(height: buttonHeight)
                .cornerRadius(buttonCornerRadius)
            
                // Manual Sign In Button
                Button {
                    showManualSignIn = true
                } label: {
                    Text("Sign In with Email")
                        .font(.system(size: buttonFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: buttonMaxWidth)
                        .frame(height: buttonHeight)
                        .background(Color.green)
                        .cornerRadius(buttonCornerRadius)
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
                        .foregroundColor(.blue)
                        .frame(maxWidth: buttonMaxWidth)
                        .frame(height: buttonHeight)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: buttonCornerRadius)
                                .stroke(Color.blue, lineWidth: buttonBorderWidth)
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
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(progressScale)
                } else {
                    Text("Sign In")
                        .font(.system(size: signInButtonFontSize, weight: .semibold))
                }
            }
            .frame(maxWidth: signInButtonMaxWidth)
            .frame(height: signInButtonHeight)
            .background(email.isEmpty || password.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(signInButtonCornerRadius)
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
