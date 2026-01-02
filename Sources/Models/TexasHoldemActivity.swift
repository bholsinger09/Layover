import Foundation
import GroupActivities

/// SharePlay activity specifically for Texas Hold'em poker game
public struct TexasHoldemActivity: GroupActivity {
    // IMPORTANT: This identifier must match exactly across all devices and builds
    // Format: <bundle-id>.<activity-name>
    public static let activityIdentifier = "com.bholsinger.LayoverLounge.texasholdem"
    
    public let roomID: UUID
    public let gameID: UUID
    public let roomName: String?
    
    public var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        
        if let name = roomName {
            meta.title = name
            meta.subtitle = "Texas Hold'em Poker"
        } else {
            meta.title = "Texas Hold'em"
            meta.subtitle = "LayoverLounge Poker"
        }
        
        meta.type = .generic
        
        return meta
    }
}

/// Messages that can be sent between participants in a Texas Hold'em game
public enum TexasHoldemMessage: Codable {
    case gameStarted(roomID: UUID, gameID: UUID, playerIDs: [UUID])
    case gameStateUpdate(TexasHoldemGameState)
    case playerAction(PlayerAction)
    case phaseAdvanced(GamePhase)
    case gameEnded(winnerID: UUID?)
    case testPing(from: String, message: String, senderID: UUID)
    case testPong(from: String, message: String, senderID: UUID)
    
    public enum PlayerAction: Codable {
        case fold(playerID: UUID)
        case check(playerID: UUID)
        case bet(playerID: UUID, amount: Int)
        case call(playerID: UUID)
        case raise(playerID: UUID, amount: Int)
    }
    
    public enum GamePhase: String, Codable {
        case preFlop
        case flop
        case turn
        case river
        case showdown
    }
}

/// Simplified game state for SharePlay synchronization
public struct TexasHoldemGameState: Codable {
    public let gameID: UUID
    public let currentPlayerIndex: Int
    public let pot: Int
    public let currentBet: Int
    public let phase: String
    public let communityCards: [PlayingCardData]
    public let playerStates: [PlayerState]
    public let winnerID: UUID?  // ID of the winning player (set during showdown)
    public let winningAmount: Int  // Amount won
    
    public struct PlayerState: Codable {
        public let id: UUID
        public let chips: Int
        public let currentBet: Int
        public let hasFolded: Bool
        public let cards: [PlayingCardData]? // nil for other players until showdown
    }
}

/// Simplified playing card for Codable conformance
public struct PlayingCardData: Codable {
    public let rank: String
    public let suit: String
}
