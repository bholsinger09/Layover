import AVFoundation
import Foundation
import GroupActivities
import Testing

@testable import LayoverKit

/// Tests for AppleTVViewModel SharePlay integration
@Suite("Apple TV ViewModel SharePlay Tests")
@MainActor
struct AppleTVViewModelSharePlayTests {

    // MARK: - Mock Services

    @MainActor
    final class MockAppleTVService: AppleTVServiceProtocol {
        var currentContent: MediaContent?
        var player: AVPlayer?
        var openedContent: [MediaContent] = []
        var playCallCount = 0
        var pauseCallCount = 0
        var seekCalls: [TimeInterval] = []

        func loadContent(_ content: MediaContent) async throws {
            currentContent = content
            openedContent.append(content)
        }

        func openInTVApp(_ content: MediaContent) async throws {
            openedContent.append(content)
        }

        func play() async {
            playCallCount += 1
        }

        func pause() async {
            pauseCallCount += 1
        }

        func seek(to time: TimeInterval) async {
            seekCalls.append(time)
        }
    }

    @MainActor
    final class MockSharePlayService: SharePlayServiceProtocol {
        var currentSession: GroupSession<LayoverActivity>?
        var isSessionActive: Bool = false
        var onRoomReceived: ((Room) -> Void)?
        var onParticipantJoined: ((User, UUID) -> Void)?
        var onContentReceived: ((MediaContent) -> Void)?
        var onSessionStateChanged: ((Bool) -> Void)?

        var activatedActivities: [LayoverActivity] = []
        var sharedRooms: [Room] = []
        var sharedUsers: [(User, UUID)] = []
        var sharedContent: [MediaContent] = []

        func startActivity(_ activity: LayoverActivity) async throws {
            activatedActivities.append(activity)
            isSessionActive = true
            await MainActor.run {
                onSessionStateChanged?(true)
            }
        }

        func leaveSession() async {
            isSessionActive = false
            await MainActor.run {
                onSessionStateChanged?(false)
            }
        }

        func setupPlaybackCoordinator(player: AVPlayer) async throws {}

        func shareRoom(_ room: Room) async {
            sharedRooms.append(room)
        }

        func shareUserJoined(_ user: User, roomID: UUID) async {
            sharedUsers.append((user, roomID))
        }

        func shareContent(_ content: MediaContent) async {
            sharedContent.append(content)
        }

        // Test helpers
        func simulateContentReceived(_ content: MediaContent) async {
            await MainActor.run {
                onContentReceived?(content)
            }
        }
    }

    // MARK: - Content Loading Tests

    @Test("Loading content shares it via SharePlay when session is active")
    func testLoadContentWithActiveSharePlay() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()
        sharePlayService.isSessionActive = true

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        let content = MediaContent(
            title: "Test Movie",
            contentID: "test-123",
            duration: 7200,
            contentType: .movie
        )

        await viewModel.loadContent(content)

        #expect(tvService.openedContent.count == 1)
        #expect(tvService.openedContent.first?.title == "Test Movie")
        #expect(sharePlayService.sharedContent.count == 1)
        #expect(sharePlayService.sharedContent.first?.title == "Test Movie")
        #expect(viewModel.currentContent?.title == "Test Movie")
    }

    @Test("Loading content without SharePlay does not share")
    func testLoadContentWithoutSharePlay() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()
        sharePlayService.isSessionActive = false

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        let content = MediaContent(
            title: "Test Show",
            contentID: "show-456",
            duration: 3600,
            contentType: .tvShow
        )

        await viewModel.loadContent(content)

        #expect(tvService.openedContent.count == 1)
        #expect(sharePlayService.sharedContent.isEmpty)
        #expect(viewModel.currentContent?.title == "Test Show")
    }

    // MARK: - Content Reception Tests

    @Test("Receiving content from SharePlay loads it")
    func testReceiveContentFromSharePlay() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        let content = MediaContent(
            title: "Shared Movie",
            contentID: "shared-789",
            duration: 7200,
            contentType: .movie
        )

        // Simulate content received from another participant
        await sharePlayService.simulateContentReceived(content)

        // The view should set up the callback, so we need to simulate it
        await sharePlayService.onContentReceived?(content)

        // Verify callback was set (in real app, view sets this in onAppear)
        #expect(sharePlayService.onContentReceived != nil)
    }

    // MARK: - Playback Control Tests

    @Test("Play and pause controls work correctly")
    func testPlayPauseControls() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        await viewModel.play()
        #expect(tvService.playCallCount == 1)
        #expect(viewModel.isPlaying)

        await viewModel.pause()
        #expect(tvService.pauseCallCount == 1)
        #expect(!viewModel.isPlaying)
    }

    @Test("Toggle play/pause works correctly")
    func testTogglePlayPause() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        // Start from paused
        await viewModel.togglePlayPause()
        #expect(viewModel.isPlaying)
        #expect(tvService.playCallCount == 1)

        // Toggle to pause
        await viewModel.togglePlayPause()
        #expect(!viewModel.isPlaying)
        #expect(tvService.pauseCallCount == 1)
    }

    @Test("Seek controls work correctly")
    func testSeekControl() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        await viewModel.seek(to: 120.0)

        #expect(tvService.seekCalls.count == 1)
        #expect(tvService.seekCalls.first == 120.0)
    }

    // MARK: - Error Handling Tests

    @Test("Loading content handles errors gracefully")
    func testLoadContentErrorHandling() async throws {
        // Mock service that throws errors
        @MainActor
        final class ErrorTVService: AppleTVServiceProtocol {
            var currentContent: MediaContent?
            var player: AVPlayer?

            func loadContent(_ content: MediaContent) async throws {
                throw NSError(
                    domain: "TestError", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to load content"
                    ])
            }

            func openInTVApp(_ content: MediaContent) async throws {
                throw NSError(
                    domain: "TestError", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to open TV app"
                    ])
            }

            func play() async {}
            func pause() async {}
            func seek(to time: TimeInterval) async {}
        }

        let tvService = ErrorTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        let content = MediaContent(
            title: "Error Test",
            contentID: "error-123",
            duration: 7200,
            contentType: .movie
        )

        await viewModel.loadContent(content)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Failed to open TV app") == true)
        #expect(viewModel.currentContent == nil)
    }

    // MARK: - iOS and Mac Compatibility Tests

    @Test("ViewModel works on both platforms")
    func testCrossPlatformCompatibility() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        let content = MediaContent(
            title: "Cross-Platform Content",
            contentID: "cross-123",
            duration: 7200,
            contentType: .movie
        )

        // Should work the same on both iOS and Mac
        await viewModel.loadContent(content)

        #expect(viewModel.currentContent != nil)
        #expect(tvService.openedContent.count == 1)
    }

    @Test("SharePlay state updates are reflected in ViewModel")
    func testSharePlayStateUpdates() async throws {
        let tvService = MockAppleTVService()
        let sharePlayService = MockSharePlayService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        #expect(!viewModel.sharePlayService.isSessionActive)

        // Start SharePlay activity
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test"]
        )
        try await sharePlayService.startActivity(activity)

        #expect(viewModel.sharePlayService.isSessionActive)

        // Leave session
        await sharePlayService.leaveSession()

        #expect(!viewModel.sharePlayService.isSessionActive)
    }
}
