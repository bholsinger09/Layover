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
    private var isLoadingFromSharePlay = false

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
        
        // Set up callback to receive content from other participants
        self.sharePlayService.onContentReceived = { [weak self] content in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.info("📺 Received content from SharePlay: \(content.title)")
                self.isLoadingFromSharePlay = true
                await self.loadContent(content)
                self.isLoadingFromSharePlay = false
            }
        }
    }

    func loadContent(_ content: MediaContent) async {
        logger.info("🎬 Loading content: \(content.title)")
        isLoading = true
        errorMessage = nil
        
        // Update current content immediately so UI reflects it
        currentContent = content

        do {
            // Open content in Apple TV app
            // When SharePlay is active, the TV app will automatically join the session
            // and sync playback across all participants
            try await tvService.openInTVApp(content)
            logger.info("✅ Opened content in Apple TV app: \(content.title)")
            
            // Share the content selection with other participants
            // But only if we're not already loading content from SharePlay (prevent loop)
            if sharePlayService.isSessionActive && !isLoadingFromSharePlay {
                logger.info("📤 Sharing content '\(content.title)' with SharePlay participants...")
                await sharePlayService.shareContent(content)
                logger.info("✅ Content shared successfully")
            } else if isLoadingFromSharePlay {
                logger.info("📥 Content received from SharePlay, not re-sharing")
            } else {
                logger.warning("⚠️ SharePlay not active, content not shared")
            }
        } catch {
            errorMessage = error.localizedDescription
            logger.error("❌ Failed to open content in TV app: \(error.localizedDescription)")
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
