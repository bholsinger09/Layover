import Foundation
import Observation

/// ViewModel for Apple Music listening rooms
@MainActor
@Observable
final class AppleMusicViewModel: LayoverViewModel {
    private let musicService: AppleMusicServiceProtocol
    
    private(set) var currentContent: MediaContent?
    private(set) var isPlaying = false
    private(set) var isAuthorized = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    nonisolated init(musicService: AppleMusicServiceProtocol) {
        self.musicService = musicService
        Task {
            isAuthorized = await musicService.isAuthorized
        }
    }
    
    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await musicService.requestAuthorization()
            isAuthorized = await musicService.isAuthorized
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadContent(_ content: MediaContent) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await musicService.loadContent(content)
            currentContent = content
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func play() async {
        await musicService.play()
        isPlaying = true
    }
    
    func pause() async {
        await musicService.pause()
        isPlaying = false
    }
    
    func togglePlayPause() async {
        if isPlaying {
            await pause()
        } else {
            await play()
        }
    }
}
