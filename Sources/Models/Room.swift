import Foundation

/// Types of activities available in a room
enum RoomActivityType: String, Codable, Sendable {
    case appleTVPlus = "tv_plus"
    case appleMusic = "music"
    case texasHoldem = "texas_holdem"
    case chess = "chess"
}

/// Represents a room where users can participate in activities
struct Room: LayoverModel {
    let id: UUID
    var name: String
    var hostID: UUID
    var subHostIDs: Set<UUID>
    var participantIDs: Set<UUID>
    var participants: [User]
    var activityType: RoomActivityType
    var maxParticipants: Int
    var isPrivate: Bool
    var createdAt: Date
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        hostID: UUID,
        subHostIDs: Set<UUID> = [],
        participantIDs: Set<UUID> = [],
        participants: [User] = [],
        activityType: RoomActivityType,
        maxParticipants: Int = 20,
        isPrivate: Bool = false,
        createdAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.hostID = hostID
        self.subHostIDs = subHostIDs
        self.participantIDs = participantIDs
        self.participants = participants
        self.activityType = activityType
        self.maxParticipants = maxParticipants
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.metadata = metadata
    }

    var isHost: Bool {
        participantIDs.contains(hostID)
    }

    func isSubHost(userID: UUID) -> Bool {
        subHostIDs.contains(userID)
    }

    mutating func addParticipant(_ userID: UUID) {
        participantIDs.insert(userID)
    }

    mutating func removeParticipant(_ userID: UUID) {
        participantIDs.remove(userID)
    }

    mutating func promoteToSubHost(_ userID: UUID) {
        if participantIDs.contains(userID) {
            subHostIDs.insert(userID)
        }
    }

    mutating func demoteSubHost(_ userID: UUID) {
        subHostIDs.remove(userID)
    }
}
