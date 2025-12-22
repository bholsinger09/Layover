import Foundation
import AVFoundation
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
        currentSession = session
        messenger = GroupSessionMessenger(session: session)
        
        session.join()
        
        // Setup message listener
        setupMessageListener()
        
        sessionTask = Task {
            for await state in session.$state.values {
                if case .invalidated = state {
                    currentSession = nil
                    messenger = nil
                    messageTask?.cancel()
                    sessionTask?.cancel()
                }
            }
        }
    }
    
    func startActivity(_ activity: LayoverActivity) async throws {
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            _ = try await activity.activate()
        case .activationDisabled:
            throw SharePlayError.activationDisabled
        case .cancelled:
            throw SharePlayError.cancelled
        @unknown default:
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
        switch message {
        case .roomCreated(let room):
            onRoomReceived?(room)
        case .userJoined(let user, let roomID):
            onParticipantJoined?(user, roomID)
        }
    }
    
    func shareRoom(_ room: Room) async {
        guard let messenger = messenger else { return }
        
        do {
            try await messenger.send(SharePlayMessage.roomCreated(room))
        } catch {
            print("Failed to share room: \(error)")
        }
    }
    
    func shareUserJoined(_ user: User, roomID: UUID) async {
        guard let messenger = messenger else { return }
        
        do {
            try await messenger.send(SharePlayMessage.userJoined(user, roomID))
        } catch {
            print("Failed to share user joined: \(error)")
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
            return "SharePlay activation is disabled"
        case .cancelled:
            return "SharePlay activation was cancelled"
        case .noActiveSession:
            return "No active SharePlay session"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
