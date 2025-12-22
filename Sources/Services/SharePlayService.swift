import AVFoundation
import Foundation
import GroupActivities

/// Service for managing SharePlay sessions and coordination
@MainActor
protocol SharePlayServiceProtocol: LayoverService {
    var currentSession: GroupSession<LayoverActivity>? { get }
    var isSessionActive: Bool { get }
    var onRoomReceived: ((Room) -> Void)? { get set }
    var onParticipantJoined: ((User, UUID) -> Void)? { get set }

    func startActivity(_ activity: LayoverActivity) async throws
    func leaveSession() async
    func setupPlaybackCoordinator(player: AVPlayer) async throws
    func shareRoom(_ room: Room) async
    func shareUserJoined(_ user: User, roomID: UUID) async
}

@MainActor
final class SharePlayService: SharePlayServiceProtocol {
    private(set) var currentSession: GroupSession<LayoverActivity>?
    private var groupStateObserver: Task<Void, Never>?
    private var sessionTask: Task<Void, Never>?
    private var playbackCoordinator: AVPlaybackCoordinator?
    private var messenger: GroupSessionMessenger?
    private var messageTask: Task<Void, Never>?

    var onRoomReceived: ((Room) -> Void)?
    var onParticipantJoined: ((User, UUID) -> Void)?

    var isSessionActive: Bool {
        currentSession != nil
    }

    init() {
        setupSessionObserver()
    }

    deinit {
        groupStateObserver?.cancel()
        sessionTask?.cancel()
    }

    private func setupSessionObserver() {
        groupStateObserver = Task {
            for await session in LayoverActivity.sessions() {
                await handleSession(session)
            }
        }
    }

    private func handleSession(_ session: GroupSession<LayoverActivity>) async {
        print("🔗 SharePlay: Session received!")
        currentSession = session
        messenger = GroupSessionMessenger(session: session)

        // Automatically join the session
        session.join()
        print("✅ SharePlay: Joined session automatically")

        // Setup message listener
        setupMessageListener()

        sessionTask = Task {
            for await state in session.$state.values {
                print("📊 SharePlay: Session state changed to \(state)")
                if case .invalidated = state {
                    currentSession = nil
                    messenger = nil
                    messageTask?.cancel()
                    sessionTask?.cancel()
                    print("❌ SharePlay: Session invalidated")
                }
            }
        }
    }

    func startActivity(_ activity: LayoverActivity) async throws {
        print("🎬 SharePlay: Preparing activity for '\(activity.metadata.title)'")

        let prepareResult = await activity.prepareForActivation()
        print("📋 SharePlay: Preparation result - \(prepareResult)")

        switch prepareResult {
        case .activationPreferred:
            print("✅ SharePlay: Activation preferred, activating...")
            let result = try await activity.activate()
            print("🎉 SharePlay: Activity activated successfully! Result: \(result)")

            // Wait a moment for session to establish
            try? await Task.sleep(nanoseconds: 500_000_000)

            if currentSession != nil {
                print("✅ SharePlay: Session is now active")
            } else {
                print("⚠️ SharePlay: Activity activated but session not yet established")
            }

        case .activationDisabled:
            print("❌ SharePlay: Activation disabled - not in FaceTime call?")
            throw SharePlayError.activationDisabled
        case .cancelled:
            print("🚫 SharePlay: Activation cancelled by user")
            throw SharePlayError.cancelled
        @unknown default:
            print("❓ SharePlay: Unknown activation result")
            throw SharePlayError.unknown
        }
    }

    func leaveSession() async {
        currentSession?.leave()
        currentSession = nil
        messenger = nil
        playbackCoordinator = nil
        messageTask?.cancel()
        sessionTask?.cancel()
    }

    private func setupMessageListener() {
        messageTask = Task {
            guard let messenger = messenger else { return }

            do {
                for try await (message, _) in messenger.messages(of: SharePlayMessage.self) {
                    await handleMessage(message)
                }
            } catch {
                print("SharePlay message error: \(error)")
            }
        }
    }

    private func handleMessage(_ message: SharePlayMessage) async {
        print("📨 SharePlay: Received message")
        switch message {
        case .roomCreated(let room):
            print("🏠 SharePlay: Room created message - '\(room.name)'")
            onRoomReceived?(room)
        case .userJoined(let user, let roomID):
            print("👋 SharePlay: User joined message - '\(user.username)'")
            onParticipantJoined?(user, roomID)
        }
    }

    func shareRoom(_ room: Room) async {
        guard let messenger = messenger else {
            print("⚠️ SharePlay: No messenger available to share room")
            return
        }

        do {
            print("📤 SharePlay: Sending room '\(room.name)' to participants")
            try await messenger.send(SharePlayMessage.roomCreated(room))
            print("✅ SharePlay: Room sent successfully")
        } catch {
            print("❌ SharePlay: Failed to share room: \(error)")
        }
    }

    func shareUserJoined(_ user: User, roomID: UUID) async {
        guard let messenger = messenger else {
            print("⚠️ SharePlay: No messenger available to share user joined")
            return
        }

        do {
            print("📤 SharePlay: Sending user '\(user.username)' joined")
            try await messenger.send(SharePlayMessage.userJoined(user, roomID))
            print("✅ SharePlay: User joined sent successfully")
        } catch {
            print("❌ SharePlay: Failed to share user joined: \(error)")
        }
    }

    func setupPlaybackCoordinator(player: AVPlayer) async throws {
        guard let session = currentSession else {
            throw SharePlayError.noActiveSession
        }

        let coordinator = player.playbackCoordinator
        coordinator.coordinateWithSession(session)
        self.playbackCoordinator = coordinator
    }
}

enum SharePlayMessage: Codable {
    case roomCreated(Room)
    case userJoined(User, UUID)
}

enum SharePlayError: LocalizedError {
    case activationDisabled
    case cancelled
    case noActiveSession
    case unknown

    var errorDescription: String? {
        switch self {
        case .activationDisabled:
            return "SharePlay is not available. Make sure you're in an active FaceTime call."
        case .cancelled:
            return "SharePlay activation was cancelled"
        case .noActiveSession:
            return "No active SharePlay session"
        case .unknown:
            return "An unknown SharePlay error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .activationDisabled:
            return "Start or join a FaceTime call first, then try SharePlay again."
        case .cancelled:
            return "Try starting SharePlay again."
        case .noActiveSession:
            return "Start a SharePlay session first."
        case .unknown:
            return "Please try again."
        }
    }
}
