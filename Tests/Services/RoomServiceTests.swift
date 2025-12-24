import Foundation
import Testing

@testable import LayoverKit

/// Tests for RoomService
@Suite("Room Service Tests")
@MainActor
struct RoomServiceTests {

    @Test("Create room")
    func testCreateRoom() async throws {
        let service = RoomService()
        let host = User(username: "TestHost")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleTVPlus
        )

        #expect(room.name == "Test Room")
        #expect(room.hostID == host.id)
        #expect(service.rooms.count == 1)
        #expect(room.participantIDs.contains(host.id))
    }

    @Test("Join room")
    func testJoinRoom() async throws {
        let service = RoomService()
        let host = User(username: "Host")
        let user = User(username: "Joiner")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .texasHoldem
        )

        try await service.joinRoom(roomID: room.id, user: user)

        let updatedRoom = service.rooms.first!
        #expect(updatedRoom.participantIDs.contains(user.id))
        #expect(updatedRoom.participantIDs.count == 2)
    }

    @Test("Leave room")
    func testLeaveRoom() async throws {
        let service = RoomService()
        let host = User(username: "Host")
        let user = User(username: "Leaver")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleMusic
        )

        try await service.joinRoom(roomID: room.id, user: user)
        try await service.leaveRoom(roomID: room.id, userID: user.id)

        let updatedRoom = service.rooms.first!
        #expect(!updatedRoom.participantIDs.contains(user.id))
        #expect(updatedRoom.participantIDs.count == 1)
    }

    @Test("Host leaving room deletes it")
    func testHostLeavingDeletesRoom() async throws {
        let service = RoomService()
        let host = User(username: "Host")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .chess
        )

        try await service.leaveRoom(roomID: room.id, userID: host.id)

        #expect(service.rooms.isEmpty)
    }

    @Test("Promote to sub-host")
    func testPromoteToSubHost() async throws {
        let service = RoomService()
        let host = User(username: "Host")
        let user = User(username: "SubHost")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleTVPlus
        )

        try await service.joinRoom(roomID: room.id, user: user)
        try await service.promoteToSubHost(roomID: room.id, userID: user.id)

        let updatedRoom = service.rooms.first!
        #expect(updatedRoom.isSubHost(userID: user.id))
    }

    @Test("Demote sub-host")
    func testDemoteSubHost() async throws {
        let service = RoomService()
        let host = User(username: "Host")
        let user = User(username: "SubHost")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .texasHoldem
        )

        try await service.joinRoom(roomID: room.id, user: user)
        try await service.promoteToSubHost(roomID: room.id, userID: user.id)
        try await service.demoteSubHost(roomID: room.id, userID: user.id)

        let updatedRoom = service.rooms.first!
        #expect(!updatedRoom.isSubHost(userID: user.id))
    }

    @Test("Delete room")
    func testDeleteRoom() async throws {
        let service = RoomService()
        let host = User(username: "Host")

        let room = try await service.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleMusic
        )

        try await service.deleteRoom(roomID: room.id)

        #expect(service.rooms.isEmpty)
    }

    @Test("Fetch rooms")
    func testFetchRooms() async throws {
        let service = RoomService()
        let host = User(username: "Host")

        _ = try await service.createRoom(name: "Room 1", host: host, activityType: .appleTVPlus)
        _ = try await service.createRoom(name: "Room 2", host: host, activityType: .texasHoldem)

        // Check the in-memory rooms array directly
        #expect(service.rooms.count == 2)
    }

    @Test("Join non-existent room throws error")
    func testJoinNonExistentRoom() async {
        let service = RoomService()
        let user = User(username: "Joiner")
        let roomID = UUID()

        await #expect(throws: RoomError.self) {
            try await service.joinRoom(roomID: roomID, user: user)
        }
    }
}
