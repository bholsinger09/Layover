import SwiftUI
public struct TVRegistrationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""

    public init(viewModel: AuthenticationViewModel) {
        self._viewModel = ObservedObject(initialValue: viewModel)
    }
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
                        dismiss()
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
            dismiss()
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
