import Foundation

/// Service for managing Texas Hold'em games
@MainActor
public protocol TexasHoldemServiceProtocol: LayoverService {
    var currentGame: TexasHoldemGame? { get }

    func startGame(roomID: UUID, players: [UUID], preserveChips: [UUID: Int]?) async throws -> TexasHoldemGame
    func loadGame(_ game: TexasHoldemGame)
    func dealCards() async throws
    func bet(playerID: UUID, amount: Int) async throws
    func fold(playerID: UUID) async throws
    func call(playerID: UUID) async throws
    func check(playerID: UUID) async throws
    func raise(playerID: UUID, amount: Int) async throws
    func nextPhase() async throws
    func dealFlop() async throws
    func dealTurn() async throws
    func dealRiver() async throws
    func showdown() async throws
    func endGame() async
}

@MainActor
public final class TexasHoldemService: TexasHoldemServiceProtocol {
    public private(set) var currentGame: TexasHoldemGame?
    private var deck: [PlayingCard] = []
    
    public nonisolated init() {}

    public func loadGame(_ game: TexasHoldemGame) {
        currentGame = game
        // Recreate deck based on cards already dealt
        deck = createDeck()
        // Remove dealt cards from deck
        for player in game.players {
            deck.removeAll { card in player.hand.contains(card) }
        }
        for card in game.communityCards {
            deck.removeAll { $0 == card }
        }
    }

    public func startGame(roomID: UUID, players: [UUID], preserveChips: [UUID: Int]? = nil) async throws -> TexasHoldemGame {
        guard players.count >= 2 && players.count <= 10 else {
            throw GameError.invalidPlayerCount
        }

        let holdemPlayers = players.enumerated().map { index, userID in
            var player = TexasHoldemPlayer(userID: userID, position: index)
            // Preserve chips from previous game if available
            if let preservedChips = preserveChips, let chipCount = preservedChips[userID] {
                player.chips = chipCount
            }
            return player
        }

        let game = TexasHoldemGame(
            roomID: roomID,
            players: holdemPlayers
        )

        currentGame = game
        deck = createDeck()

        return game
    }

    public func dealCards() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        // Shuffle multiple times with different seeds to ensure randomness
        // This prevents both devices from getting the same shuffle
        let shuffleCount = Int.random(in: 3...7)
        for _ in 0..<shuffleCount {
            deck.shuffle()
        }

        // Additional entropy: shuffle again using UUID-based randomness
        var rng = SystemRandomNumberGenerator()
        deck.shuffle(using: &rng)

        // Deal 2 cards to each player
        for i in 0..<game.players.count {
            game.players[i].hand = [deck.removeFirst(), deck.removeFirst()]
        }

        currentGame = game
    }

    public func bet(playerID: UUID, amount: Int) async throws {
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

        print("💰 Bet executed: player \(playerIndex) bet $\(amount)")
        print("   Player current bet: $\(player.currentBet)")
        print("   Game current bet: $\(game.currentBet)")
        print("   Pot: $\(game.pot)")

        // Advance to next player's turn and check if round is complete
        await advanceTurn()
        await checkAndAdvancePhase()
    }

    public func fold(playerID: UUID) async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let playerIndex = game.players.firstIndex(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        game.players[playerIndex].isFolded = true
        currentGame = game

        print("🚫 Fold: player \(playerIndex) folded")

        // Advance to next player's turn and check if round is complete
        await advanceTurn()
        await checkAndAdvancePhase()
    }

    public func call(playerID: UUID) async throws {
        guard let game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let player = game.players.first(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        let callAmount = game.currentBet - player.currentBet
        
        // If currentBet is 0 (nobody has bet yet), treat call as a minimum bet of $10
        if callAmount == 0 {
            print("📞 Call with currentBet=0 - placing minimum bet of $10")
            try await bet(playerID: playerID, amount: 10)
        } else {
            print("📞 Call - matching current bet of $\(game.currentBet)")
            try await bet(playerID: playerID, amount: callAmount)
        }

        // bet() already calls advanceTurn(), so we don't need to call it again
    }

    public func raise(playerID: UUID, amount: Int) async throws {
        guard let game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let player = game.players.first(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        let raiseAmount = (game.currentBet - player.currentBet) + amount
        try await bet(playerID: playerID, amount: raiseAmount)

        // bet() already calls advanceTurn(), so we don't need to call it again
    }

    public func nextPhase() async throws {
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

    public func endGame() async {
        currentGame = nil
        deck = []
    }

    public func check(playerID: UUID) async throws {
        guard let game = currentGame else {
            throw GameError.noActiveGame
        }

        guard let playerIndex = game.players.firstIndex(where: { $0.userID == playerID }) else {
            throw GameError.playerNotFound
        }

        // Check is allowed if no one has bet yet or if player has matched current bet
        guard game.currentBet == game.players[playerIndex].currentBet else {
            throw GameError.invalidMove
        }

        print("✅ Check: player \(playerIndex) checked")

        // Move to next player and check if round is complete
        await advanceTurn()
        await checkAndAdvancePhase()
    }

    public func dealFlop() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard game.gamePhase == .preFlop else {
            throw GameError.invalidMove
        }

        // Shuffle remaining deck for randomness
        deck.shuffle()

        // Deal the flop (3 cards)
        game.communityCards = [deck.removeFirst(), deck.removeFirst(), deck.removeFirst()]
        game.gamePhase = .flop

        currentGame = game
        print("🎴 Flop dealt: \(game.communityCards.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: " "))")
    }

    public func dealTurn() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard game.gamePhase == .flop else {
            throw GameError.invalidMove
        }

        // Shuffle remaining deck for randomness
        deck.shuffle()

        // Deal the turn (1 card)
        let turnCard = deck.removeFirst()
        game.communityCards.append(turnCard)
        game.gamePhase = .turn

        currentGame = game
        print("🎴 Turn dealt: \(turnCard.rank.rawValue)\(turnCard.suit.rawValue)")
    }

    public func dealRiver() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard game.gamePhase == .turn else {
            throw GameError.invalidMove
        }

        // Shuffle remaining deck for randomness
        deck.shuffle()

        // Deal the river (1 card)
        let riverCard = deck.removeFirst()
        game.communityCards.append(riverCard)
        game.gamePhase = .river

        currentGame = game
        print("🎴 River dealt: \(riverCard.rank.rawValue)\(riverCard.suit.rawValue)")
    }

    public func showdown() async throws {
        guard var game = currentGame else {
            throw GameError.noActiveGame
        }

        guard game.gamePhase == .river else {
            throw GameError.invalidMove
        }

        game.gamePhase = .showdown
        
        // Determine winner(s) and award pot
        let activePlayers = game.players.enumerated().filter { !$0.element.isFolded }
        
        print("🏆 SHOWDOWN - Evaluating hands...")
        print("   Pot: $\(game.pot)")
        print("   Community cards: \(game.communityCards.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: " "))")
        
        var bestScore = -1
        var winners: [Int] = []
        
        for (index, player) in activePlayers {
            let handScore = evaluateHand(playerHand: player.hand, communityCards: game.communityCards)
            print("   Player \(index): \(player.hand.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: " ")) - Score: \(handScore)")
            
            if handScore > bestScore {
                bestScore = handScore
                winners = [index]
            } else if handScore == bestScore {
                winners.append(index)
            }
        }
        
        // Award pot to winner(s)
        let winningsPerPlayer = game.pot / winners.count
        for winnerIndex in winners {
            game.players[winnerIndex].chips += winningsPerPlayer
            print("🏆 Player \(winnerIndex) wins $\(winningsPerPlayer)!")
        }
        
        // Set winner ID for UI display (if single winner)
        if winners.count == 1 {
            game.winnerID = game.players[winners[0]].userID
            game.winningAmount = winningsPerPlayer
            print("🎉 Winner set: \(game.winnerID!) wins $\(game.winningAmount)")
        } else {
            // Multiple winners (tie)
            game.winnerID = nil
            game.winningAmount = winningsPerPlayer
            print("🤝 Tie! \(winners.count) players split pot of $\(game.pot)")
        }
        
        // Reset pot and bets for next hand
        game.pot = 0
        game.currentBet = 0
        for i in 0..<game.players.count {
            game.players[i].currentBet = 0
        }
        
        currentGame = game
    }
    
    /// Evaluate a poker hand - returns a score (higher is better)
    /// This is a simplified evaluator that considers high card and pairs
    private func evaluateHand(playerHand: [PlayingCard], communityCards: [PlayingCard]) -> Int {
        let allCards = playerHand + communityCards
        
        // Count card ranks
        var rankCounts: [PlayingCard.Rank: Int] = [:]
        for card in allCards {
            rankCounts[card.rank, default: 0] += 1
        }
        
        // Check for pairs, three of a kind, etc.
        let pairs = rankCounts.filter { $0.value == 2 }.keys.sorted { $0.value > $1.value }
        let threeOfKind = rankCounts.filter { $0.value == 3 }.keys.sorted { $0.value > $1.value }
        let fourOfKind = rankCounts.filter { $0.value == 4 }.keys.sorted { $0.value > $1.value }
        
        // Score calculation (simplified)
        var score = 0
        
        if !fourOfKind.isEmpty {
            // Four of a kind
            score = 8000 + fourOfKind.first!.value
        } else if !threeOfKind.isEmpty && !pairs.isEmpty {
            // Full house
            score = 7000 + threeOfKind.first!.value * 10 + pairs.first!.value
        } else if !threeOfKind.isEmpty {
            // Three of a kind
            score = 4000 + threeOfKind.first!.value
        } else if pairs.count >= 2 {
            // Two pair
            score = 3000 + pairs[0].value * 10 + pairs[1].value
        } else if pairs.count == 1 {
            // One pair
            score = 2000 + pairs.first!.value
        } else {
            // High card
            let highCard = allCards.map { $0.rank.value }.max() ?? 0
            score = 1000 + highCard
        }
        
        return score
    }

    private func advanceTurn() async {
        guard var game = currentGame else { return }

        // Move to next player
        game.currentPlayerIndex = (game.currentPlayerIndex + 1) % game.players.count

        // Skip folded players
        while game.players[game.currentPlayerIndex].isFolded {
            game.currentPlayerIndex = (game.currentPlayerIndex + 1) % game.players.count
        }

        currentGame = game
    }

    /// Check if betting round is complete and automatically advance to next phase
    private func checkAndAdvancePhase() async {
        guard var game = currentGame else { return }

        // Get active (non-folded) players
        let activePlayers = game.players.filter { !$0.isFolded }
        
        // If only one player left, they win
        if activePlayers.count == 1 {
            let winnerIndex = game.players.firstIndex(where: { !$0.isFolded })!
            let potAmount = game.pot
            
            // Award pot to winner
            game.players[winnerIndex].chips += potAmount
            
            // Set winner info for UI
            game.winnerID = game.players[winnerIndex].userID
            game.winningAmount = potAmount
            game.gamePhase = .showdown  // Use showdown to display winner
            
            print("🏆 Player \(winnerIndex) wins by default (others folded)!")
            print("   Won: $\(potAmount)")
            print("   New chip count: $\(game.players[winnerIndex].chips)")
            
            // Reset pot and bets
            game.pot = 0
            game.currentBet = 0
            for i in 0..<game.players.count {
                game.players[i].currentBet = 0
            }
            
            currentGame = game
            return
        }

        // Check if all active players have matched the current bet
        let allMatched = activePlayers.allSatisfy { $0.currentBet == game.currentBet }
        
        if allMatched {
            print("✅ Betting round complete - all players matched at $\(game.currentBet)")
            print("   Current phase: \(game.gamePhase.rawValue)")
            print("   Pot: $\(game.pot)")
            
            // Reset current bets for next round (but keep the pot)
            for i in 0..<game.players.count {
                game.players[i].currentBet = 0
            }
            game.currentBet = 0
            game.currentPlayerIndex = 0
            
            // Auto-advance to next phase
            switch game.gamePhase {
            case .preFlop:
                print("   → Auto-dealing flop")
                currentGame = game
                try? await dealFlop()
                
            case .flop:
                print("   → Auto-dealing turn")
                currentGame = game
                try? await dealTurn()
                
            case .turn:
                print("   → Auto-dealing river")
                currentGame = game
                try? await dealRiver()
                
            case .river:
                print("   → Going to showdown")
                currentGame = game
                try? await showdown()
                
            case .showdown, .ended:
                currentGame = game
                break
            }
        } else {
            print("⏳ Betting round continuing...")
            print("   Current bet: $\(game.currentBet)")
            for (i, player) in activePlayers.enumerated() {
                print("   Player \(i): bet $\(player.currentBet)")
            }
            currentGame = game
        }
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

public enum GameError: LocalizedError {
    case noActiveGame
    case invalidPlayerCount
    case playerNotFound
    case insufficientChips
    case invalidMove

    public var errorDescription: String? {
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
