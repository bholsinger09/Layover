import Foundation

/// Game state for the Jacks game
public struct JacksGame: LayoverModel {
    public let id: UUID
    public var roomID: UUID
    public var playerID: UUID
    public var score: Int
    public var round: Int
    public var totalJacks: Int
    public var pickedUpJacks: Int
    public var gamePhase: GamePhase
    public var highScore: Int
    public var jackPositions: [JackPosition]

    public enum GamePhase: String, Codable, Sendable {
        case ready
        case ballDropped
        case ballBouncing
        case collecting
        case roundComplete
        case gameOver
    }

    public init(
        id: UUID = UUID(),
        roomID: UUID,
        playerID: UUID,
        score: Int = 0,
        round: Int = 1,
        totalJacks: Int = 10,
        pickedUpJacks: Int = 0,
        gamePhase: GamePhase = .ready,
        highScore: Int = 0,
        jackPositions: [JackPosition] = []
    ) {
        self.id = id
        self.roomID = roomID
        self.playerID = playerID
        self.score = score
        self.round = round
        self.totalJacks = totalJacks
        self.pickedUpJacks = pickedUpJacks
        self.gamePhase = gamePhase
        self.highScore = highScore
        self.jackPositions = jackPositions
    }
}

/// Position of a single jack on the floor
public struct JackPosition: Codable, Hashable, Sendable {
    public let id: UUID
    public var x: Float
    public var z: Float
    public var rotation: Float
    public var isPickedUp: Bool

    public init(
        id: UUID = UUID(),
        x: Float,
        z: Float,
        rotation: Float = 0,
        isPickedUp: Bool = false
    ) {
        self.id = id
        self.x = x
        self.z = z
        self.rotation = rotation
        self.isPickedUp = isPickedUp
    }
}
