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
        NavigationStack {
            VStack(spacing: 0) {
                #if os(tvOS)
                tvTopBar(currentUser: currentUser)
                #elseif os(macOS)
                macTopBar(currentUser: currentUser)
                #else
                iOSTopBar(currentUser: currentUser)
                #endif
                
                // Chess game view
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
                #if os(tvOS)
                .focusSection()
                #endif
            }
            .background(
                Image("airport-lounge")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            )
            .navigationTitle("LayoverLounge")
            .sheet(isPresented: $showingLibrary) {
                LibraryView(libraryService: libraryService)
            }
            .sheet(isPresented: $showingProfile) {
                TVProfileView(
                    currentUser: currentUser,
                    authViewModel: authViewModel
                )
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
                        .foregroundStyle(.white)
                    Text(currentUser.username)
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
            
            // My Library Button
            Button {
                showingLibrary = true
            } label: {
                Label("My Library", systemImage: "books.vertical")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.75))
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
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
        .focusSection()
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
            
            // My Library Button
            Button {
                showingLibrary = true
            } label: {
                Label("My Library", systemImage: "books.vertical")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
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
