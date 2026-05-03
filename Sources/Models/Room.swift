import Foundation

/// Constants for room configuration
public enum RoomConstants {
    public static let defaultMaxParticipants = 20
    public static let minParticipants = 2
    public static let maxPossibleParticipants = 100
}

/// Types of activities available in a room
public enum RoomActivityType: String, Codable, Sendable {
    case appleTVPlus = "tv_plus"
    case appleMusic = "music"
    case chess = "chess"
}

/// Represents a room where users can participate in activities
public struct Room: LayoverModel {
    public let id: UUID
    public var name: String
    public var hostID: UUID
    public var subHostIDs: Set<UUID>
    public var participantIDs: Set<UUID>
    public var participants: [User]
    public var activityType: RoomActivityType
    public var maxParticipants: Int
    public var isPrivate: Bool
    public var createdAt: Date
    public var metadata: [String: String]
    public var activeGameID: UUID? // Track active game
    
    // Global directory features
    public var primaryLanguage: String? // ISO 639-1 language code
    public var supportedLanguages: [String] // Additional languages
    public var region: String? // ISO 3166-1 alpha-2 region code
    public var timezone: String? // IANA timezone identifier
    public var culturalEventId: UUID? // Link to cultural event
    public var tags: [String] // Searchable tags
    public var isGloballyVisible: Bool // Show in global directory

    public init(
        id: UUID = UUID(),
        name: String,
        hostID: UUID,
        subHostIDs: Set<UUID> = [],
        participantIDs: Set<UUID> = [],
        participants: [User] = [],
        activityType: RoomActivityType,
        maxParticipants: Int = RoomConstants.defaultMaxParticipants,
        isPrivate: Bool = false,
        createdAt: Date = Date(),
        metadata: [String: String] = [:],
        activeGameID: UUID? = nil,
        primaryLanguage: String? = nil,
        supportedLanguages: [String] = [],
        region: String? = nil,
        timezone: String? = nil,
        culturalEventId: UUID? = nil,
        tags: [String] = [],
        isGloballyVisible: Bool = false
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
        self.activeGameID = activeGameID
        self.primaryLanguage = primaryLanguage
        self.supportedLanguages = supportedLanguages
        self.region = region
        self.timezone = timezone
        self.culturalEventId = culturalEventId
        self.tags = tags
        self.isGloballyVisible = isGloballyVisible
    }

    public var isHost: Bool {
        participantIDs.contains(hostID)
    }

    public func isSubHost(userID: UUID) -> Bool {
        subHostIDs.contains(userID)
    }

    public mutating func addParticipant(_ userID: UUID) {
        participantIDs.insert(userID)
    }

    public mutating func removeParticipant(_ userID: UUID) {
        participantIDs.remove(userID)
    }

    public mutating func promoteToSubHost(_ userID: UUID) {
        if participantIDs.contains(userID) {
            subHostIDs.insert(userID)
        }
    }

    public mutating func demoteSubHost(_ userID: UUID) {
        subHostIDs.remove(userID)
    }
}
