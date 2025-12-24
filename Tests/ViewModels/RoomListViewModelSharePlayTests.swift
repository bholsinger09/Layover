import AVFoundation
import Foundation
import GroupActivities
import Testing

@testable import LayoverKit

/// Tests for RoomListViewModel SharePlay integration
@Suite("Room List ViewModel SharePlay Tests")
@MainActor
struct RoomListViewModelSharePlayTests {

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

        var activatedActivities: [LayoverActivity] = []
        var sharedRooms: [Room] = []
        var sharedUsers: [(User, UUID)] = []

        func addSessionStateObserver(_ observer: @escaping (Bool) -> Void) {
            sessionStateObservers.append(observer)
            observer(isSessionActive)
        }

        func startActivity(_ activity: LayoverActivity) async throws {
            activatedActivities.append(activity)
            isSessionActive = true
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

        func shareRoom(_ room: Room) async {
            sharedRooms.append(room)
        }

        func shareUserJoined(_ user: User, roomID: UUID) async {
            sharedUsers.append((user, roomID))
        }

        func shareContent(_ content: MediaContent) async {}

        // Test helpers
        func simulateRoomReceived(_ room: Room) async {
            await MainActor.run {
                onRoomReceived?(room)
            }
        }

        func simulateParticipantJoined(_ user: User, roomID: UUID) async {
            await MainActor.run {
                onParticipantJoined?(user, roomID)
            }
        }
    }

    // MARK: - SharePlay State Tests

    @Test("SharePlay state is tracked correctly")
    func testSharePlayStateTracking() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!viewModel.isSharePlayActive)

        // Start SharePlay
        let activity = LayoverActivity(
            roomID: UUID(),
            activityType: .appleTVPlus,
            customMetadata: ["roomName": "Test"]
        )
        try await sharePlayService.startActivity(activity)

        // Give callback time to execute
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(viewModel.isSharePlayActive)

        // Leave SharePlay
        await sharePlayService.leaveSession()

        // Give callback time to execute
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(!viewModel.isSharePlayActive)
    }

    @Test("SharePlay state updates trigger UI changes")
    func testSharePlayStateUpdates() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        var stateChanges: [Bool] = []

        // Monitor state changes (in real app, SwiftUI would observe this)
        let initialState = viewModel.isSharePlayActive
        stateChanges.append(initialState)

        // Start SharePlay
        try await sharePlayService.startActivity(
            LayoverActivity(
                roomID: UUID(),
                activityType: .appleMusic,
                customMetadata: ["roomName": "Music"]
            ))

        try await Task.sleep(nanoseconds: 100_000_000)
        stateChanges.append(viewModel.isSharePlayActive)

        // Leave SharePlay
        await sharePlayService.leaveSession()

        try await Task.sleep(nanoseconds: 100_000_000)
        stateChanges.append(viewModel.isSharePlayActive)

        #expect(stateChanges == [false, true, false])
    }

    // MARK: - Room Sharing Tests

    @Test("Creating room shares it via SharePlay")
    func testCreateRoomSharing() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let host = User(username: "TestHost")

        await viewModel.createRoom(
            name: "Shared Room",
            host: host,
            activityType: .appleTVPlus
        )

        #expect(viewModel.rooms.count == 1)
        #expect(sharePlayService.sharedRooms.count == 1)
        #expect(sharePlayService.sharedRooms.first?.name == "Shared Room")
    }

    @Test("Receiving room from SharePlay adds it to list")
    func testReceiveRoomFromSharePlay() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to set up callbacks
        try await Task.sleep(nanoseconds: 100_000_000)

        let room = Room(
            name: "Received Room",
            hostID: UUID(),
            activityType: .appleMusic
        )

        await sharePlayService.simulateRoomReceived(room)

        #expect(viewModel.rooms.count == 1)
        #expect(viewModel.rooms.first?.name == "Received Room")
    }

    @Test("Receiving duplicate room does not add it twice")
    func testReceiveDuplicateRoom() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to set up callbacks
        try await Task.sleep(nanoseconds: 100_000_000)

        let room = Room(
            name: "Duplicate Room",
            hostID: UUID(),
            activityType: .texasHoldem
        )

        // Add room twice
        await sharePlayService.simulateRoomReceived(room)
        await sharePlayService.simulateRoomReceived(room)

        #expect(viewModel.rooms.count == 1)
    }

    // MARK: - Participant Synchronization Tests

    @Test("Joining room shares user via SharePlay")
    func testJoinRoomSharing() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let host = User(username: "Host")
        let joiner = User(username: "Joiner")

        await viewModel.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleTVPlus
        )

        let room = viewModel.rooms.first!
        await viewModel.joinRoom(room, user: joiner)

        #expect(sharePlayService.sharedUsers.count == 1)
        #expect(sharePlayService.sharedUsers.first?.0.username == "Joiner")
        #expect(sharePlayService.sharedUsers.first?.1 == room.id)
    }

    @Test("Receiving participant adds them to room")
    func testReceiveParticipantFromSharePlay() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to set up callbacks
        try await Task.sleep(nanoseconds: 100_000_000)

        let host = User(username: "Host")
        await viewModel.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleMusic
        )

        let room = viewModel.rooms.first!
        let newUser = User(username: "NewParticipant")

        await sharePlayService.simulateParticipantJoined(newUser, roomID: room.id)

        let updatedRoom = viewModel.rooms.first!
        #expect(updatedRoom.participants.count == 2)  // Host + new participant
        #expect(updatedRoom.participants.contains(where: { $0.username == "NewParticipant" }))
    }

    @Test("Receiving duplicate participant does not add them twice")
    func testReceiveDuplicateParticipant() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to set up callbacks
        try await Task.sleep(nanoseconds: 100_000_000)

        let host = User(username: "Host")
        await viewModel.createRoom(
            name: "Test Room",
            host: host,
            activityType: .texasHoldem
        )

        let room = viewModel.rooms.first!
        let participant = User(username: "Participant")

        // Add participant twice
        await sharePlayService.simulateParticipantJoined(participant, roomID: room.id)
        await sharePlayService.simulateParticipantJoined(participant, roomID: room.id)

        let updatedRoom = viewModel.rooms.first!
        #expect(updatedRoom.participants.count == 2)  // Only host + one instance of participant
    }

    // MARK: - Navigation Tests

    @Test("Room received callback triggers navigation")
    func testRoomReceivedNavigation() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to set up callbacks
        try await Task.sleep(nanoseconds: 100_000_000)

        var navigatedToRoom: Room?
        viewModel.onRoomReceivedForNavigation = { room in
            navigatedToRoom = room
        }

        let room = Room(
            name: "Navigation Test",
            hostID: UUID(),
            activityType: .appleTVPlus
        )

        await sharePlayService.simulateRoomReceived(room)

        #expect(navigatedToRoom != nil)
        #expect(navigatedToRoom?.name == "Navigation Test")
    }

    // MARK: - Cross-Platform Tests

    @Test("iOS and Mac share same room data")
    func testCrossPlatformRoomSharing() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let host = User(username: "CrossPlatformHost")

        await viewModel.createRoom(
            name: "Cross-Platform Room",
            host: host,
            activityType: .appleMusic
        )

        // Room should be shared regardless of platform
        #expect(sharePlayService.sharedRooms.count == 1)

        let sharedRoom = sharePlayService.sharedRooms.first!
        #expect(sharedRoom.name == "Cross-Platform Room")
        #expect(sharedRoom.activityType == .appleMusic)
    }

    @Test("Session state synchronizes across platforms")
    func testCrossPlatformSessionState() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        // Simulate iOS device
        let iosViewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Simulate Mac device (same service, different view model instance)
        let macViewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!iosViewModel.isSharePlayActive)
        #expect(!macViewModel.isSharePlayActive)

        // Start SharePlay from "iOS"
        try await sharePlayService.startActivity(
            LayoverActivity(
                roomID: UUID(),
                activityType: .appleTVPlus,
                customMetadata: ["roomName": "Test"]
            ))

        try await Task.sleep(nanoseconds: 200_000_000)

        // Both should see the session as active
        #expect(iosViewModel.isSharePlayActive)
        #expect(macViewModel.isSharePlayActive)
    }

    // MARK: - Activity Type Tests

    @Test("Start SharePlay for Apple TV room")
    func testStartSharePlayAppleTV() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let host = User(username: "Host")
        await viewModel.createRoom(
            name: "TV Room",
            host: host,
            activityType: .appleTVPlus
        )

        let room = viewModel.rooms.first!
        await viewModel.startSharePlayForRoom(room)

        #expect(sharePlayService.activatedActivities.count == 1)
        #expect(sharePlayService.activatedActivities.first?.activityType == .appleTVPlus)
    }

    @Test("Start SharePlay for Apple Music room")
    func testStartSharePlayAppleMusic() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let host = User(username: "Host")
        await viewModel.createRoom(
            name: "Music Room",
            host: host,
            activityType: .appleMusic
        )

        let room = viewModel.rooms.first!
        await viewModel.startSharePlayForRoom(room)

        #expect(sharePlayService.activatedActivities.count == 1)
        #expect(sharePlayService.activatedActivities.first?.activityType == .appleMusic)
    }

    @Test("Start SharePlay for Texas Hold'em room")
    func testStartSharePlayTexasHoldem() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        let host = User(username: "Host")
        await viewModel.createRoom(
            name: "Poker Room",
            host: host,
            activityType: .texasHoldem
        )

        let room = viewModel.rooms.first!
        await viewModel.startSharePlayForRoom(room)

        #expect(sharePlayService.activatedActivities.count == 1)
        #expect(sharePlayService.activatedActivities.first?.activityType == .texasHoldem)
    }

    // MARK: - Leave Session Tests

    @Test("Leaving room ends SharePlay session")
    func testLeaveRoomEndsSharePlay() async throws {
        let sharePlayService = MockSharePlayService()
        let roomService = RoomService()

        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: sharePlayService
        )

        // Give init time to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        let host = User(username: "Host")
        await viewModel.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleTVPlus
        )

        let room = viewModel.rooms.first!

        // Start SharePlay
        await viewModel.startSharePlayForRoom(room)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(viewModel.isSharePlayActive)

        // Leave room
        await viewModel.leaveRoom(room, userID: host.id)

        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(!viewModel.isSharePlayActive)
    }
}
