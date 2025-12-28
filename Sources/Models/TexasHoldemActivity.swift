import Foundation
import GroupActivities

/// SharePlay activity specifically for Texas Hold'em poker game
struct TexasHoldemActivity: GroupActivity {
    static let activityIdentifier = "com.bholsinger.LayoverLounge.texasholdem"
    
    let roomID: UUID
    let gameID: UUID
    let roomName: String?
    
    var metadata: GroupActivityMetadata {
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
enum TexasHoldemMessage: Codable {
    case gameStarted(roomID: UUID, gameID: UUID, playerIDs: [UUID])
    case gameStateUpdate(TexasHoldemGameState)
    case playerAction(PlayerAction)
    case phaseAdvanced(GamePhase)
    case gameEnded(winnerID: UUID?)
    
    enum PlayerAction: Codable {
        case fold(playerID: UUID)
        case check(playerID: UUID)
        case bet(playerID: UUID, amount: Int)
        case call(playerID: UUID)
        case raise(playerID: UUID, amount: Int)
    }
    
    enum GamePhase: String, Codable {
        case preFlop
        case flop
        case turn
        case river
        case showdown
    }
}

/// Simplified game state for SharePlay synchronization
struct TexasHoldemGameState: Codable {
    let gameID: UUID
    let currentPlayerIndex: Int
    let pot: Int
    let currentBet: Int
    let phase: String
    let communityCards: [PlayingCardData]
    let playerStates: [PlayerState]
    
    struct PlayerState: Codable {
        let id: UUID
        let chips: Int
        let currentBet: Int
        let hasFolded: Bool
        let cards: [PlayingCardData]? // nil for other players until showdown
    }
}

/// Simplified playing card for Codable conformance
struct PlayingCardData: Codable {
    let rank: String
    let suit: String
}
