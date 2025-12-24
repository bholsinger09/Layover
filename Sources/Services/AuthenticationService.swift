import AuthenticationServices
import Combine
import Foundation
import OSLog

/// Protocol for authentication operations
public protocol AuthenticationServiceProtocol: Sendable {
    var currentUser: User? { get async }
    var isAuthenticated: Bool { get async }

    func signInWithApple() async throws -> User
    func signOut() async throws
}

/// Service for handling Apple Sign In authentication
@MainActor
public final class AuthenticationService: NSObject, AuthenticationServiceProtocol, ObservableObject
{
    private let logger = Logger(
        subsystem: "com.bholsinger.LayoverLounge", category: "AuthenticationService")

    @Published public private(set) var currentUser: User?

    public var isAuthenticated: Bool {
        get async {
            currentUser != nil
        }
    }

    private let userDefaultsKey = "layover.currentUser"

    public override init() {
        super.init()
        loadStoredUser()
    }

    /// Sign in with Apple using ASAuthorization
    public func signInWithApple() async throws -> User {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = SignInDelegate(continuation: continuation, service: self)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()

            // Keep delegate alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// Sign out the current user
    public func signOut() async throws {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    /// Store user to UserDefaults
    func storeUser(_ user: User) {
        currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            logger.info("Stored user: \(user.username)")
        } else {
            logger.error("Failed to encode user for storage")
        }
    }

    /// Load stored user from UserDefaults
    private func loadStoredUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let user = try? JSONDecoder().decode(User.self, from: data)
        else {
            logger.debug("No stored user found or decode failed")
            return
        }
        currentUser = user
        logger.info("Loaded stored user: \(user.username)")
    }

    /// Check credential state for a user
    func checkCredentialState(for userID: String) async
        -> ASAuthorizationAppleIDProvider.CredentialState
    {
        let provider = ASAuthorizationAppleIDProvider()
        return await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: userID) { state, error in
                continuation.resume(returning: state)
            }
        }
    }
}

/// Delegate for handling Sign in with Apple authorization
@MainActor
private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{

    let continuation: CheckedContinuation<User, Error>
    weak var service: AuthenticationService?

    init(continuation: CheckedContinuation<User, Error>, service: AuthenticationService) {
        self.continuation = continuation
        self.service = service
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: AuthenticationError.invalidCredential)
            return
        }

        let userID = credential.user
        let fullName = credential.fullName
        let email = credential.email

        let displayName: String
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        } else if let email = email {
            displayName = email.components(separatedBy: "@").first ?? "User"
        } else {
            displayName = "Apple User"
        }

        let user = User(
            id: UUID(),
            appleUserID: userID,
            username: displayName,
            email: email,
            isHost: false,
            isSubHost: false
        )

        service?.storeUser(user)
        continuation.resume(returning: user)
    }

    func authorizationController(
        controller: ASAuthorizationController, didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation.resume(throwing: AuthenticationError.userCanceled)
            case .failed:
                continuation.resume(throwing: AuthenticationError.authorizationFailed)
            case .invalidResponse:
                continuation.resume(throwing: AuthenticationError.invalidResponse)
            case .notHandled:
                continuation.resume(throwing: AuthenticationError.notHandled)
            case .unknown:
                continuation.resume(throwing: AuthenticationError.unknown)
            default:
                continuation.resume(throwing: AuthenticationError.unknown)
            }
        } else {
            continuation.resume(throwing: error)
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(macOS)
            return NSApplication.shared.windows.first ?? NSWindow()
        #else
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        #endif
    }
}

/// Errors that can occur during authentication
enum AuthenticationError: LocalizedError {
    case invalidCredential
    case userCanceled
    case authorizationFailed
    case invalidResponse
    case notHandled
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credential received from Apple"
        case .userCanceled:
            return "Sign in was canceled"
        case .authorizationFailed:
            return "Authorization failed"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Authorization not handled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
