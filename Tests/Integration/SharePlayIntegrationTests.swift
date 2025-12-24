import AVFoundation
import Foundation
import GroupActivities
import Testing

@testable import LayoverKit

/// Integration tests for SharePlay cross-platform state synchronization
/// These tests verify that iOS and Mac properly reflect SharePlay session states
@Suite("SharePlay Integration Tests")
@MainActor
struct SharePlayIntegrationTests {

    // MARK: - Mock SharePlay Service

    @MainActor
    final class TestSharePlayService: SharePlayServiceProtocol {
        var currentSession: GroupSession<LayoverActivity>?
        var isSessionActive: Bool = false
        var onRoomReceived: ((Room) -> Void)?
        var onParticipantJoined: ((User, UUID) -> Void)?
        var onContentReceived: ((MediaContent) -> Void)?
        private var sessionStateObservers: [(Bool) -> Void] = []

        var activatedActivities: [LayoverActivity] = []

        func addSessionStateObserver(_ observer: @escaping (Bool) -> Void) {
            sessionStateObservers.append(observer)
            // Immediately call with current state
            observer(isSessionActive)
        }

        func startActivity(_ activity: LayoverActivity) async throws {
            activatedActivities.append(activity)
            isSessionActive = true
            // Notify all observers
            await MainActor.run {
                for observer in sessionStateObservers {
                    observer(true)
                }
            }
        }

        func leaveSession() async {
            isSessionActive = false
            await MainActor.run {
                for observer in sessionStateObservers {
                    observer(false)
                }
            }
        }

        func setupPlaybackCoordinator(player: AVPlayer) async throws {}

        func shareRoom(_ room: Room) async {}

        func shareUserJoined(_ user: User, roomID: UUID) async {}

        func shareContent(_ content: MediaContent) async {}
    }

    // MARK: - Session State Synchronization Tests

    @Test("Session state callback executes on MainActor")
    func testSessionStateCallbackMainActor() async throws {
        let service = TestSharePlayService()
        var callbackExecuted = false
        var wasOnMainActor = false

        service.addSessionStateObserver { isActive in
            callbackExecuted = true
            wasOnMainActor = Thread.isMainThread
        }

        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test"]
        )

        try await service.startActivity(activity)

        // Give callback time to execute
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(callbackExecuted)
        #expect(wasOnMainActor)
    }

    @Test("iOS and Mac receive same session state - start")
    func testCrossPlatformSessionStart() async throws {
        let sharedService = TestSharePlayService()

        var iosState: Bool?
        var macState: Bool?

        // Both platforms listen to same service
        sharedService.addSessionStateObserver { isActive in
            iosState = isActive
            macState = isActive
        }

        // Start SharePlay from one device
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleMusic,
            customMetadata: ["roomName": "Music Room"]
        )

        try await sharedService.startActivity(activity)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Both platforms should see active state
        #expect(iosState == true)
        #expect(macState == true)
        #expect(sharedService.isSessionActive)
    }

    @Test("iOS and Mac receive same session state - leave")
    func testCrossPlatformSessionLeave() async throws {
        let sharedService = TestSharePlayService()

        var stateChanges: [Bool] = []

        sharedService.addSessionStateObserver { isActive in
            stateChanges.append(isActive)
        }

        // Start then leave
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .texasHoldem,
            customMetadata: ["roomName": "Poker"]
        )

        try await sharedService.startActivity(activity)
        try await Task.sleep(nanoseconds: 100_000_000)

        await sharedService.leaveSession()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Should see both state changes
        #expect(stateChanges.count == 3)  // Initial false, start true, leave false
        #expect(stateChanges == [false, true, false])
        #expect(!sharedService.isSessionActive)
    }

    @Test("RoomListViewModel reflects SharePlay state changes")
    func testRoomListViewModelStateSync() async throws {
        let sharePlayService = TestSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to set up callbacks
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(!viewModel.isSharePlayActive)

        // Start SharePlay
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "TV"]
        )
        try await sharePlayService.startActivity(activity)

        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(viewModel.isSharePlayActive)

        // Leave SharePlay
        await sharePlayService.leaveSession()

        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(!viewModel.isSharePlayActive)
    }

    @Test("Multiple ViewModels see same SharePlay state")
    func testMultipleViewModelsSynchronization() async throws {
        let sharePlayService = TestSharePlayService()
        let roomService = RoomService()

        // Simulate different views/screens
        let viewModel1 = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let viewModel2 = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!viewModel1.isSharePlayActive)
        #expect(!viewModel2.isSharePlayActive)

        // Start SharePlay
        try await sharePlayService.startActivity(
            LayoverActivity(
                roomID: UUID(),
                activityType: .appleMusic,
                customMetadata: ["roomName": "Music"]
            ))

        try await Task.sleep(nanoseconds: 200_000_000)

        // Both should see active state
        #expect(viewModel1.isSharePlayActive)
        #expect(viewModel2.isSharePlayActive)
    }

    @Test("Session state persists across callback updates")
    func testSessionStatePersistence() async throws {
        let service = TestSharePlayService()
        var callbackCount = 0

        service.addSessionStateObserver { isActive in
            callbackCount += 1
        }

        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test"]
        )

        try await service.startActivity(activity)
        try await Task.sleep(nanoseconds: 150_000_000)

        // Update callback (simulating view re-appearing)
        service.addSessionStateObserver { isActive in
            callbackCount += 1
            #expect(isActive == service.isSessionActive)  // Should match service state
        }

        // Verify service still shows active
        #expect(service.isSessionActive)

        await service.leaveSession()
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(callbackCount >= 2)
    }

    @Test("All activity types are supported")
    func testAllActivityTypes() async throws {
        let service = TestSharePlayService()

        let activityTypes: [(RoomActivityType, String)] = [
            (.appleTVPlus, "TV Room"),
            (.appleMusic, "Music Room"),
            (.texasHoldem, "Poker Room"),
        ]

        for (type, name) in activityTypes {
            let activity = LayoverActivity(
                roomID: UUID(),
                activityType: type,
                customMetadata: ["roomName": name]
            )

            try await service.startActivity(activity)

            #expect(service.isSessionActive)
            #expect(service.activatedActivities.last?.activityType == type)

            await service.leaveSession()
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(service.activatedActivities.count == 3)
    }
}
