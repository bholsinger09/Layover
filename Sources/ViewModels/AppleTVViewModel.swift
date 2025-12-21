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
            try await tvService.loadContent(content)
            currentContent = content
            
            // Setup SharePlay coordination
            if let player = tvService.player {
                try await sharePlayService.setupPlaybackCoordinator(player: player)
            }
        } catch {
            errorMessage = error.localizedDescription
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
