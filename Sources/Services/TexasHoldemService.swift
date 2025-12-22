import Foundation

/// Service for managing Texas Hold'em games
@MainActor
protocol TexasHoldemServiceProtocol: LayoverService {
    var currentGame: TexasHoldemGame? { get }

    func startGame(roomID: UUID, players: [UUID]) async throws -> TexasHoldemGame
    func dealCards() async throws
    func bet(playerID: UUID, amount: Int) async throws
    func fold(playerID: UUID) async throws
    func call(playerID: UUID) async throws
    func raise(playerID: UUID, amount: Int) async throws
    func nextPhase() async throws
    func endGame() async
}

@MainActor
final class TexasHoldemService: TexasHoldemServiceProtocol {
    private(set) var currentGame: TexasHoldemGame?
    private var deck: [PlayingCard] = []

    func startGame(roomID: UUID, players: [UUID]) async throws -> TexasHoldemGame {
        guard players.count >= 2 && players.count <= 10 else {
            throw GameError.invalidPlayerCount
        }

        let holdemPlayers = players.enumerated().map { index, userID in
            TexasHoldemPlayer(userID: userID, position: index)
        }

        let game = TexasHoldemGame(
            roomID: roomID,
            players: holdemPlayers
        )

        currentGame = game
        deck = createDeck()

        return game
    }

    func dealCards() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        deck.shuffle()

        // Deal 2 cards to each player
        for i in 0..<game.players.count {
            game.players[i].hand = [deck.removeFirst(), deck.removeFirst()]
        }

        currentGame = game
    }

    func bet(playerID: UUID, amount: Int) async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let playerIndex = game.players.firstIndex(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        var player = game.players[playerIndex]
        guard player.chips >= amount else {
            throw GameError.insufficientChips
        }

        player.chips -= amount
        player.currentBet += amount
        game.pot += amount
        game.currentBet = max(game.currentBet, player.currentBet)

        game.players[playerIndex] = player
        currentGame = game
    }

    func fold(playerID: UUID) async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let playerIndex = game.players.firstIndex(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        game.players[playerIndex].isFolded = true
        currentGame = game
    }

    func call(playerID: UUID) async throws {
        guard let game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let player = game.players.first(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        let callAmount = game.currentBet - player.currentBet
        try await bet(playerID: playerID, amount: callAmount)
    }

    func raise(playerID: UUID, amount: Int) async throws {
        guard let game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let player = game.players.first(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        let raiseAmount = (game.currentBet - player.currentBet) + amount
        try await bet(playerID: playerID, amount: raiseAmount)
    }

    func nextPhase() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        switch game.gamePhase {
        case .preFlop:
            // Deal the flop (3 cards)
            game.communityCards = [deck.removeFirst(), deck.removeFirst(), deck.removeFirst()]
            game.gamePhase = .flop
        case .flop:
            // Deal the turn (1 card)
            game.communityCards.append(deck.removeFirst())
            game.gamePhase = .turn
        case .turn:
            // Deal the river (1 card)
            game.communityCards.append(deck.removeFirst())
            game.gamePhase = .river
        case .river:
            game.gamePhase = .showdown
        case .showdown:
            game.gamePhase = .ended
        case .ended:
            break
        }

        currentGame = game
    }

    func endGame() async {
        currentGame = nil
        deck = []
    }

    private func createDeck() -> [PlayingCard] {
        var cards: [PlayingCard] = []
        for suit in PlayingCard.Suit.allCases {
            for rank in PlayingCard.Rank.allCases {
                cards.append(PlayingCard(rank: rank, suit: suit))
            }
        }
        return cards
    }
}

enum GameError: LocalizedError {
    case noActiveGame
    case invalidPlayerCount
    case playerNotFound
    case insufficientChips
    case invalidMove

    var errorDescription: String? {
        switch self {
        case .noActiveGame:
            return "No active game"
        case .invalidPlayerCount:
            return "Invalid number of players (must be 2-10)"
        case .playerNotFound:
            return "Player not found in game"
        case .insufficientChips:
            return "Insufficient chips"
        case .invalidMove:
            return "Invalid move"
        }
    }
}
