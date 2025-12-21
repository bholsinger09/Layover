import Foundation

/// ViewModel for authentication operations
@MainActor
public final class AuthenticationViewModel: ObservableObject {
    
    @Published public private(set) var currentUser: User?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    
    public nonisolated init(authService: AuthenticationServiceProtocol) {
        self.authService = authService
        Task { @MainActor in
            self.currentUser = await authService.currentUser
            self.isAuthenticated = await authService.isAuthenticated
        }
    }
    
    /// Sign in with Apple
    public func signInWithApple() async {
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
    public func signOut() async {
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
    public func checkCredentialState() async {
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
