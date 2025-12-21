import Testing
import Foundation
@testable import LayoverKit

/// Tests for Texas Hold'em game models
@Suite("Texas Hold'em Model Tests")
struct TexasHoldemTests {
    
    @Test("Playing card initialization")
    func testPlayingCardInitialization() {
        let card = PlayingCard(rank: .ace, suit: .spades)
        
        #expect(card.rank == .ace)
        #expect(card.suit == .spades)
    }
    
    @Test("Card rank values")
    func testCardRankValues() {
        #expect(PlayingCard.Rank.two.value == 2)
        #expect(PlayingCard.Rank.ten.value == 10)
        #expect(PlayingCard.Rank.jack.value == 10)
        #expect(PlayingCard.Rank.ace.value == 11)
    }
    
    @Test("Texas Hold'em player initialization")
    func testPlayerInitialization() {
        let userID = UUID()
        let player = TexasHoldemPlayer(userID: userID, position: 0)
        
        #expect(player.userID == userID)
        #expect(player.chips == 1000)
        #expect(player.currentBet == 0)
        #expect(player.hand.isEmpty)
        #expect(player.isFolded == false)
        #expect(player.position == 0)
    }
    
    @Test("Texas Hold'em game initialization")
    func testGameInitialization() {
        let roomID = UUID()
        let game = TexasHoldemGame(roomID: roomID)
        
        #expect(game.roomID == roomID)
        #expect(game.players.isEmpty)
        #expect(game.pot == 0)
        #expect(game.currentBet == 0)
        #expect(game.communityCards.isEmpty)
        #expect(game.gamePhase == .preFlop)
    }
    
    @Test("Game phase progression")
    func testGamePhases() {
        let phases: [TexasHoldemGame.GamePhase] = [
            .preFlop, .flop, .turn, .river, .showdown, .ended
        ]
        
        for phase in phases {
            let game = TexasHoldemGame(roomID: UUID(), gamePhase: phase)
            #expect(game.gamePhase == phase)
        }
    }
    
    @Test("Playing card conforms to Codable")
    func testPlayingCardCodable() throws {
        let card = PlayingCard(rank: .king, suit: .hearts)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(card)
        let decodedCard = try decoder.decode(PlayingCard.self, from: data)
        
        #expect(decodedCard.rank == card.rank)
        #expect(decodedCard.suit == card.suit)
    }
}
