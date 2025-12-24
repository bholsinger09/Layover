import AVFoundation
import Foundation
import GroupActivities
import OSLog

/// Service for managing SharePlay sessions and coordination
@MainActor
protocol SharePlayServiceProtocol: LayoverService {
    var currentSession: GroupSession<LayoverActivity>? { get }
    var isSessionActive: Bool { get }
    var isSessionHost: Bool { get }
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
    
    // Track if this device initiated the session or joined via invitation
    private(set) var isSessionHost: Bool = false

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
        
        // Only mark as participant if we don't already have a session (i.e., we're not the host)
        if currentSession == nil {
            logger.info("   This device is JOINING an existing session (not the host)")
            isSessionHost = false  // This device joined via invitation
        } else {
            logger.info("   This is our OWN session - already marked as HOST, not changing role")
        }
        
        currentSession = session
        messenger = GroupSessionMessenger(session: session)

        // Automatically join the session
        session.join()
        if isSessionHost {
            logger.info("✅ SharePlay: Host joined own session")
        } else {
            logger.info("✅ SharePlay: Joined session automatically as PARTICIPANT")
        }

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
        logger.info("   This device is STARTING the session (will be the host)")

        let prepareResult = await activity.prepareForActivation()
        logger.info("📋 SharePlay: Preparation result - \(String(describing: prepareResult))")

        switch prepareResult {
        case .activationPreferred:
            logger.info("✅ SharePlay: Activation preferred, activating...")
            isSessionHost = true  // This device initiated the session
            let result = try await activity.activate()
            logger.info(
                "🎉 SharePlay: Activity activated successfully! Result: \(String(describing: result))"
            )
            logger.info("👑 This device is the SESSION HOST")

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
        isSessionHost = false  // Reset host status
        messageTask?.cancel()
        sessionTask?.cancel()
        notifySessionStateObservers(false)
    }

    private func setupMessageListener() {
        logger.info("🔧 Setting up message listener...")
        messageTask = Task {
            guard let messenger = messenger else {
                logger.error("❌ No messenger available for message listener")
                return
            }
            logger.info("✅ Message listener started, waiting for messages...")

            for await (message, _) in messenger.messages(of: SharePlayMessage.self) {
                logger.info("📨 ⚡️ Message received from messenger!")
                await handleMessage(message)
            }
            logger.warning("⚠️ Message listener loop ended")
        }
    }

    private func handleMessage(_ message: SharePlayMessage) async {
        logger.info("📨 ═══════════════════════════════════")
        logger.info("📨 SharePlay: MESSAGE RECEIVED")
        switch message {
        case .roomCreated(let room):
            logger.info("🏠 SharePlay: Room created message - '\(room.name)'")
            logger.info("🏠 Triggering onRoomReceived callback...")
            onRoomReceived?(room)
            logger.info("🏠 onRoomReceived callback completed")
        case .userJoined(let user, let roomID):
            logger.info("👋 SharePlay: User joined message - '\(user.username)'")
            logger.info("👋 Triggering onParticipantJoined callback...")
            onParticipantJoined?(user, roomID)
            logger.info("👋 onParticipantJoined callback completed")
        case .contentSelected(let content):
            logger.info("🎬 ✨ SharePlay: CONTENT SELECTED MESSAGE")
            logger.info("🎬 Content title: \(content.title)")
            logger.info("🎬 Content ID: \(content.contentID)")
            logger.info("🎬 Content type: \(content.contentType.rawValue)")
            logger.info("🎬 onContentReceived callback exists: \(self.onContentReceived != nil)")
            if self.onContentReceived == nil {
                logger.error("❌ WARNING: onContentReceived callback is NIL!")
            } else {
                logger.info("🎬 Triggering onContentReceived callback NOW...")
                self.onContentReceived?(content)
                logger.info("✅ onContentReceived callback invoked")
            }
        }
        logger.info("📨 ═══════════════════════════════════")
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
            logger.warning("⚠️ SharePlay: No messenger available to share user joined")
            return
        }

        do {
            logger.info("📤 SharePlay: Sending user '\(user.username)' joined")
            try await messenger.send(SharePlayMessage.userJoined(user, roomID))
            logger.info("✅ SharePlay: User joined sent successfully")
        } catch {
            logger.error("❌ SharePlay: Failed to share user joined: \(error.localizedDescription)")
        }
    }

    func shareContent(_ content: MediaContent) async {
        logger.info("📤 ═══════════════════════════════════")
        logger.info("📤 shareContent() called")
        logger.info("📤 Content: \(content.title)")

        guard let messenger = messenger else {
            logger.error("❌ SharePlay: No messenger available to share content")
            logger.error("   Current session exists: \(self.currentSession != nil)")
            if let session = self.currentSession {
                logger.error("   Session state: \(String(describing: session.state))")
            } else {
                logger.error("   Session state: no session")
            }
            logger.info("📤 ═══════════════════════════════════")
            return
        }

        do {
            logger.info("📤 SharePlay: Sending content '\(content.title)' to participants")
            logger.info("   Content ID: \(content.contentID)")
            logger.info("   Content type: \(content.contentType == .movie ? "movie" : "show")")
            logger.info("   Sending message now...")
            try await messenger.send(SharePlayMessage.contentSelected(content))
            logger.info("✅ SharePlay: Content message SENT successfully via messenger")
            logger.info("✅ Other participants should receive this message")
        } catch {
            logger.error("❌ SharePlay: Failed to share content: \(error.localizedDescription)")
            logger.error("   Error type: \(type(of: error))")
            logger.error("   Error details: \(String(describing: error))")
        }
        logger.info("📤 ═══════════════════════════════════")
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
