import AVFoundation
import Foundation
import GroupActivities
import OSLog

/// Service for managing SharePlay sessions and coordination
@MainActor
protocol SharePlayServiceProtocol: LayoverService {
    var currentSession: GroupSession<LayoverActivity>? { get }
    var isSessionActive: Bool { get }
    var onRoomReceived: ((Room) -> Void)? { get set }
    var onParticipantJoined: ((User, UUID) -> Void)? { get set }
    var onContentReceived: ((MediaContent) -> Void)? { get set }
    
    func addSessionStateObserver(_ observer: @escaping (Bool) -> Void)
    func startActivity(_ activity: LayoverActivity) async throws
    func leaveSession() async
    func setupPlaybackCoordinator(player: AVPlayer) async throws
    func shareRoom(_ room: Room) async
    func shareUserJoined(_ user: User, roomID: UUID) async
    func shareContent(_ content: MediaContent) async
}

@MainActor
final class SharePlayService: SharePlayServiceProtocol {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "SharePlay")
    
    private(set) var currentSession: GroupSession<LayoverActivity>?
    private var groupStateObserver: Task<Void, Never>?
    private var sessionTask: Task<Void, Never>?
    private var playbackCoordinator: AVPlaybackCoordinator?
    private var messenger: GroupSessionMessenger?
    private var messageTask: Task<Void, Never>?

    var onRoomReceived: ((Room) -> Void)?
    var onParticipantJoined: ((User, UUID) -> Void)?
    var onContentReceived: ((MediaContent) -> Void)?
    private var sessionStateObservers: [(Bool) -> Void] = []
    
    func addSessionStateObserver(_ observer: @escaping (Bool) -> Void) {
        sessionStateObservers.append(observer)
        // Immediately call with current state
        observer(isSessionActive)
    }
    
    private func notifySessionStateObservers(_ isActive: Bool) {
        for observer in sessionStateObservers {
            observer(isActive)
        }
    }
    
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
        logger.info("🔗 SharePlay: Session received!")
        currentSession = session
        messenger = GroupSessionMessenger(session: session)

        // Automatically join the session
        session.join()
        logger.info("✅ SharePlay: Joined session automatically")
        
        // Notify that session is now active - ensure callback runs on MainActor
        await MainActor.run {
            logger.info("📢 SharePlay: Notifying UI of session state change (active)")
            notifySessionStateObservers(true)
        }

        // Setup message listener
        setupMessageListener()

        sessionTask = Task {
            for await state in session.$state.values {
                logger.info("📊 SharePlay: Session state changed to \(String(describing: state))")
                if case .invalidated = state {
                    currentSession = nil
                    messenger = nil
                    messageTask?.cancel()
                    sessionTask?.cancel()
                    logger.warning("❌ SharePlay: Session invalidated")
                    await MainActor.run {
                        logger.info("📢 SharePlay: Notifying UI of session state change (inactive)")
                        notifySessionStateObservers(false)
                    }
                }
            }
        }
    }

    func startActivity(_ activity: LayoverActivity) async throws {
        logger.info("🎬 SharePlay: Preparing activity for '\(activity.metadata.title ?? "unknown")'")

        let prepareResult = await activity.prepareForActivation()
        logger.info("📋 SharePlay: Preparation result - \(String(describing: prepareResult))")

        switch prepareResult {
        case .activationPreferred:
            logger.info("✅ SharePlay: Activation preferred, activating...")
            let result = try await activity.activate()
            logger.info("🎉 SharePlay: Activity activated successfully! Result: \(String(describing: result))")

            // Wait a moment for session to establish
            try? await Task.sleep(nanoseconds: 500_000_000)

            if currentSession != nil {
                logger.info("✅ SharePlay: Session is now active")
            } else {
                logger.warning("⚠️ SharePlay: Activity activated but session not yet established")
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
        notifySessionStateObservers(false)
    }

    private func setupMessageListener() {
        messageTask = Task {
            guard let messenger = messenger else { return }

            for await (message, _) in messenger.messages(of: SharePlayMessage.self) {
                await handleMessage(message)
            }
        }
    }

    private func handleMessage(_ message: SharePlayMessage) async {
        logger.info("📨 SharePlay: Received message")
        switch message {
        case .roomCreated(let room):
            logger.info("🏠 SharePlay: Room created message - '\(room.name)'")
            onRoomReceived?(room)
        case .userJoined(let user, let roomID):
            logger.info("👋 SharePlay: User joined message - '\(user.username)'")
            onParticipantJoined?(user, roomID)
        case .contentSelected(let content):
            logger.info("🎬 SharePlay: Content selected message - '\(content.title)'")
            logger.info("🎬 Content ID: \(content.contentID)")
            logger.info("🎬 Triggering onContentReceived callback...")
            onContentReceived?(content)
            logger.info("🎬 Callback triggered")
        }
    }

    func shareRoom(_ room: Room) async {
        guard let messenger = messenger else {
            logger.warning("⚠️ SharePlay: No messenger available to share room")
            logger.info("   Current session exists: \(self.currentSession != nil)")
            return
        }

        do {
            logger.info("📤 SharePlay: Sending room '\(room.name)' to participants")
            logger.info("   Room ID: \(room.id)")
            logger.info("   Activity type: \(room.activityType.rawValue)")
            try await messenger.send(SharePlayMessage.roomCreated(room))
            logger.info("✅ SharePlay: Room sent successfully via messenger")
        } catch {
            logger.error("❌ SharePlay: Failed to share room: \(error.localizedDescription)")
            logger.error("   Error details: \(String(describing: error))")
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
    
    func shareContent(_ content: MediaContent) async {
        guard let messenger = messenger else {
            logger.warning("⚠️ SharePlay: No messenger available to share content")
            logger.info("   Current session: \(self.currentSession != nil ? "EXISTS" : "NIL")")
            return
        }

        do {
            logger.info("📤 SharePlay: Sending content '\(content.title)' to participants")
            logger.info("   Content ID: \(content.contentID)")
            logger.info("   Content type: \(content.contentType == .movie ? "movie" : "show")")
            try await messenger.send(SharePlayMessage.contentSelected(content))
            logger.info("✅ SharePlay: Content sent successfully via messenger")
        } catch {
            logger.error("❌ SharePlay: Failed to share content: \(error.localizedDescription)")
            logger.error("   Error details: \(String(describing: error))")
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
    case contentSelected(MediaContent)
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
