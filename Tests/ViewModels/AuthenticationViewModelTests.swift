import Testing
import Foundation
@testable import LayoverKit

/// Tests for AuthenticationViewModel
@Suite("Authentication ViewModel Tests")
@MainActor
struct AuthenticationViewModelTests {
    
    @Test("Initialize view model")
    func testInitialization() {
        let viewModel = AuthenticationViewModel(authService: MockAuthenticationService())
        
        #expect(viewModel.currentUser == nil)
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Sign in with Apple")
    func testSignInWithApple() async {
        let mockService = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(authService: mockService)
        
        await viewModel.signInWithApple()
        
        #expect(viewModel.currentUser != nil)
        #expect(viewModel.isAuthenticated == true)
        #expect(viewModel.currentUser?.username == "Test User")
    }
    
    @Test("Sign out")
    func testSignOut() async {
        let mockService = MockAuthenticationService()
        let viewModel = AuthenticationViewModel(authService: mockService)
        
        // First sign in
        await viewModel.signInWithApple()
        #expect(viewModel.isAuthenticated == true)
        
        // Then sign out
        await viewModel.signOut()
        #expect(viewModel.currentUser == nil)
        #expect(viewModel.isAuthenticated == false)
    }
    
    @Test("Handle sign in error")
    func testSignInError() async {
        let mockService = MockAuthenticationService(shouldFail: true)
        let viewModel = AuthenticationViewModel(authService: mockService)
        
        await viewModel.signInWithApple()
        
        #expect(viewModel.currentUser == nil)
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.errorMessage != nil)
    }
}

/// Mock authentication service for testing
@MainActor
class MockAuthenticationService: AuthenticationServiceProtocol {
    private(set) var _currentUser: User?
    private let shouldFail: Bool
    
    var currentUser: User? {
        get async { _currentUser }
    }
    
    var isAuthenticated: Bool {
        get async { _currentUser != nil }
    }
    
    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    func signInWithApple() async throws -> User {
        if shouldFail {
            throw AuthenticationError.authorizationFailed
        }
        
        let user = User(
            id: UUID(),
            appleUserID: "test.user.id",
            username: "Test User",
            email: "test@example.com",
            isHost: false,
            isSubHost: false
        )
        _currentUser = user
        return user
    }
    
    func signOut() async throws {
        _currentUser = nil
    }
}
