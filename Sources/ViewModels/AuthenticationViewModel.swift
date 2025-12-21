import Foundation

/// ViewModel for authentication operations
@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    
    nonisolated init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        Task { @MainActor in
            self.currentUser = await authService.currentUser
            self.isAuthenticated = await authService.isAuthenticated
        }
    }
    
    /// Sign in with Apple
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signInWithApple()
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Sign out the current user
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Check if credentials are still valid
    func checkCredentialState() async {
        guard let userID = currentUser?.appleUserID else { return }
        
        if let authService = authService as? AuthenticationService {
            let state = await authService.checkCredentialState(for: userID)
            
            switch state {
            case .revoked, .notFound:
                // User credentials are no longer valid
                await signOut()
            case .authorized:
                // Credentials are still valid
                break
            case .transferred:
                // Handle credential transfer
                break
            @unknown default:
                break
            }
        }
    }
}
