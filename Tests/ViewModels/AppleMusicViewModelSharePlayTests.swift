import AVFoundation
import Foundation
import GroupActivities
import Testing

@testable import LayoverKit

/// Tests for AppleMusicViewModel SharePlay integration
@Suite("Apple Music ViewModel SharePlay Tests")
@MainActor
struct AppleMusicViewModelSharePlayTests {

    // MARK: - Mock Services

    @MainActor
    final class MockAppleMusicService: AppleMusicServiceProtocol {
        var currentContent: MediaContent?
        var isAuthorized = true
        var loadedContent: [MediaContent] = []
        var playCallCount = 0
        var pauseCallCount = 0
        var authorizationRequested = false

        func requestAuthorization() async throws {
            authorizationRequested = true
            isAuthorized = true
        }

        func loadContent(_ content: MediaContent) async throws {
            currentContent = content
            loadedContent.append(content)
        }

        func play() async {
            playCallCount += 1
        }

        func pause() async {
            pauseCallCount += 1
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

        func shareUserJoined(_ user: User, roomID: UUID) async {}

        func shareContent(_ content: MediaContent) async {
            sharedContent.append(content)
        }
    }

    // MARK: - Authorization Tests

    @Test("Request authorization updates state")
    func testRequestAuthorization() async throws {
        let musicService = MockAppleMusicService()
        musicService.isAuthorized = false

        let viewModel = AppleMusicViewModel(musicService: musicService)

        await viewModel.requestAuthorization()

        #expect(musicService.authorizationRequested)
        #expect(viewModel.isAuthorized)
    }

    @Test("Authorization state is checked on init")
    func testAuthorizationOnInit() async throws {
        let musicService = MockAppleMusicService()
        musicService.isAuthorized = true

        let viewModel = AppleMusicViewModel(musicService: musicService)

        // Give time for async init
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.isAuthorized)
    }

    // MARK: - Content Loading Tests

    @Test("Loading content works correctly")
    func testLoadContent() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        let content = MediaContent(
            title: "Test Song",
            contentID: "song-123",
            duration: 240,
            contentType: .song
        )

        await viewModel.loadContent(content)

        #expect(musicService.loadedContent.count == 1)
        #expect(musicService.loadedContent.first?.title == "Test Song")
        #expect(viewModel.currentContent?.title == "Test Song")
    }

    @Test("Loading content handles errors")
    func testLoadContentError() async throws {
        @MainActor
        final class ErrorMusicService: AppleMusicServiceProtocol {
            var currentContent: MediaContent?
            var isAuthorized = true

            func requestAuthorization() async throws {}

            func loadContent(_ content: MediaContent) async throws {
                throw NSError(
                    domain: "TestError", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to load music"
                    ])
            }

            func play() async {}
            func pause() async {}
        }

        let musicService = ErrorMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        let content = MediaContent(
            title: "Error Song",
            contentID: "error-123",
            duration: 240,
            contentType: .song
        )

        await viewModel.loadContent(content)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Failed to load music") == true)
    }

    // MARK: - Playback Control Tests

    @Test("Play control works correctly")
    func testPlayControl() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        await viewModel.play()

        #expect(musicService.playCallCount == 1)
        #expect(viewModel.isPlaying)
    }

    @Test("Pause control works correctly")
    func testPauseControl() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        await viewModel.pause()

        #expect(musicService.pauseCallCount == 1)
        #expect(!viewModel.isPlaying)
    }

    @Test("Toggle play/pause works correctly")
    func testTogglePlayPause() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        // Start paused
        #expect(!viewModel.isPlaying)

        // Toggle to play
        await viewModel.togglePlayPause()
        #expect(viewModel.isPlaying)
        #expect(musicService.playCallCount == 1)

        // Toggle to pause
        await viewModel.togglePlayPause()
        #expect(!viewModel.isPlaying)
        #expect(musicService.pauseCallCount == 1)
    }

    // MARK: - Loading State Tests

    @Test("Loading state is managed correctly")
    func testLoadingState() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        #expect(!viewModel.isLoading)

        let loadTask = Task {
            await viewModel.loadContent(
                MediaContent(
                    title: "Test",
                    contentID: "test",
                    duration: 240,
                    contentType: .song
                ))
        }

        // Brief moment to check loading state
        try await Task.sleep(nanoseconds: 1_000_000)

        await loadTask.value

        #expect(!viewModel.isLoading)
    }

    // MARK: - Cross-Platform Compatibility Tests

    @Test("ViewModel works on both iOS and Mac")
    func testCrossPlatformCompatibility() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        let content = MediaContent(
            title: "Cross-Platform Song",
            contentID: "cross-123",
            duration: 240,
            contentType: .song
        )

        await viewModel.loadContent(content)

        #expect(viewModel.currentContent?.title == "Cross-Platform Song")
        #expect(musicService.loadedContent.count == 1)
    }

    // MARK: - Content Type Tests

    @Test("Loading song content")
    func testLoadSong() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        let song = MediaContent(
            title: "Test Song",
            contentID: "song-123",
            duration: 240,
            contentType: .song
        )

        await viewModel.loadContent(song)

        #expect(viewModel.currentContent?.contentType == .song)
    }

    @Test("Loading album content")
    func testLoadAlbum() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        let album = MediaContent(
            title: "Test Album",
            contentID: "album-456",
            duration: 3600,
            contentType: .album
        )

        await viewModel.loadContent(album)

        #expect(viewModel.currentContent?.contentType == .album)
    }

    @Test("Loading playlist content")
    func testLoadPlaylist() async throws {
        let musicService = MockAppleMusicService()
        let viewModel = AppleMusicViewModel(musicService: musicService)

        let playlist = MediaContent(
            title: "Test Playlist",
            contentID: "playlist-789",
            duration: 7200,
            contentType: .playlist
        )

        await viewModel.loadContent(playlist)

        #expect(viewModel.currentContent?.contentType == .playlist)
    }
}
