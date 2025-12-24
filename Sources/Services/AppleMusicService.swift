import Foundation
import MusicKit
import OSLog

/// Service for managing Apple Music playback
@MainActor
protocol AppleMusicServiceProtocol: LayoverService {
    var currentContent: MediaContent? { get }
    var isAuthorized: Bool { get async }

    func requestAuthorization() async throws
    func loadContent(_ content: MediaContent) async throws
    func play() async
    func pause() async
}

@MainActor
final class AppleMusicService: AppleMusicServiceProtocol {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "AppleMusicService")
    private(set) var currentContent: MediaContent?
    private let musicPlayer = ApplicationMusicPlayer.shared

    var isAuthorized: Bool {
        get async {
            let status = await MusicAuthorization.currentStatus
            return status == .authorized
        }
    }

    func requestAuthorization() async throws {
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            throw MusicError.authorizationDenied
        }
    }

    func loadContent(_ content: MediaContent) async throws {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }

        // In a real app, this would use MusicKit to load the actual content
        self.currentContent = content
    }

    func play() async {
        do {
            try await musicPlayer.play()
        } catch {
            logger.error("Failed to play music: \(error.localizedDescription)")
        }
    }

    func pause() async {
        musicPlayer.pause()
    }
}

enum MusicError: LocalizedError {
    case notAuthorized
    case authorizationDenied
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Music authorization required"
        case .authorizationDenied:
            return "Music authorization was denied"
        case .loadFailed:
            return "Failed to load music content"
        }
    }
}
