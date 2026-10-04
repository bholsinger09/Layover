import SwiftUI

public struct TVManualSignInView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    public enum Field {
        case email, password
    }

    public init(viewModel: AuthenticationViewModel) {
        self._viewModel = ObservedObject(initialValue: viewModel)
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
                    dismiss()
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
                    dismiss()
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
                        dismiss()
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
