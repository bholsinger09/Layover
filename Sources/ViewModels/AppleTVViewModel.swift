import AVFoundation
import Foundation
import Observation
import OSLog

/// ViewModel for Apple TV+ viewing rooms
@MainActor
@Observable
final class AppleTVViewModel: LayoverViewModel {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "AppleTVViewModel")
    private let tvService: AppleTVServiceProtocol
    let sharePlayService: SharePlayServiceProtocol

    private(set) var currentContent: MediaContent?
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var player: AVPlayer? {
        tvService.player
    }

    init(
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
            // Open content in Apple TV app
            // When SharePlay is active, the TV app will automatically join the session
            // and sync playback across all participants
            try await tvService.openInTVApp(content)
            currentContent = content
            print("✅ Opened content in Apple TV app: \(content.title)")
            
            // Share the content selection with other participants
            if sharePlayService.isSessionActive {
                print("📤 Sharing content '\(content.title)' with SharePlay participants...")
                await sharePlayService.shareContent(content)
            } else {
                print("⚠️ SharePlay not active, content not shared")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to open content in TV app: \(error)")
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
    
    func openContentInTVApp(_ content: MediaContent) async {
        do {
            try await tvService.openInTVApp(content)
        } catch {
            logger.error("❌ Failed to open TV app: \(error.localizedDescription)")
        }
    }
}
