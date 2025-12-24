import AVFoundation
import Foundation
import GroupActivities
import Testing

@testable import LayoverKit

/// Regression tests for Apple TV SharePlay screen sharing across iOS and Mac
/// These tests ensure that when SharePlay is activated on either platform,
/// the Apple TV content is properly shared and visible on the other device
@Suite("Apple TV SharePlay Regression Tests")
@MainActor
struct AppleTVSharePlayRegressionTests {

    // MARK: - Mock Services

    @MainActor
    final class MockSharePlayService: SharePlayServiceProtocol {
        var currentSession: GroupSession<LayoverActivity>?
        var isSessionActive: Bool = false
        var isSessionHost: Bool = false
        var onRoomReceived: ((Room) -> Void)?
        var onParticipantJoined: ((User, UUID) -> Void)?
        var onContentReceived: ((MediaContent) -> Void)?

        private var sessionStateObservers: [(Bool) -> Void] = []
        private var sharedContent: [MediaContent] = []
        private var activatedActivities: [LayoverActivity] = []
        var shouldSimulateRemoteParticipant = true  // Set to false for single-device tests

        func addSessionStateObserver(_ observer: @escaping (Bool) -> Void) {
            sessionStateObservers.append(observer)
            observer(isSessionActive)
        }

        func startActivity(_ activity: LayoverActivity) async throws {
            activatedActivities.append(activity)
            isSessionActive = true
            notifyObservers(true)
        }

        func leaveSession() async {
            isSessionActive = false
            sharedContent.removeAll()
            notifyObservers(false)
        }

        func shareContent(_ content: MediaContent) async {
            sharedContent.append(content)
            // Simulate receiving content on other device(s)
            // Only trigger if simulating remote participants
            if shouldSimulateRemoteParticipant {
                onContentReceived?(content)
            }
        }

        func shareRoom(_ room: Room) async {}
        func shareUserJoined(_ user: User, roomID: UUID) async {}
        func setupPlaybackCoordinator(player: AVPlayer) async throws {}

        private func notifyObservers(_ isActive: Bool) {
            for observer in sessionStateObservers {
                observer(isActive)
            }
        }

        // Test helpers
        var lastSharedContent: MediaContent? {
            sharedContent.last
        }

        var allSharedContent: [MediaContent] {
            sharedContent
        }

        var lastActivatedActivity: LayoverActivity? {
            activatedActivities.last
        }
    }

    @MainActor
    final class MockAppleTVService: AppleTVServiceProtocol {
        var currentContent: MediaContent?
        var player: AVPlayer?

        private(set) var openedContent: [MediaContent] = []
        private(set) var playbackCommands: [String] = []

        func loadContent(_ content: MediaContent) async throws {
            currentContent = content
            openedContent.append(content)
        }

        func openInTVApp(_ content: MediaContent) async throws {
            currentContent = content
            openedContent.append(content)
            playbackCommands.append("open:\(content.title)")
        }

        func play() async {
            playbackCommands.append("play")
        }

        func pause() async {
            playbackCommands.append("pause")
        }

        func seek(to time: TimeInterval) async {
            playbackCommands.append("seek:\(time)")
        }

        // Test helper
        var lastOpenedContent: MediaContent? {
            openedContent.last
        }
    }

    // MARK: - Helper Functions

    private func createTVContent(
        title: String, contentID: String, type: MediaContent.ContentType = .tvShow
    ) -> MediaContent {
        MediaContent(
            title: title,
            contentID: contentID,
            contentType: type
        )
    }

    // MARK: - iOS to Mac Screen Sharing Tests

    @Test("iOS starts SharePlay and Mac receives Apple TV content")
    func testIOSToMacScreenSharing() async throws {
        // Setup: Create services that simulate iOS and Mac devices
        let sharedSharePlayService = MockSharePlayService()

        // iOS device setup
        let iosViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        // Mac device setup (listening for content)
        let macTVService = MockAppleTVService()
        var macReceivedContent: MediaContent?

        // Mac listens for shared content
        sharedSharePlayService.onContentReceived = { content in
            macReceivedContent = content
            Task {
                try? await macTVService.loadContent(content)
            }
        }

        // Create Apple TV content
        let tvContent = createTVContent(
            title: "Ted Lasso",
            contentID: "umc.cmc.vtoh0mn0xn7t3c643xqonfzy"
        )

        // Step 1: Start SharePlay session on iOS
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "TV Room"]
        )
        try await sharedSharePlayService.startActivity(activity)

        // Verify SharePlay is active
        #expect(sharedSharePlayService.isSessionActive)
        #expect(sharedSharePlayService.lastActivatedActivity?.activityType == .appleTVPlus)

        // Step 2: iOS selects Apple TV content
        await iosViewModel.loadContent(tvContent)

        // Step 3: Verify Mac receives the content
        try await Task.sleep(nanoseconds: 100_000_000)  // Allow async propagation

        #expect(macReceivedContent != nil)
        #expect(macReceivedContent?.title == "Ted Lasso")
        #expect(macReceivedContent?.contentID == "umc.cmc.vtoh0mn0xn7t3c643xqonfzy")
        #expect(macTVService.lastOpenedContent?.title == "Ted Lasso")

        // Step 4: Verify content was shared through SharePlay
        #expect(sharedSharePlayService.lastSharedContent?.title == "Ted Lasso")
    }

    @Test("Mac starts SharePlay and iOS receives Apple TV content")
    func testMacToIOSScreenSharing() async throws {
        // Setup: Create services that simulate Mac and iOS devices
        let sharedSharePlayService = MockSharePlayService()

        // Mac device setup
        let macViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        // iOS device setup (listening for content)
        let iosTVService = MockAppleTVService()
        var iosReceivedContent: MediaContent?

        // iOS listens for shared content
        sharedSharePlayService.onContentReceived = { content in
            iosReceivedContent = content
            Task {
                try? await iosTVService.loadContent(content)
            }
        }

        // Create Apple TV content
        let tvContent = createTVContent(
            title: "Foundation",
            contentID: "umc.cmc.5983fipzqbicvrve6jdfep4x3"
        )

        // Step 1: Start SharePlay session on Mac
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Sci-Fi Room"]
        )
        try await sharedSharePlayService.startActivity(activity)

        // Verify SharePlay is active
        #expect(sharedSharePlayService.isSessionActive)

        // Step 2: Mac selects Apple TV content
        await macViewModel.loadContent(tvContent)

        // Step 3: Verify iOS receives the content
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(iosReceivedContent != nil)
        #expect(iosReceivedContent?.title == "Foundation")
        #expect(iosReceivedContent?.contentID == "umc.cmc.5983fipzqbicvrve6jdfep4x3")
        #expect(iosTVService.lastOpenedContent?.title == "Foundation")

        // Step 4: Verify content was shared through SharePlay
        #expect(sharedSharePlayService.lastSharedContent?.title == "Foundation")
    }

    // MARK: - Bidirectional Content Sharing Tests

    @Test("Both iOS and Mac can share different Apple TV content in same session")
    func testBidirectionalContentSharing() async throws {
        let sharedSharePlayService = MockSharePlayService()

        // iOS setup
        let iosViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        // Mac setup
        let macViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        // Track received content on both devices
        var allReceivedContent: [MediaContent] = []
        sharedSharePlayService.onContentReceived = { content in
            allReceivedContent.append(content)
        }

        // Start SharePlay session
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Shared TV Room"]
        )
        try await sharedSharePlayService.startActivity(activity)

        // iOS shares first content
        let content1 = createTVContent(
            title: "The Morning Show",
            contentID: "umc.cmc.25tn3v8ku4b39tr6ccgb8nl6m"
        )
        await iosViewModel.loadContent(content1)
        try await Task.sleep(nanoseconds: 50_000_000)

        // Mac shares second content
        let content2 = createTVContent(
            title: "Severance",
            contentID: "umc.cmc.1srk2goyh2q2zdxcx605w8vtx"
        )
        await macViewModel.loadContent(content2)
        try await Task.sleep(nanoseconds: 50_000_000)

        // Verify both content items were shared
        #expect(sharedSharePlayService.allSharedContent.count == 2)
        #expect(allReceivedContent.count == 2)
        #expect(allReceivedContent[0].title == "The Morning Show")
        #expect(allReceivedContent[1].title == "Severance")
    }

    @Test("Content sharing requires active SharePlay session")
    func testContentSharingRequiresActiveSession() async throws {
        let sharePlayService = MockSharePlayService()
        sharePlayService.shouldSimulateRemoteParticipant = false
        let tvService = MockAppleTVService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        // Track received content
        var receivedContent: MediaContent?
        sharePlayService.onContentReceived = { content in
            receivedContent = content
        }

        // Try to load content WITHOUT starting SharePlay
        let content = createTVContent(
            title: "Hijack",
            contentID: "umc.cmc.4h54hzf5kdrk6gz0fzx2ybr45"
        )

        await viewModel.loadContent(content)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify content was opened locally but NOT shared
        #expect(tvService.lastOpenedContent?.title == "Hijack")
        #expect(sharePlayService.lastSharedContent == nil)
        #expect(receivedContent == nil)
    }

    // MARK: - Movie Content Sharing Tests

    @Test("iOS shares movie content to Mac")
    func testIOSSharesMovieToMac() async throws {
        let sharedSharePlayService = MockSharePlayService()

        let iosViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        let macTVService = MockAppleTVService()
        var macReceivedContent: MediaContent?

        sharedSharePlayService.onContentReceived = { content in
            macReceivedContent = content
            Task {
                try? await macTVService.loadContent(content)
            }
        }

        // Start SharePlay
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Movie Night"]
        )
        try await sharedSharePlayService.startActivity(activity)

        // Share movie content
        let movieContent = createTVContent(
            title: "CODA",
            contentID: "umc.cmc.3eh9r5iz32ggdm4ccvw5igiir",
            type: .movie
        )

        await iosViewModel.loadContent(movieContent)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify movie was shared correctly
        #expect(macReceivedContent != nil)
        #expect(macReceivedContent?.contentType == .movie)
        #expect(macReceivedContent?.title == "CODA")
        #expect(macTVService.lastOpenedContent?.contentType == .movie)
    }

    // MARK: - Session Lifecycle Tests

    @Test("Content sharing stops when SharePlay session ends")
    func testContentSharingStopsAfterSessionEnds() async throws {
        let sharedSharePlayService = MockSharePlayService()

        let iosViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        var receivedContent: [MediaContent] = []
        sharedSharePlayService.onContentReceived = { content in
            receivedContent.append(content)
        }

        // Start SharePlay and share content
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test Room"]
        )
        try await sharedSharePlayService.startActivity(activity)

        let content1 = createTVContent(
            title: "For All Mankind",
            contentID: "umc.cmc.6wsi780sz5tdbqcf11k76mkp7"
        )
        await iosViewModel.loadContent(content1)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedContent.count == 1)
        let sharedCountBeforeLeave = sharedSharePlayService.allSharedContent.count
        #expect(sharedCountBeforeLeave == 1)

        // Leave SharePlay session
        await sharedSharePlayService.leaveSession()
        #expect(!sharedSharePlayService.isSessionActive)

        // Try to share content after session ended
        let content2 = createTVContent(
            title: "Silo",
            contentID: "umc.cmc.3y2k4p5ro3dkbfh4wxvnkaqhw"
        )
        await iosViewModel.loadContent(content2)
        try await Task.sleep(nanoseconds: 50_000_000)

        // Verify second content was NOT shared (same count as before because session is inactive)
        #expect(receivedContent.count == 1)  // Still only one item
        #expect(sharedSharePlayService.allSharedContent.count == 0)  // Cleared on leave
    }

    @Test("Multiple participants receive same Apple TV content")
    func testMultipleParticipantsReceiveSameContent() async throws {
        let sharedSharePlayService = MockSharePlayService()

        // Host device
        let hostViewModel = AppleTVViewModel(
            tvService: MockAppleTVService(),
            sharePlayService: sharedSharePlayService
        )

        // Participant 1 (Mac)
        let mac1TVService = MockAppleTVService()
        var mac1ReceivedContent: MediaContent?

        // Participant 2 (iOS)
        let ios2TVService = MockAppleTVService()
        var ios2ReceivedContent: MediaContent?

        // Participant 3 (Mac)
        let mac3TVService = MockAppleTVService()
        var mac3ReceivedContent: MediaContent?

        // All participants listen for content
        sharedSharePlayService.onContentReceived = { content in
            mac1ReceivedContent = content
            ios2ReceivedContent = content
            mac3ReceivedContent = content

            Task {
                try? await mac1TVService.loadContent(content)
                try? await ios2TVService.loadContent(content)
                try? await mac3TVService.loadContent(content)
            }
        }

        // Start SharePlay session
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Group Watch"]
        )
        try await sharedSharePlayService.startActivity(activity)

        // Host shares content
        let content = createTVContent(
            title: "Shrinking",
            contentID: "umc.cmc.28tzz2rfbhp9l5yk95dhz6sxz"
        )

        await hostViewModel.loadContent(content)
        try await Task.sleep(nanoseconds: 150_000_000)

        // Verify ALL participants received the same content
        #expect(mac1ReceivedContent?.title == "Shrinking")
        #expect(ios2ReceivedContent?.title == "Shrinking")
        #expect(mac3ReceivedContent?.title == "Shrinking")

        #expect(mac1TVService.lastOpenedContent?.title == "Shrinking")
        #expect(ios2TVService.lastOpenedContent?.title == "Shrinking")
        #expect(mac3TVService.lastOpenedContent?.title == "Shrinking")
    }

    // MARK: - Content Type Verification Tests

    @Test("SharePlay activity type matches Apple TV content")
    func testActivityTypeMatchesContent() async throws {
        let sharePlayService = MockSharePlayService()
        sharePlayService.shouldSimulateRemoteParticipant = false
        let tvService = MockAppleTVService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        // Start Apple TV+ SharePlay activity
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "TV Room"]
        )
        try await sharePlayService.startActivity(activity)

        // Verify correct activity type was activated
        #expect(sharePlayService.lastActivatedActivity?.activityType == .appleTVPlus)

        // Load content
        let content = createTVContent(
            title: "Mythic Quest",
            contentID: "umc.cmc.1nfdfd5zlk05fo1bwwetzldy3"
        )

        await viewModel.loadContent(content)

        // Verify content was loaded with correct service
        #expect(tvService.lastOpenedContent?.title == "Mythic Quest")
    }

    // MARK: - Error Handling Tests

    @Test("Content sharing handles nil content gracefully")
    func testHandlesNilContentGracefully() async throws {
        let sharePlayService = MockSharePlayService()
        sharePlayService.shouldSimulateRemoteParticipant = false
        let tvService = MockAppleTVService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        // Start SharePlay
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test"]
        )
        try await sharePlayService.startActivity(activity)

        // Verify no crashes when current content is nil
        #expect(viewModel.currentContent == nil)
        #expect(sharePlayService.lastSharedContent == nil)
    }

    @Test("SharePlay session state is consistent across content changes")
    func testSessionStateConsistentAcrossContentChanges() async throws {
        let sharePlayService = MockSharePlayService()
        sharePlayService.shouldSimulateRemoteParticipant = false  // Don't trigger callback for own content
        let tvService = MockAppleTVService()

        let viewModel = AppleTVViewModel(
            tvService: tvService,
            sharePlayService: sharePlayService
        )

        var stateChanges: [Bool] = []
        sharePlayService.addSessionStateObserver { isActive in
            stateChanges.append(isActive)
        }

        // Start session
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test"]
        )
        try await sharePlayService.startActivity(activity)

        // Load multiple content items
        for i in 1...5 {
            let content = createTVContent(
                title: "Show \(i)",
                contentID: "test.id.\(i)"
            )
            await viewModel.loadContent(content)
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        // Session should remain active throughout
        #expect(sharePlayService.isSessionActive)
        #expect(stateChanges == [false, true])  // Initial + start, no additional changes
        #expect(tvService.openedContent.count == 5)
    }
}
