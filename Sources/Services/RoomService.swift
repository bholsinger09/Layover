import Foundation

/// Service for managing rooms
@MainActor
protocol RoomServiceProtocol: LayoverService {
    var rooms: [Room] { get }
    
    func createRoom(name: String, hostID: UUID, activityType: RoomActivityType) async throws -> Room
    func joinRoom(roomID: UUID, userID: UUID) async throws
    func leaveRoom(roomID: UUID, userID: UUID) async throws
    func promoteToSubHost(roomID: UUID, userID: UUID) async throws
    func demoteSubHost(roomID: UUID, userID: UUID) async throws
    func deleteRoom(roomID: UUID) async throws
    func fetchRooms() async throws -> [Room]
}

@MainActor
final class RoomService: RoomServiceProtocol {
    private(set) var rooms: [Room] = []
    
    func createRoom(name: String, hostID: UUID, activityType: RoomActivityType) async throws -> Room {
        let room = Room(
            name: name,
            hostID: hostID,
            participantIDs: [hostID],
            activityType: activityType
        )
        
        rooms.append(room)
        return room
    }
    
    func joinRoom(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        
        guard room.participantIDs.count < room.maxParticipants else {
            throw RoomError.roomFull
        }
        
        room.addParticipant(userID)
        rooms[index] = room
    }
    
    func leaveRoom(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.removeParticipant(userID)
        
        // If host leaves, delete the room
        if userID == room.hostID {
            rooms.remove(at: index)
        } else {
            rooms[index] = room
        }
    }
    
    func promoteToSubHost(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.promoteToSubHost(userID)
        rooms[index] = room
    }
    
    func demoteSubHost(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.demoteSubHost(userID)
        rooms[index] = room
    }
    
    func deleteRoom(roomID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        rooms.remove(at: index)
    }
    
    func fetchRooms() async throws -> [Room] {
        // In a real app, this would fetch from a backend
        return rooms
    }
}

enum RoomError: LocalizedError {
    case roomNotFound
    case roomFull
    case notAuthorized
    
    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            return "Room not found"
        case .roomFull:
            return "Room is at maximum capacity"
        case .notAuthorized:
            return "You are not authorized to perform this action"
        }
    }
}
