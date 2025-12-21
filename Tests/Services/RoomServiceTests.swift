import Testing
import Foundation
@testable import LayoverKit

/// Tests for RoomService
@Suite("Room Service Tests")
@MainActor
struct RoomServiceTests {
    
    @Test("Create room")
    func testCreateRoom() async throws {
        let service = RoomService()
        let hostID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleTVPlus
        )
        
        #expect(room.name == "Test Room")
        #expect(room.hostID == hostID)
        #expect(room.activityType == .appleTVPlus)
        #expect(service.rooms.count == 1)
        #expect(room.participantIDs.contains(hostID))
    }
    
    @Test("Join room")
    func testJoinRoom() async throws {
        let service = RoomService()
        let hostID = UUID()
        let userID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .texasHoldem
        )
        
        try await service.joinRoom(roomID: room.id, userID: userID)
        
        let updatedRoom = service.rooms.first!
        #expect(updatedRoom.participantIDs.contains(userID))
        #expect(updatedRoom.participantIDs.count == 2)
    }
    
    @Test("Leave room")
    func testLeaveRoom() async throws {
        let service = RoomService()
        let hostID = UUID()
        let userID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleMusic
        )
        
        try await service.joinRoom(roomID: room.id, userID: userID)
        try await service.leaveRoom(roomID: room.id, userID: userID)
        
        let updatedRoom = service.rooms.first!
        #expect(!updatedRoom.participantIDs.contains(userID))
        #expect(updatedRoom.participantIDs.count == 1)
    }
    
    @Test("Host leaving room deletes it")
    func testHostLeavingDeletesRoom() async throws {
        let service = RoomService()
        let hostID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .chess
        )
        
        try await service.leaveRoom(roomID: room.id, userID: hostID)
        
        #expect(service.rooms.isEmpty)
    }
    
    @Test("Promote to sub-host")
    func testPromoteToSubHost() async throws {
        let service = RoomService()
        let hostID = UUID()
        let userID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleTVPlus
        )
        
        try await service.joinRoom(roomID: room.id, userID: userID)
        try await service.promoteToSubHost(roomID: room.id, userID: userID)
        
        let updatedRoom = service.rooms.first!
        #expect(updatedRoom.isSubHost(userID: userID))
    }
    
    @Test("Demote sub-host")
    func testDemoteSubHost() async throws {
        let service = RoomService()
        let hostID = UUID()
        let userID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .texasHoldem
        )
        
        try await service.joinRoom(roomID: room.id, userID: userID)
        try await service.promoteToSubHost(roomID: room.id, userID: userID)
        try await service.demoteSubHost(roomID: room.id, userID: userID)
        
        let updatedRoom = service.rooms.first!
        #expect(!updatedRoom.isSubHost(userID: userID))
    }
    
    @Test("Delete room")
    func testDeleteRoom() async throws {
        let service = RoomService()
        let hostID = UUID()
        
        let room = try await service.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleMusic
        )
        
        try await service.deleteRoom(roomID: room.id)
        
        #expect(service.rooms.isEmpty)
    }
    
    @Test("Fetch rooms")
    func testFetchRooms() async throws {
        let service = RoomService()
        let hostID = UUID()
        
        _ = try await service.createRoom(name: "Room 1", hostID: hostID, activityType: .appleTVPlus)
        _ = try await service.createRoom(name: "Room 2", hostID: hostID, activityType: .texasHoldem)
        
        let rooms = try await service.fetchRooms()
        
        #expect(rooms.count == 2)
    }
    
    @Test("Join non-existent room throws error")
    func testJoinNonExistentRoom() async {
        let service = RoomService()
        let userID = UUID()
        let roomID = UUID()
        
        await #expect(throws: RoomError.self) {
            try await service.joinRoom(roomID: roomID, userID: userID)
        }
    }
}
