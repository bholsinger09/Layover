import Foundation

/// AI service for computer opponents in Texas Hold'em
@MainActor
final class TexasHoldemAIService {
    
    /// Make an AI decision based on current game state
    /// Returns the action the AI should take
    func makeDecision(
        game: TexasHoldemGame,
        aiPlayerID: UUID
    ) async -> AIAction {
        guard let aiPlayer = game.players.first(where: { $0.userID == aiPlayerID }) else {
            return .fold
        }
        
        // Don't act if already folded
        if aiPlayer.isFolded {
            return .fold
        }
        
        // Evaluate hand strength
        let handStrength = evaluateHandStrength(
            playerHand: aiPlayer.hand,
            communityCards: game.communityCards,
            gamePhase: game.gamePhase
        )
        
        let callAmount = game.currentBet - aiPlayer.currentBet
        let potOdds = callAmount > 0 ? Double(callAmount) / Double(game.pot + callAmount) : 0.0
        
        print("🤖 AI Decision Making:")
        print("   Hand strength: \(handStrength)")
        print("   Current bet: $\(game.currentBet)")
        print("   AI current bet: $\(aiPlayer.currentBet)")
        print("   Call amount: $\(callAmount)")
        print("   Pot: $\(game.pot)")
        print("   Pot odds: \(String(format: "%.2f", potOdds))")
        print("   AI chips: $\(aiPlayer.chips)")
        
        // Decision logic based on hand strength and game phase
        let decision = makeStrategyDecision(
            handStrength: handStrength,
            callAmount: callAmount,
            pot: game.pot,
            aiChips: aiPlayer.chips,
            gamePhase: game.gamePhase
        )
        
        print("   Decision: \(decision)")
        return decision
    }
    
    private func makeStrategyDecision(
        handStrength: HandStrength,
        callAmount: Int,
        pot: Int,
        aiChips: Int,
        gamePhase: TexasHoldemGame.GamePhase
    ) -> AIAction {
        
        // Pre-flop strategy
        if gamePhase == .preFlop {
            switch handStrength {
            case .veryStrong, .strong:
                // Raise with strong hands
                return .bet(amount: max(20, callAmount + 10))
            case .moderate:
                // Call with moderate hands
                return callAmount > 0 ? .call : .check
            case .weak, .veryWeak:
                // Fold weak hands if there's a bet
                return callAmount > 0 ? .fold : .check
            }
        }
        
        // Post-flop strategy
        let potOdds = callAmount > 0 ? Double(callAmount) / Double(pot + callAmount) : 0.0
        
        switch handStrength {
        case .veryStrong:
            // Always bet/raise with very strong hands
            if callAmount == 0 {
                return .bet(amount: min(30, aiChips / 2))
            } else {
                return .bet(amount: min(callAmount + 20, aiChips))
            }
            
        case .strong:
            // Bet or call with strong hands
            if callAmount == 0 {
                return .bet(amount: 20)
            } else if callAmount <= 30 {
                return .call
            } else {
                // Fold to large bets
                return .fold
            }
            
        case .moderate:
            // Call small bets, check otherwise
            if callAmount == 0 {
                return .check
            } else if callAmount <= 20 && potOdds < 0.5 {
                return .call
            } else {
                return .fold
            }
            
        case .weak:
            // Check or fold
            if callAmount == 0 {
                // Occasionally bluff
                if Double.random(in: 0...1) < 0.15 {
                    return .bet(amount: 15)
                }
                return .check
            } else {
                return .fold
            }
            
        case .veryWeak:
            // Always fold or check
            return callAmount > 0 ? .fold : .check
        }
    }
    
    private func evaluateHandStrength(
        playerHand: [PlayingCard],
        communityCards: [PlayingCard],
        gamePhase: TexasHoldemGame.GamePhase
    ) -> HandStrength {
        
        // Pre-flop evaluation based on hole cards only
        if gamePhase == .preFlop {
            return evaluatePreFlopHand(playerHand)
        }
        
        // Post-flop evaluation with community cards
        let allCards = playerHand + communityCards
        return evaluatePostFlopHand(allCards)
    }
    
    private func evaluatePreFlopHand(_ hand: [PlayingCard]) -> HandStrength {
        guard hand.count == 2 else { return .veryWeak }
        
        let card1 = hand[0]
        let card2 = hand[1]
        
        let isPair = card1.rank == card2.rank
        let isSuited = card1.suit == card2.suit
        let highCard = max(card1.rank.value, card2.rank.value)
        let lowCard = min(card1.rank.value, card2.rank.value)
        
        // Premium pairs (AA, KK, QQ, JJ)
        if isPair && highCard >= 11 {
            return .veryStrong
        }
        
        // Medium pairs (10-10 through 7-7)
        if isPair && highCard >= 7 {
            return .strong
        }
        
        // High cards suited (AK, AQ, AJ suited)
        if isSuited && highCard == 14 && lowCard >= 11 {
            return .strong
        }
        
        // High cards offsuit (AK, AQ)
        if highCard == 14 && lowCard >= 12 {
            return .moderate
        }
        
        // Suited connectors or one-gappers
        if isSuited && abs(highCard - lowCard) <= 2 && highCard >= 9 {
            return .moderate
        }
        
        // Any two face cards
        if highCard >= 11 && lowCard >= 11 {
            return .moderate
        }
        
        // One high card
        if highCard >= 11 {
            return .weak
        }
        
        return .veryWeak
    }
    
    private func evaluatePostFlopHand(_ cards: [PlayingCard]) -> HandStrength {
        guard !cards.isEmpty else { return .veryWeak }
        
        // Count card ranks
        var rankCounts: [PlayingCard.Rank: Int] = [:]
        for card in cards {
            rankCounts[card.rank, default: 0] += 1
        }
        
        // Check for pairs, trips, quads
        let pairs = rankCounts.filter { $0.value == 2 }.keys.sorted { $0.value > $1.value }
        let threeOfKind = rankCounts.filter { $0.value == 3 }.keys.sorted { $0.value > $1.value }
        let fourOfKind = rankCounts.filter { $0.value == 4 }.keys.sorted { $0.value > $1.value }
        
        // Check for flush
        var suitCounts: [PlayingCard.Suit: Int] = [:]
        for card in cards {
            suitCounts[card.suit, default: 0] += 1
        }
        let hasFlush = suitCounts.values.contains { $0 >= 5 }
        
        // Check for straight
        let sortedRanks = Set(cards.map { $0.rank.value }).sorted()
        var hasStraight = false
        if sortedRanks.count >= 5 {
            for i in 0...(sortedRanks.count - 5) {
                if sortedRanks[i + 4] - sortedRanks[i] == 4 {
                    hasStraight = true
                    break
                }
            }
        }
        
        // Evaluate hand
        if !fourOfKind.isEmpty {
            return .veryStrong  // Four of a kind
        }
        
        if !threeOfKind.isEmpty && !pairs.isEmpty {
            return .veryStrong  // Full house
        }
        
        if hasFlush {
            return .veryStrong  // Flush
        }
        
        if hasStraight {
            return .strong  // Straight
        }
        
        if !threeOfKind.isEmpty {
            return .strong  // Three of a kind
        }
        
        if pairs.count >= 2 {
            return .moderate  // Two pair
        }
        
        if pairs.count == 1 {
            let pairValue = pairs[0].value
            if pairValue >= 11 {
                return .moderate  // High pair (J or better)
            } else {
                return .weak  // Low pair
            }
        }
        
        // High card
        let highCard = cards.map { $0.rank.value }.max() ?? 0
        if highCard >= 12 {
            return .weak
        }
        
        return .veryWeak
    }
}

/// Hand strength categories
enum HandStrength: String {
    case veryStrong = "Very Strong"
    case strong = "Strong"
    case moderate = "Moderate"
    case weak = "Weak"
    case veryWeak = "Very Weak"
}

/// AI actions
enum AIAction: Equatable {
    case fold
    case check
    case call
    case bet(amount: Int)
    
    var description: String {
        switch self {
        case .fold: return "Fold"
        case .check: return "Check"
        case .call: return "Call"
        case .bet(let amount): return "Bet $\(amount)"
        }
    }
}
