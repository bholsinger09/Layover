import AuthenticationServices
import SwiftUI

/// Platform-responsive Sign in with Apple view
public struct SignInView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: AuthenticationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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
            .padding(.bottom, titleBottomPadding)

            Spacer()

            // Sign In with Apple Button
            VStack(spacing: contentSpacing) {
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

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(progressScale)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(errorFont)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, bottomPadding)
        }
        .padding()
    }
    
    // Platform-specific sizing
    #if os(tvOS)
    private var logoSize: CGFloat { 120 }
    private var titleSize: CGFloat { 72 }
    private var subtitleFont: Font { .title }
    private var titleSpacing: CGFloat { 20 }
    private var platformSpacing: CGFloat { 50 }
    private var titleBottomPadding: CGFloat { 40 }
    private var contentSpacing: CGFloat { 30 }
    private var buttonMaxWidth: CGFloat { 1000 }
    private var buttonHeight: CGFloat { 120 }
    private var buttonCornerRadius: CGFloat { 16 }
    private var progressScale: CGFloat { 2.0 }
    private var errorFont: Font { .title3 }
    private var horizontalPadding: CGFloat { 0 }
    private var bottomPadding: CGFloat { 120 }
    #elseif os(macOS)
    private var logoSize: CGFloat { 60 }
    private var titleSize: CGFloat { 42 }
    private var subtitleFont: Font { .title3 }
    private var titleSpacing: CGFloat { 12 }
    private var platformSpacing: CGFloat { 30 }
    private var titleBottomPadding: CGFloat { 30 }
    private var contentSpacing: CGFloat { 20 }
    private var buttonMaxWidth: CGFloat { 400 }
    private var buttonHeight: CGFloat { 50 }
    private var buttonCornerRadius: CGFloat { 10 }
    private var progressScale: CGFloat { 1.0 }
    private var errorFont: Font { .callout }
    private var horizontalPadding: CGFloat { 40 }
    private var bottomPadding: CGFloat { 40 }
    #else // iOS
    private var logoSize: CGFloat { 80 }
    private var titleSize: CGFloat { 48 }
    private var subtitleFont: Font { .title3 }
    private var titleSpacing: CGFloat { 16 }
    private var platformSpacing: CGFloat { 30 }
    private var titleBottomPadding: CGFloat { 40 }
    private var contentSpacing: CGFloat { 20 }
    private var buttonMaxWidth: CGFloat { .infinity }
    private var buttonHeight: CGFloat { 50 }
    private var buttonCornerRadius: CGFloat { 8 }
    private var progressScale: CGFloat { 1.0 }
    private var errorFont: Font { .callout }
    private var horizontalPadding: CGFloat { 40 }
    private var bottomPadding: CGFloat { 60 }
    #endif
}

#Preview {
    SignInView(viewModel: AuthenticationViewModel(authService: AuthenticationService()))
}
