import SwiftUI
import AuthenticationServices

/// View for Sign in with Apple
public struct SignInView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    public init(viewModel: AuthenticationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                Text("Layover")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                
                Text("Connect, Watch, Play Together")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 40)
            
            Spacer()
            
            // Sign In with Apple Button
            VStack(spacing: 20) {
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
                .frame(height: 50)
                .cornerRadius(8)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .padding()
    }
}

#Preview {
    SignInView(viewModel: AuthenticationViewModel(authService: AuthenticationService()))
}
