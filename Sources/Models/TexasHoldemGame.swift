import Foundation

/// Texas Hold'em game state
struct TexasHoldemGame: LayoverModel {
    let id: UUID
    var roomID: UUID
    var players: [TexasHoldemPlayer]
    var dealerIndex: Int
    var currentBet: Int
    var pot: Int
    var communityCards: [PlayingCard]
    var gamePhase: GamePhase
    var currentPlayerIndex: Int

    enum GamePhase: String, Codable, Sendable {
        case preFlop
        case flop
        case turn
        case river
        case showdown
        case ended
    }

    init(
        id: UUID = UUID(),
        roomID: UUID,
        players: [TexasHoldemPlayer] = [],
        dealerIndex: Int = 0,
        currentBet: Int = 0,
        pot: Int = 0,
        communityCards: [PlayingCard] = [],
        gamePhase: GamePhase = .preFlop,
        currentPlayerIndex: Int = 0
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
    }
}

/// Player in a Texas Hold'em game
struct TexasHoldemPlayer: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var userID: UUID
    var chips: Int
    var currentBet: Int
    var hand: [PlayingCard]
    var isFolded: Bool
    var position: Int

    init(
        id: UUID = UUID(),
        userID: UUID,
        chips: Int = 1000,
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
struct PlayingCard: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let rank: Rank
    let suit: Suit

    enum Rank: String, Codable, CaseIterable, Sendable {
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

        var value: Int {
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

    enum Suit: String, Codable, CaseIterable, Sendable {
        case hearts = "♥️"
        case diamonds = "♦️"
        case clubs = "♣️"
        case spades = "♠️"
    }

    init(id: UUID = UUID(), rank: Rank, suit: Suit) {
        self.id = id
        self.rank = rank
        self.suit = suit
    }
}
