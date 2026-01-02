import Foundation

/// Texas Hold'em game state
public struct TexasHoldemGame: LayoverModel {
    public let id: UUID
    public var roomID: UUID
    public var players: [TexasHoldemPlayer]
    public var dealerIndex: Int
    public var currentBet: Int
    public var pot: Int
    public var communityCards: [PlayingCard]
    public var gamePhase: GamePhase
    public var currentPlayerIndex: Int
    public var winnerID: UUID?  // ID of the winning player (set during showdown)
    public var winningAmount: Int = 0  // Amount won by the winner

    public enum GamePhase: String, Codable, Sendable {
        case preFlop
        case flop
        case turn
        case river
        case showdown
        case ended
    }

    public init(
        id: UUID = UUID(),
        roomID: UUID,
        players: [TexasHoldemPlayer] = [],
        dealerIndex: Int = 0,
        currentBet: Int = 0,
        pot: Int = 0,
        communityCards: [PlayingCard] = [],
        gamePhase: GamePhase = .preFlop,
        currentPlayerIndex: Int = 0,
        winnerID: UUID? = nil,
        winningAmount: Int = 0
    ) {
        self.id = id
        self.roomID = roomID
        self.players = players
        self.dealerIndex = dealerIndex
        self.currentBet = currentBet
        self.pot = pot
        self.communityCards = communityCards
        self.gamePhase = gamePhase
        self.currentPlayerIndex = currentPlayerIndex
        self.winnerID = winnerID
        self.winningAmount = winningAmount
    }
}

/// Player in a Texas Hold'em game
public struct TexasHoldemPlayer: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var userID: UUID
    public var chips: Int
    public var currentBet: Int
    public var hand: [PlayingCard]
    public var isFolded: Bool
    public var position: Int

    public init(
        id: UUID = UUID(),
        userID: UUID,
        chips: Int = 500,
        currentBet: Int = 0,
        hand: [PlayingCard] = [],
        isFolded: Bool = false,
        position: Int = 0
    ) {
        self.id = id
        self.userID = userID
        self.chips = chips
        self.currentBet = currentBet
        self.hand = hand
        self.isFolded = isFolded
        self.position = position
    }
}

/// Playing card model
public struct PlayingCard: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let rank: Rank
    public let suit: Suit

    public enum Rank: String, Codable, CaseIterable, Sendable {
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case ten = "10"
        case jack = "J"
        case queen = "Q"
        case king = "K"
        case ace = "A"

        public var value: Int {
            switch self {
            case .two: return 2
            case .three: return 3
            case .four: return 4
            case .five: return 5
            case .six: return 6
            case .seven: return 7
            case .eight: return 8
            case .nine: return 9
            case .ten, .jack, .queen, .king: return 10
            case .ace: return 11
            }
        }
    }

    public enum Suit: String, Codable, CaseIterable, Sendable {
        case hearts = "♥️"
        case diamonds = "♦️"
        case clubs = "♣️"
        case spades = "♠️"
    }

    public init(id: UUID = UUID(), rank: Rank, suit: Suit) {
        self.id = id
        self.rank = rank
        self.suit = suit
    }
}
