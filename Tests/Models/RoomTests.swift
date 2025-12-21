import Testing
import Foundation
@testable import Layover

/// Tests for Room model
@Suite("Room Model Tests")
struct RoomTests {
    
    @Test("Room initialization")
    func testRoomInitialization() {
        let hostID = UUID()
        let room = Room(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleTVPlus
        )
        
        #expect(room.name == "Test Room")
        #expect(room.hostID == hostID)
        #expect(room.activityType == .appleTVPlus)
        #expect(room.participantIDs.isEmpty)
        #expect(room.subHostIDs.isEmpty)
        #expect(room.maxParticipants == 20)
        #expect(room.isPrivate == false)
    }
    
    @Test("Add participant to room")
    func testAddParticipant() {
        let hostID = UUID()
        var room = Room(
            name: "Test Room",
            hostID: hostID,
            activityType: .texasHoldem
        )
        
        let userID = UUID()
        room.addParticipant(userID)
        
        #expect(room.participantIDs.contains(userID))
        #expect(room.participantIDs.count == 1)
    }
    
    @Test("Remove participant from room")
    func testRemoveParticipant() {
        let hostID = UUID()
        let userID = UUID()
        var room = Room(
            name: "Test Room",
            hostID: hostID,
            participantIDs: [userID],
            activityType: .appleMusic
        )
        
        room.removeParticipant(userID)
        
        #expect(!room.participantIDs.contains(userID))
        #expect(room.participantIDs.isEmpty)
    }
    
    @Test("Promote user to sub-host")
    func testPromoteToSubHost() {
        let hostID = UUID()
        let userID = UUID()
        var room = Room(
            name: "Test Room",
            hostID: hostID,
            participantIDs: [userID],
            activityType: .appleTVPlus
        )
        
        room.promoteToSubHost(userID)
        
        #expect(room.isSubHost(userID: userID))
        #expect(room.subHostIDs.contains(userID))
    }
    
    @Test("Demote sub-host")
    func testDemoteSubHost() {
        let hostID = UUID()
        let userID = UUID()
        var room = Room(
            name: "Test Room",
            hostID: hostID,
            subHostIDs: [userID],
            activityType: .chess
        )
        
        room.demoteSubHost(userID)
        
        #expect(!room.isSubHost(userID: userID))
        #expect(room.subHostIDs.isEmpty)
    }
    
    @Test("Cannot promote non-participant to sub-host")
    func testCannotPromoteNonParticipant() {
        let hostID = UUID()
        let userID = UUID()
        var room = Room(
            name: "Test Room",
            hostID: hostID,
            activityType: .texasHoldem
        )
        
        room.promoteToSubHost(userID)
        
        #expect(!room.isSubHost(userID: userID))
    }
    
    @Test("Room conforms to Codable")
    func testRoomCodable() throws {
        let room = Room(
            name: "Test Room",
            hostID: UUID(),
            activityType: .appleTVPlus
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(room)
        let decodedRoom = try decoder.decode(Room.self, from: data)
        
        #expect(decodedRoom.name == room.name)
        #expect(decodedRoom.hostID == room.hostID)
        #expect(decodedRoom.activityType == room.activityType)
    }
}
