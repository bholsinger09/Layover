import SwiftUI

public struct PlatformSignInView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showManualSignIn = false
    @State private var showRegistration = false

    public init(viewModel: AuthenticationViewModel) {
        self._viewModel = ObservedObject(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                if colorScheme == .dark {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.15),
                            Color.black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                } else {
                    #if os(iOS)
                    Color(.systemBackground).ignoresSafeArea()
                    #else
                    Color(nsColor: .controlBackgroundColor).ignoresSafeArea()
                    #endif
                }

                VStack(spacing: 20) {
                    Spacer()

                    // Logo/Title
                    VStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text("Layover Lounge")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Your Content, Everywhere")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    // Sign in options
                    VStack(spacing: 12) {
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }

                        Button(action: {
                            Task {
                                await viewModel.signInWithApple()
                            }
                        }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Sign in with Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading)

                        Button(action: { showManualSignIn = true }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Sign in with Email")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading)

                        HStack {
                            Text("No account?")
                                .foregroundStyle(.gray)

                            Button("Create one") {
                                showRegistration = true
                            }
                            .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }
                    .padding()

                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.primary)
                            .cornerRadius(8)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationDestination(isPresented: $showManualSignIn) {
                TVManualSignInView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showRegistration) {
                TVRegistrationView(viewModel: viewModel)
            }
        }
    }
}
