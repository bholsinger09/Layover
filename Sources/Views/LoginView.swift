import SwiftUI
import AuthenticationServices

/// View for user login
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
        VStack(spacing: 24) {
            // Logo/Header
            VStack(spacing: 8) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("LayoverLounge")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Connect during your layover")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
            
            // Sign in with Apple Button
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.email, .fullName]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
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
            .frame(height: 50)
            .cornerRadius(10)
            
            // Divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
                Text("or")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.secondary.opacity(0.3))
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your email", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    #endif
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField("Enter your password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .cornerRadius(10)
            }
            
            // Error Message
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
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
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(10)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            // Register Link
            Button {
                showRegistration = true
            } label: {
                Text("Don't have an account? **Register**")
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding()
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
}

#Preview {
    LoginView(onSignIn: { _ in })
}
