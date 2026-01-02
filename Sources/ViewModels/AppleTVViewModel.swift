import AVFoundation
import Foundation
import OSLog
import Observation

/// ViewModel for Apple TV+ viewing rooms
@MainActor
@Observable
public final class AppleTVViewModel: LayoverViewModel {
    private let logger = Logger(
        subsystem: "com.bholsinger.LayoverLounge", category: "AppleTVViewModel")
    private let tvService: AppleTVServiceProtocol
    public let sharePlayService: SharePlayServiceProtocol
    private var isLoadingFromSharePlay = false
    public var onTVAppOpened: (() -> Void)?

    public private(set) var currentContent: MediaContent?
    public private(set) var isPlaying = false
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public var player: AVPlayer? {
        tvService.player
    }

    public nonisolated init(
        tvService: AppleTVServiceProtocol,
        sharePlayService: SharePlayServiceProtocol
    ) {
        self.tvService = tvService
        self.sharePlayService = sharePlayService
    }
    
    public func setupSharePlayCallbacks() {
        logger.info("🎬 AppleTVViewModel setting up SharePlay callbacks")
        logger.info("🔌 Setting up onContentReceived callback...")
        logger.info("   SharePlay session active: \(self.sharePlayService.isSessionActive)")

        // Set up callback to receive content from other participants
        self.sharePlayService.onContentReceived = { [weak self] content in
            Task { @MainActor in
                guard let self = self else {
                    print("⚠️ Self is nil in onContentReceived callback")
                    return
                }
                self.logger.info("📺 ═══════════════════════════════════")
                self.logger.info("📺 ✅ CALLBACK TRIGGERED: Received content from SharePlay")
                self.logger.info("📺 Content title: \(content.title)")
                self.logger.info("📺 Content ID: \(content.contentID)")
                self.logger.info("📺 Content type: \(content.contentType.rawValue)")
                self.logger.info("📺 Current content before: \(self.currentContent?.title ?? "none")")
                self.logger.info("📺 Setting isLoadingFromSharePlay = true to prevent loop")
                self.isLoadingFromSharePlay = true
                await self.loadContent(content)
                self.logger.info("📺 Current content after: \(self.currentContent?.title ?? "none")")
                self.logger.info("📺 Content loaded, clearing isLoadingFromSharePlay flag")
                self.isLoadingFromSharePlay = false
                self.logger.info("📺 ═══════════════════════════════════")
            }
        }

        logger.info("✅ onContentReceived callback setup complete")
        logger.info("   Callback is set: \(self.sharePlayService.onContentReceived != nil)")
    }
    
    // TEST FUNCTION: Send content without opening TV app
    public func testShareContent() async {
        logger.info("🧪 TEST: Sending test content via SharePlay...")
        let testContent = MediaContent(
            title: "TEST_CONTENT_\(Date().timeIntervalSince1970)",
            contentID: "test-\(UUID().uuidString)",
            duration: 100,
            contentType: .tvShow
        )
        
        currentContent = testContent
        
        if sharePlayService.isSessionActive {
            await sharePlayService.shareContent(testContent)
            logger.info("🧪 TEST: Content shared!")
        } else {
            logger.error("🧪 TEST: SharePlay not active, cannot share")
        }
    }

    public func loadContent(_ content: MediaContent) async {
        logger.info("🎬 ═══════════════════════════════════")
        logger.info("🎬 loadContent() called")
        logger.info("🎬 Content: \(content.title)")
        logger.info("🎬 Content ID: \(content.contentID)")
        logger.info("🎬 isLoadingFromSharePlay: \(self.isLoadingFromSharePlay)")
        logger.info("🎬 SharePlay active: \(self.sharePlayService.isSessionActive)")
        logger.info("🎬 ═══════════════════════════════════")

        isLoading = true
        errorMessage = nil

        // Update current content immediately so UI reflects it
        logger.info("📝 Setting currentContent = \(content.title)")
        currentContent = content
        logger.info("✅ currentContent updated, should trigger UI refresh")

        do {
            // Open content in Apple TV app
            // When SharePlay is active, the TV app will automatically join the session
            // and sync playback across all participants
            logger.info("📱 Opening content in TV app...")
            try await tvService.openInTVApp(content)
            logger.info("✅ Opened content in Apple TV app: \(content.title)")
            
            // Notify that TV app window has opened
            logger.info("📺 Notifying that TV app window has opened...")
            onTVAppOpened?()

            // Share the content selection with other participants
            // But only if we're not already loading content from SharePlay (prevent loop)
            if sharePlayService.isSessionActive && !isLoadingFromSharePlay {
                logger.info("📤 SharePlay is active and this is LOCAL content selection")
                logger.info("📤 Sharing content '\(content.title)' with SharePlay participants...")
                await sharePlayService.shareContent(content)
                logger.info("✅ Content shared successfully via SharePlay")
            } else if isLoadingFromSharePlay {
                logger.info("📥 This content was RECEIVED from SharePlay, not re-sharing")
            } else {
                logger.warning("⚠️ SharePlay session is NOT active, content will NOT be shared")
                logger.warning(
                    "⚠️ Current session state: \(self.sharePlayService.isSessionActive ? "active" : "inactive")"
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            logger.error("❌ Failed to open content in TV app: \(error.localizedDescription)")
            logger.error("❌ Error: \(String(describing: error))")
        }

        isLoading = false
        logger.info("🎬 loadContent() completed")
    }

    public func play() async {
        await tvService.play()
        isPlaying = true
    }

    public func pause() async {
        await tvService.pause()
        isPlaying = false
    }

    public func seek(to time: TimeInterval) async {
        await tvService.seek(to: time)
    }

    public func togglePlayPause() async {
        if isPlaying {
            await pause()
        } else {
            await play()
        }
    }

    public func openContentInTVApp(_ content: MediaContent) async {
        do {
            try await tvService.openInTVApp(content)
        } catch {
            logger.error("❌ Failed to open TV app: \(error.localizedDescription)")
        }
    }
}
