import SwiftUI

/// Platform-responsive user registration view
public struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onRegister: (String) -> Void

    public init(onRegister: @escaping (String) -> Void) {
        self.onRegister = onRegister
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: contentSpacing) {
                    // Header
                    VStack(spacing: headerSpacing) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: iconSize))
                            .foregroundStyle(.blue)

                        Text("Create Account")
                            .font(titleFont)
                            .fontWeight(.bold)

                        Text("Join LayoverLounge today")
                            .font(subtitleFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, headerBottomPadding)

                    // Username Field
                    VStack(alignment: .leading, spacing: fieldLabelSpacing) {
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
                                .textInputAutocapitalization(.never)
                            #endif
                            .padding(fieldPadding)
                            .background(fieldBackground)
                            .cornerRadius(fieldCornerRadius)
                            .overlay(fieldBorder)
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

                        SecureField("Create a password", text: $password)
                            .textContentType(.newPassword)
                            .padding(fieldPadding)
                            .background(fieldBackground)
                            .cornerRadius(fieldCornerRadius)
                            .overlay(fieldBorder)

                        Text("Must be at least 6 characters")
                            .font(hintFont)
                            .foregroundStyle(.secondary)
                    }

                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: fieldLabelSpacing) {
                        Text("Confirm Password")
                            .font(labelFont)
                            .fontWeight(.medium)

                        SecureField("Confirm your password", text: $confirmPassword)
                            .textContentType(.newPassword)
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

                    // Register Button
                    Button {
                        Task {
                            await register()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(progressScale)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                                .font(buttonFont)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background((isLoading || !isFormValid) ? Color.blue.opacity(0.5) : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(buttonCornerRadius)
                    .disabled(isLoading || !isFormValid)

                    // Terms
                    Text("By registering, you agree to our Terms of Service and Privacy Policy")
                        .font(termsFont)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(contentPadding)
            }
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6
            && password == confirmPassword
    }

    private func register() async {
        isLoading = true
        errorMessage = nil

        // Validate form
        guard username.count >= 2 else {
            errorMessage = "Username must be at least 2 characters"
            isLoading = false
            return
        }

        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            isLoading = false
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }

        // Simulate registration
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
            await MainActor.run {
                dismiss()
            }
            onRegister(username)
        } catch {
            await MainActor.run {
                errorMessage = "Registration failed. Please try again."
                isLoading = false
            }
        }
    }
    
    // Platform-specific styling
    #if os(tvOS)
    private var iconSize: CGFloat { 80 }
    private var titleFont: Font { .system(size: 50, weight: .bold) }
    private var subtitleFont: Font { .title2 }
    private var headerSpacing: CGFloat { 16 }
    private var contentSpacing: CGFloat { 40 }
    private var headerBottomPadding: CGFloat { 30 }
    private var labelFont: Font { .title3 }
    private var fieldLabelSpacing: CGFloat { 12 }
    private var fieldPadding: CGFloat { 20 }
    private var fieldBackground: Color { Color.white.opacity(0.15) }
    private var fieldCornerRadius: CGFloat { 12 }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: fieldCornerRadius)
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
    }
    private var hintFont: Font { .caption }
    private var errorFont: Font { .title3 }
    private var progressScale: CGFloat { 1.5 }
    private var buttonFont: Font { .system(size: 36, weight: .semibold) }
    private var buttonHeight: CGFloat { 100 }
    private var buttonCornerRadius: CGFloat { 16 }
    private var termsFont: Font { .caption }
    private var contentPadding: CGFloat { 80 }
    #elseif os(macOS)
    private var iconSize: CGFloat { 40 }
    private var titleFont: Font { .title }
    private var subtitleFont: Font { .subheadline }
    private var headerSpacing: CGFloat { 8 }
    private var contentSpacing: CGFloat { 20 }
    private var headerBottomPadding: CGFloat { 16 }
    private var labelFont: Font { .subheadline }
    private var fieldLabelSpacing: CGFloat { 6 }
    private var fieldPadding: CGFloat { 10 }
    private var fieldBackground: Color { Color(NSColor.controlBackgroundColor) }
    private var fieldCornerRadius: CGFloat { 8 }
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: fieldCornerRadius)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    private var hintFont: Font { .caption }
    private var errorFont: Font { .caption }
    private var progressScale: CGFloat { 1.0 }
    private var buttonFont: Font { .body }
    private var buttonHeight: CGFloat { 40 }
    private var buttonCornerRadius: CGFloat { 8 }
    private var termsFont: Font { .caption }
    private var contentPadding: CGFloat { 40 }
    #else // iOS
    private var iconSize: CGFloat { 50 }
    private var titleFont: Font { .title }
    private var subtitleFont: Font { .subheadline }
    private var headerSpacing: CGFloat { 8 }
    private var contentSpacing: CGFloat { 24 }
    private var headerBottomPadding: CGFloat { 16 }
    private var labelFont: Font { .subheadline }
    private var fieldLabelSpacing: CGFloat { 8 }
    private var fieldPadding: CGFloat { 16 }
    private var fieldBackground: Color { Color(.systemGray6) }
    private var fieldCornerRadius: CGFloat { 10 }
    private var fieldBorder: some View { EmptyView() }
    private var hintFont: Font { .caption }
    private var errorFont: Font { .caption }
    private var progressScale: CGFloat { 1.0 }
    private var buttonFont: Font { .body }
    private var buttonHeight: CGFloat { 50 }
    private var buttonCornerRadius: CGFloat { 10 }
    private var termsFont: Font { .caption }
    private var contentPadding: CGFloat { 24 }
    #endif
}

#Preview {
    RegistrationView(onRegister: { _ in })
}
