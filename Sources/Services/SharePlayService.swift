import Foundation
import AVFoundation
import GroupActivities

/// Service for managing SharePlay sessions and coordination
@MainActor
protocol SharePlayServiceProtocol: LayoverService {
    var currentSession: GroupSession<LayoverActivity>? { get }
    var isSessionActive: Bool { get }
    
    func startActivity(_ activity: LayoverActivity) async throws
    func leaveSession() async
    func setupPlaybackCoordinator(player: AVPlayer) async throws
}

@MainActor
final class SharePlayService: SharePlayServiceProtocol {
    private(set) var currentSession: GroupSession<LayoverActivity>?
    private var groupStateObserver: Task<Void, Never>?
    private var sessionTask: Task<Void, Never>?
    private var playbackCoordinator: AVPlaybackCoordinator?
    
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
        
        session.join()
        
        sessionTask = Task {
            for await state in session.$state.values {
                if case .invalidated = state {
                    currentSession = nil
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
        playbackCoordinator = nil
        sessionTask?.cancel()
    }
    
    func setupPlaybackCoordinator(player: AVPlayer) async throws {
        guard let session = currentSession else {
            throw SharePlayError.noActiveSession
        }
        
        guard let coordinator = player.playbackCoordinator as? AVPlayerPlaybackCoordinator else {
            throw SharePlayError.unknown
        }
        coordinator.coordinateWithSession(session)
        self.playbackCoordinator = coordinator
    }
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
