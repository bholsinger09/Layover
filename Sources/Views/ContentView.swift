//
//  ContentView.swift
//  LayoverKit
//
//  Main app view with authentication
//

import SwiftUI
import LayoverKit
import AuthenticationServices

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
                // Custom Top Bar with Large Buttons
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
                
                // SharePlay status banner
                if viewModel.isSharePlayActive {
                    HStack {
                        Image(systemName: "shareplay")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                        Text("SharePlay Active - Sharing with FaceTime participants")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
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
        }
    }

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
                    NavigationLink(value: room) {
                        RoomRowView(room: room)
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

// TV-specific Profile View
public struct TVProfileView: View {
    let currentUser: User
    @ObservedObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)
                
                Text(currentUser.username)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(currentUser.email ?? "No email")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                        dismiss()
                    }
                } label: {
                    Text("Sign Out")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 900)
                        .frame(height: 100)
                        .background(Color.red)
                        .cornerRadius(16)
                }
                .padding(.bottom, 60)
            }
            .padding()
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
}

// TV-optimized Sign In View
public struct TVSignInView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showManualSignIn = false
    @State private var showRegistration = false
    
    public var body: some View {
        VStack(spacing: 50) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 20) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 120))
                    .foregroundStyle(.blue.gradient)
                
                Text("Layover")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                
                Text("Connect, Watch, Play Together")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)
            
            Spacer()
            
            // Authentication Options
            VStack(spacing: 40) {
                // Sign In with Apple Button
                Button {
                    Task {
                        await viewModel.signInWithApple()
                    }
                } label: {
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
                    .frame(width: 1000)
                    .frame(height: 120)
                    .cornerRadius(16)
                    .allowsHitTesting(false)
                }
                .buttonStyle(.plain)
            
                // Manual Sign In Button
                Button {
                    showManualSignIn = true
                } label: {
                    Text("Sign In with Email")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 1000)
                        .frame(height: 120)
                        .background(Color.green)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow, lineWidth: 8)
                        )
                }
                .buttonStyle(.plain)
            
                // Register Button
                Button {
                    showRegistration = true
                } label: {
                    Text("Create Account")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 1000)
                        .frame(height: 120)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 4)
                        )
                }
                .buttonStyle(.plain)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                        .padding(.top, 20)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .frame(width: 1000)
                        .padding(.top, 20)
                }
            }
            .padding(.bottom, 120)
        }
        .sheet(isPresented: $showManualSignIn) {
            TVManualSignInView(viewModel: viewModel, isPresented: $showManualSignIn)
        }
        .sheet(isPresented: $showRegistration) {
            TVRegistrationView(viewModel: viewModel, isPresented: $showRegistration)
        }
    }
}

// TV-optimized Manual Sign In View
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
            VStack(spacing: 40) {
                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 60)
                
                VStack(spacing: 30) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Email")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(20)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .focused($focusedField, equals: .email)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Password")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .padding(20)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .focused($focusedField, equals: .password)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.title3)
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
                                .scaleEffect(1.5)
                        } else {
                            Text("Sign In")
                                .font(.system(size: 36, weight: .semibold))
                        }
                    }
                    .frame(width: 900)
                    .frame(height: 100)
                    .background(email.isEmpty || password.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(16)
                    .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, 100)
                
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
    }
}

// TV-optimized Registration View
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
                VStack(spacing: 40) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    VStack(spacing: 30) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Username")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            TextField("Choose a username", text: $username)
                                .textContentType(.username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(20)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .focused($focusedField, equals: .username)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Email")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(20)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                                .focused($focusedField, equals: .email)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Password")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            SecureField("Create a password", text: $password)
                                .textContentType(.newPassword)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .focused($focusedField, equals: .password)
                            
                            Text("Must be at least 6 characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Confirm Password")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding(20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                                .font(.title3)
                                .foregroundStyle(.white)
                                .focused($focusedField, equals: .confirmPassword)
                        }
                        
                        if let errorMessage = localErrorMessage ?? viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.title3)
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
                                    .scaleEffect(1.5)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 36, weight: .semibold))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 900)
                        .frame(height: 100)
                        .background(!isFormValid ? Color.blue.opacity(0.5) : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .disabled(!isFormValid || viewModel.isLoading)
                    }
                    .padding(.horizontal, 100)
                    
                    Spacer()
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
}

#Preview {
    ContentView()
}
