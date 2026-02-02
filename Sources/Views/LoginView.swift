import AuthenticationServices
import SwiftUI

/// Platform-responsive user login view
public struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegistration = false

    let onSignIn: (String) -> Void

    public init(onSignIn: @escaping (String) -> Void) {
        self.onSignIn = onSignIn
    }

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
            
            VStack(spacing: contentSpacing) {
                // Logo/Header
                VStack(spacing: headerSpacing) {
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

                    Text("Social Sync Lounge")
                        .font(titleFont)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)

                    Text("Synchronized Social Entertainment")
                        .font(subtitleFont)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("Where Distance Disappears")
                        .font(.caption)
                        .foregroundStyle(.cyan.opacity(0.8))
                }
                .padding(.bottom, headerBottomPadding)

            // Sign in with Apple Button
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.email, .fullName]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let credential = authorization.credential
                            as? ASAuthorizationAppleIDCredential
                        {
                            let username = credential.fullName?.givenName ?? "Apple User"
                            onSignIn(username)
                        } else {
                            onSignIn("Apple User")
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            )
            .frame(maxWidth: signInButtonMaxWidth)
            .frame(height: signInButtonHeight)
            .cornerRadius(signInButtonCornerRadius)
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)

            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.3))
                Text("or")
                    .font(dividerFont)
                    .foregroundStyle(.white.opacity(0.6))
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.white.opacity(0.3))
            }

            // Email Field
            VStack(alignment: .leading, spacing: fieldLabelSpacing) {
                Text("Email")
                    .font(labelFont)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))

                TextField("Enter your email", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    #endif
                    #if os(macOS)
                        .autocorrectionDisabled()
                    #elseif os(tvOS)
                        .autocorrectionDisabled()
                    #endif
                    .padding(fieldPadding)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .cornerRadius(fieldCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: fieldCornerRadius)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Password Field
            VStack(alignment: .leading, spacing: fieldLabelSpacing) {
                Text("Password")
                    .font(labelFont)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))

                SecureField("Enter your password", text: $password)
                    .textContentType(.password)
                    .padding(fieldPadding)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .cornerRadius(fieldCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: fieldCornerRadius)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            // Error Message
            if let errorMessage {
                Text(errorMessage)
                    .font(errorFont)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            // Sign In Button
            Button {
                Task {
                    await signIn()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(progressScale)
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .font(buttonFont)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: actionButtonHeight)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.cyan.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .cornerRadius(actionButtonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: actionButtonCornerRadius)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .blue.opacity(0.5), radius: 8, x: 0, y: 4)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.5 : 1.0)

            // Register Link
            Button {
                showRegistration = true
            } label: {
                Text("Don't have an account? **Register**")
                    .font(registerLinkFont)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(contentPadding)
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView(onRegister: onSignIn)
        }
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        // Simulate authentication
        do {
            // Check reviewer credentials (updated for Social Sync Lounge)
            if email == "reviewer@socialsynclounge.app" && password == "SyncDemo2025!" {
                try await Task.sleep(nanoseconds: 500_000_000)
                onSignIn("Reviewer")
                return
            }

            // For demo, accept any email/password
            guard email.contains("@"), !password.isEmpty else {
                errorMessage = "Please enter valid credentials"
                isLoading = false
                return
            }

            // Extract username from email (part before @)
            let username = String(email.split(separator: "@").first ?? "User")

            try await Task.sleep(nanoseconds: 500_000_000)
            onSignIn(username)
        } catch {
            errorMessage = "Sign in failed. Please try again."
            isLoading = false
        }
    }
    
    // Platform-specific styling
    #if os(tvOS)
    private var logoSize: CGFloat { 100 }
    private var titleFont: Font { .system(size: 60, weight: .bold) }
    private var subtitleFont: Font { .title2 }
    private var headerSpacing: CGFloat { 16 }
    private var contentSpacing: CGFloat { 40 }
    private var headerBottomPadding: CGFloat { 60 }
    private var signInButtonMaxWidth: CGFloat { 1000 }
    private var signInButtonHeight: CGFloat { 120 }
    private var signInButtonCornerRadius: CGFloat { 16 }
    private var dividerFont: Font { .title3 }
    private var labelFont: Font { .title3 }
    private var fieldLabelSpacing: CGFloat { 12 }
    private var fieldPadding: CGFloat { 20 }
    private var fieldCornerRadius: CGFloat { 12 }
    private var errorFont: Font { .title3 }
    private var progressScale: CGFloat { 1.5 }
    private var buttonFont: Font { .system(size: 36, weight: .semibold) }
    private var actionButtonHeight: CGFloat { 100 }
    private var actionButtonCornerRadius: CGFloat { 16 }
    private var registerLinkFont: Font { .title3 }
    private var contentPadding: CGFloat { 80 }
    #elseif os(macOS)
    private var logoSize: CGFloat { 50 }
    private var titleFont: Font { .title }
    private var subtitleFont: Font { .subheadline }
    private var headerSpacing: CGFloat { 8 }
    private var contentSpacing: CGFloat { 20 }
    private var headerBottomPadding: CGFloat { 28 }
    private var signInButtonMaxWidth: CGFloat { .infinity }
    private var signInButtonHeight: CGFloat { 44 }
    private var signInButtonCornerRadius: CGFloat { 8 }
    private var dividerFont: Font { .subheadline }
    private var labelFont: Font { .subheadline }
    private var fieldLabelSpacing: CGFloat { 6 }
    private var fieldPadding: CGFloat { 10 }
    private var fieldCornerRadius: CGFloat { 8 }
    private var errorFont: Font { .caption }
    private var progressScale: CGFloat { 1.0 }
    private var buttonFont: Font { .body }
    private var actionButtonHeight: CGFloat { 40 }
    private var actionButtonCornerRadius: CGFloat { 8 }
    private var registerLinkFont: Font { .subheadline }
    private var contentPadding: CGFloat { 40 }
    #else // iOS
    private var logoSize: CGFloat { 60 }
    private var titleFont: Font { .largeTitle }
    private var subtitleFont: Font { .subheadline }
    private var headerSpacing: CGFloat { 8 }
    private var contentSpacing: CGFloat { 24 }
    private var headerBottomPadding: CGFloat { 32 }
    private var signInButtonMaxWidth: CGFloat { .infinity }
    private var signInButtonHeight: CGFloat { 50 }
    private var signInButtonCornerRadius: CGFloat { 10 }
    private var dividerFont: Font { .subheadline }
    private var labelFont: Font { .subheadline }
    private var fieldLabelSpacing: CGFloat { 8 }
    private var fieldPadding: CGFloat { 16 }
    private var fieldCornerRadius: CGFloat { 10 }
    private var errorFont: Font { .caption }
    private var progressScale: CGFloat { 1.0 }
    private var buttonFont: Font { .body }
    private var actionButtonHeight: CGFloat { 50 }
    private var actionButtonCornerRadius: CGFloat { 10 }
    private var registerLinkFont: Font { .subheadline }
    private var contentPadding: CGFloat { 24 }
    #endif
}

#Preview {
    LoginView(onSignIn: { _ in })
}
