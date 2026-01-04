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
        VStack(spacing: contentSpacing) {
            // Logo/Header
            VStack(spacing: headerSpacing) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: logoSize))
                    .foregroundStyle(.blue)

                Text("LayoverLounge")
                    .font(titleFont)
                    .fontWeight(.bold)

                Text("Connect during your layover")
                    .font(subtitleFont)
                    .foregroundStyle(.secondary)
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

            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("or")
                    .font(dividerFont)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
            }

            // Email Field
            VStack(alignment: .leading, spacing: fieldLabelSpacing) {
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
                        .textInputAutocapitalization(.never)
                    #endif
                    .padding(fieldPadding)
                    .background(fieldBackground)
                    .cornerRadius(fieldCornerRadius)
                    .overlay(fieldBorder)
            }

            // Password Field
            VStack(alignment: .leading, spacing: fieldLabelSpacing) {
                Text("Password")
                    .font(labelFont)
                    .fontWeight(.medium)

                SecureField("Enter your password", text: $password)
                    .textContentType(.password)
                    .padding(fieldPadding)
                    .background(fieldBackground)
                    .cornerRadius(fieldCornerRadius)
                    .overlay(fieldBorder)
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
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(actionButtonCornerRadius)
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            // Register Link
            Button {
                showRegistration = true
            } label: {
                Text("Don't have an account? **Register**")
                    .font(registerLinkFont)
            }

            Spacer()
        }
        .padding(contentPadding)
        .sheet(isPresented: $showRegistration) {
            RegistrationView(onRegister: onSignIn)
        }
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil

        // Simulate authentication
        do {
            // Check reviewer credentials
            if email == "reviewer@layoverlounge.app" && password == "TestFlight2025!" {
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
    private var fieldBackground: Color { Color.white.opacity(0.15) }
    private var fieldCornerRadius: CGFloat { 12 }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: fieldCornerRadius)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
    }
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
    private var fieldBackground: Color { Color(NSColor.controlBackgroundColor) }
    private var fieldCornerRadius: CGFloat { 8 }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: fieldCornerRadius)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
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
    private var fieldBackground: Color { Color(.systemGray6) }
    private var fieldCornerRadius: CGFloat { 10 }
    private var fieldBorder: some View { EmptyView() }
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
