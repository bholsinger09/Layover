import Foundation

/// Service for managing rooms
@MainActor
protocol RoomServiceProtocol: LayoverService {
    var rooms: [Room] { get }
    
    func createRoom(name: String, host: User, activityType: RoomActivityType) async throws -> Room
    func updateRoom(roomID: UUID, name: String, isPrivate: Bool, maxParticipants: Int) async throws
    func joinRoom(roomID: UUID, user: User) async throws
    func leaveRoom(roomID: UUID, userID: UUID) async throws
    func promoteToSubHost(roomID: UUID, userID: UUID) async throws
    func demoteSubHost(roomID: UUID, userID: UUID) async throws
    func deleteRoom(roomID: UUID) async throws
    func fetchRooms() async throws -> [Room]
}

@MainActor
final class RoomService: RoomServiceProtocol {
    private(set) var rooms: [Room] = []
    private let defaults = NSUbiquitousKeyValueStore.default
    private let roomsKey = "layoverlounge.rooms"
    
    init() {
        loadRooms()
        // Observe changes from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudDataChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: defaults
        )
    }
    
    @objc private func cloudDataChanged() {
        loadRooms()
    }
    
    private func loadRooms() {
        guard let data = defaults.data(forKey: roomsKey),
              let decoded = try? JSONDecoder().decode([Room].self, from: data) else {
            rooms = []
            return
        }
        rooms = decoded
    }
    
    private func saveRooms() {
        guard let encoded = try? JSONEncoder().encode(rooms) else { return }
        defaults.set(encoded, forKey: roomsKey)
        defaults.synchronize()
    }
    
    func createRoom(name: String, host: User, activityType: RoomActivityType) async throws -> Room {
        let room = Room(
            name: name,
            hostID: host.id,
            participantIDs: [host.id],
            participants: [host],
            activityType: activityType
        )
        
        rooms.append(room)
        saveRooms()
        return room
    }
    
    func updateRoom(roomID: UUID, name: String, isPrivate: Bool, maxParticipants: Int) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.name = name
        room.isPrivate = isPrivate
        room.maxParticipants = maxParticipants
        rooms[index] = room
        saveRooms()
    }
    
    func joinRoom(roomID: UUID, user: User) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        
        guard room.participantIDs.count < room.maxParticipants else {
            throw RoomError.roomFull
        }
        
        room.addParticipant(user.id)
        if !room.participants.contains(where: { $0.id == user.id }) {
            room.participants.append(user)
        }
        rooms[index] = room
        saveRooms()
    }
    
    func leaveRoom(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.removeParticipant(userID)
        room.participants.removeAll { $0.id == userID }
        
        // If host leaves, delete the room
        if userID == room.hostID {
            rooms.remove(at: index)
        } else {
            rooms[index] = room
        }
        saveRooms()
    }
    
    func promoteToSubHost(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.promoteToSubHost(userID)
        rooms[index] = room
        saveRooms()
    }
    
    func demoteSubHost(roomID: UUID, userID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        var room = rooms[index]
        room.demoteSubHost(userID)
        rooms[index] = room
        saveRooms()
    }
    
    func deleteRoom(roomID: UUID) async throws {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else {
            throw RoomError.roomNotFound
        }
        
        rooms.remove(at: index)
        saveRooms()
    }
    
    func fetchRooms() async throws -> [Room] {
        loadRooms()
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
