import Foundation
import AVFoundation

/// Service for managing Apple TV+ playback
@MainActor
protocol AppleTVServiceProtocol: LayoverService {
    var currentContent: MediaContent? { get }
    var player: AVPlayer? { get }
    
    func loadContent(_ content: MediaContent) async throws
    func play() async
    func pause() async
    func seek(to time: TimeInterval) async
}

@MainActor
final class AppleTVService: AppleTVServiceProtocol {
    private(set) var currentContent: MediaContent?
    private(set) var player: AVPlayer?
    
    func loadContent(_ content: MediaContent) async throws {
        // In a real app, this would integrate with Apple TV+ API
        guard let url = URL(string: "https://example.com/\(content.contentID)") else {
            throw MediaError.invalidURL
        }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        self.player = newPlayer
        self.currentContent = content
    }
    
    func play() async {
        player?.play()
    }
    
    func pause() async {
        player?.pause()
    }
    
    func seek(to time: TimeInterval) async {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        await player?.seek(to: cmTime)
    }
}

enum MediaError: LocalizedError {
    case invalidURL
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid media URL"
        case .loadFailed:
            return "Failed to load media content"
        }
    }
}
