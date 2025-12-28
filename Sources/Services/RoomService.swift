import Foundation
import OSLog

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
    
    // Game sync methods
    func saveGame(_ game: TexasHoldemGame)
    func getGame(gameID: UUID) -> TexasHoldemGame?
    func getActiveGame(for roomID: UUID) -> TexasHoldemGame?
}

@MainActor
final class RoomService: RoomServiceProtocol {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "RoomService")
    private(set) var rooms: [Room] = []
    private let defaults = NSUbiquitousKeyValueStore.default
    private let roomsKey = "layoverlounge.rooms"
    private let gamesKey = "layoverlounge.games"
    private(set) var games: [UUID: TexasHoldemGame] = [:] // gameID -> game

    init() {
        loadRooms()
        loadGames()
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
        loadGames()
    }

    private func loadRooms() {
        guard let data = defaults.data(forKey: roomsKey),
            let decoded = try? JSONDecoder().decode([Room].self, from: data)
        else {
            rooms = []
            return
        }
        rooms = decoded
    }
    
    private func loadGames() {
        guard let data = defaults.data(forKey: gamesKey),
            let decoded = try? JSONDecoder().decode([UUID: TexasHoldemGame].self, from: data)
        else {
            self.games = [:]
            return
        }
        self.games = decoded
        logger.info("📥 Loaded \(self.games.count) games from iCloud")
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

    func updateRoom(roomID: UUID, name: String, isPrivate: Bool, maxParticipants: Int) async throws
    {
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
    
    // MARK: - Game Sync Methods
    
    func saveGame(_ game: TexasHoldemGame) {
        logger.info("💾 Saving game \(game.id) to iCloud...")
        games[game.id] = game
        saveGames()
        
        // Update room's active game
        if let index = rooms.firstIndex(where: { $0.id == game.roomID }) {
            rooms[index].activeGameID = game.id
            saveRooms()
            logger.info("   ✅ Updated room \(game.roomID) activeGameID")
        }
        
        logger.info("   ✅ Game saved successfully. Total games: \(games.count)")
    }
    
    func getGame(gameID: UUID) -> TexasHoldemGame? {
        logger.info("🔍 Looking for game: \(gameID)")
        let game = games[gameID]
        logger.info(game == nil ? "   ❌ Game not found" : "   ✅ Game found")
        return game
    }
    
    func getActiveGame(for roomID: UUID) -> TexasHoldemGame? {
        logger.info("🔍 Looking for active game in room: \(roomID)")
        guard let room = rooms.first(where: { $0.id == roomID }) else {
            logger.info("   ❌ Room not found")
            return nil
        }
        
        guard let gameID = room.activeGameID else {
            logger.info("   ℹ️ Room has no active game")
            return nil
        }
        
        let game = games[gameID]
        logger.info(game == nil ? "   ❌ Game \(gameID) not found in games dict" : "   ✅ Found active game \(gameID)")
        return game
    }
    
    private func saveGames() {
        guard let encoded = try? JSONEncoder().encode(games) else {
            logger.error("Failed to encode games")
            return
        }
        defaults.set(encoded, forKey: gamesKey)
        defaults.synchronize()
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
