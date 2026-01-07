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
    
    /// Delete the current user's account and all associated data
    public func deleteAccount() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.deleteAccount()
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
    
    /// Check authentication state on app launch
    public func checkAuthenticationState() async {
        // Check if we have a stored user
        if currentUser != nil {
            isAuthenticated = true
            // Optionally check credential state for Apple sign in users
            if currentUser?.appleUserID != nil {
                await checkCredentialState()
            }
        } else {
            isAuthenticated = false
        }
    }
    
    /// Sign in with email and password (demo implementation)
    public func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // For demo purposes, accept any valid email/password
            guard email.contains("@"), !password.isEmpty else {
                throw NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"])
            }
            
            // Extract username from email
            let username = String(email.split(separator: "@").first ?? "User")
            
            // Create user
            let user = User(
                id: UUID(),
                appleUserID: nil,
                username: username,
                email: email,
                isHost: false,
                isSubHost: false
            )
            
            // Store user
            if let authService = authService as? AuthenticationService {
                authService.storeUser(user)
            }
            
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Register new user (demo implementation)
    public func register(username: String, email: String, password: String) async {
        print("🔵 AuthViewModel: Starting registration for \(username)")
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate input
            guard username.count >= 2 else {
                throw NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Username must be at least 2 characters"])
            }
            
            guard email.contains("@") else {
                throw NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email address"])
            }
            
            guard password.count >= 6 else {
                throw NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters"])
            }
            
            // Create user
            let user = User(
                id: UUID(),
                appleUserID: nil,
                username: username,
                email: email,
                isHost: false,
                isSubHost: false
            )
            
            print("🔵 AuthViewModel: User object created")
            
            // Store user
            if let authService = authService as? AuthenticationService {
                authService.storeUser(user)
                print("🔵 AuthViewModel: User stored")
            }
            
            currentUser = user
            isAuthenticated = true
            print("🔵 AuthViewModel: Set currentUser and isAuthenticated=true")
            print("🔵 AuthViewModel: currentUser is now \(currentUser?.username ?? "nil")")
            print("🔵 AuthViewModel: isAuthenticated is now \(isAuthenticated)")
        } catch {
            print("❌ AuthViewModel: Registration error - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        print("🔵 AuthViewModel: Registration complete")
    }
}
