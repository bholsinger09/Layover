import Foundation
import Observation
import AVFoundation

/// ViewModel for Apple TV+ viewing rooms
@MainActor
@Observable
final class AppleTVViewModel: LayoverViewModel {
    private let tvService: AppleTVServiceProtocol
    private let sharePlayService: SharePlayServiceProtocol
    
    private(set) var currentContent: MediaContent?
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var player: AVPlayer? {
        tvService.player
    }
    
    nonisolated init(
        tvService: AppleTVServiceProtocol,
        sharePlayService: SharePlayServiceProtocol
    ) {
        self.tvService = tvService
        self.sharePlayService = sharePlayService
    }
    
    func loadContent(_ content: MediaContent) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try to open in Apple TV app first for better SharePlay support
            try await tvService.openInTVApp(content)
            currentContent = content
            
            // Note: When opening in TV app, SharePlay is handled automatically
            // by the TV app itself, no need for manual coordinator setup
        } catch {
            // Fallback: try in-app playback if TV app fails
            do {
                try await tvService.loadContent(content)
                currentContent = content
                
                // Setup SharePlay coordination for in-app playback
                if let player = tvService.player {
                    try await sharePlayService.setupPlaybackCoordinator(player: player)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func play() async {
        await tvService.play()
        isPlaying = true
    }
    
    func pause() async {
        await tvService.pause()
        isPlaying = false
    }
    
    func seek(to time: TimeInterval) async {
        await tvService.seek(to: time)
    }
    
    func togglePlayPause() async {
        if isPlaying {
            await pause()
        } else {
            await play()
        }
    }
}
