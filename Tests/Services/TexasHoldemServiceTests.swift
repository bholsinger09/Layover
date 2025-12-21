import Testing
import Foundation
@testable import Layover

/// Tests for TexasHoldemService
@Suite("Texas Hold'em Service Tests")
@MainActor
struct TexasHoldemServiceTests {
    
    @Test("Start game with valid players")
    func testStartGame() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let players = [UUID(), UUID(), UUID()]
        
        let game = try await service.startGame(roomID: roomID, players: players)
        
        #expect(game.roomID == roomID)
        #expect(game.players.count == 3)
        #expect(game.gamePhase == .preFlop)
        #expect(game.pot == 0)
    }
    
    @Test("Cannot start game with too few players")
    func testStartGameTooFewPlayers() async {
        let service = TexasHoldemService()
        let roomID = UUID()
        let players = [UUID()]
        
        await #expect(throws: GameError.self) {
            try await service.startGame(roomID: roomID, players: players)
        }
    }
    
    @Test("Cannot start game with too many players")
    func testStartGameTooManyPlayers() async {
        let service = TexasHoldemService()
        let roomID = UUID()
        let players = Array(repeating: UUID(), count: 11)
        
        await #expect(throws: GameError.self) {
            try await service.startGame(roomID: roomID, players: players)
        }
    }
    
    @Test("Deal cards to players")
    func testDealCards() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let players = [UUID(), UUID()]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        try await service.dealCards()
        
        let game = service.currentGame!
        #expect(game.players[0].hand.count == 2)
        #expect(game.players[1].hand.count == 2)
    }
    
    @Test("Player can bet")
    func testBet() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let playerID = UUID()
        let players = [playerID, UUID()]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        try await service.bet(playerID: playerID, amount: 50)
        
        let game = service.currentGame!
        let player = game.players.first { $0.userID == playerID }!
        
        #expect(player.currentBet == 50)
        #expect(player.chips == 950)
        #expect(game.pot == 50)
        #expect(game.currentBet == 50)
    }
    
    @Test("Player can fold")
    func testFold() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let playerID = UUID()
        let players = [playerID, UUID()]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        try await service.fold(playerID: playerID)
        
        let game = service.currentGame!
        let player = game.players.first { $0.userID == playerID }!
        
        #expect(player.isFolded == true)
    }
    
    @Test("Player can call")
    func testCall() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()
        let players = [player1ID, player2ID]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        try await service.bet(playerID: player1ID, amount: 50)
        try await service.call(playerID: player2ID)
        
        let game = service.currentGame!
        let player2 = game.players.first { $0.userID == player2ID }!
        
        #expect(player2.currentBet == 50)
        #expect(game.pot == 100)
    }
    
    @Test("Player can raise")
    func testRaise() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()
        let players = [player1ID, player2ID]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        try await service.bet(playerID: player1ID, amount: 50)
        try await service.raise(playerID: player2ID, amount: 50)
        
        let game = service.currentGame!
        let player2 = game.players.first { $0.userID == player2ID }!
        
        #expect(player2.currentBet == 100)
        #expect(game.currentBet == 100)
    }
    
    @Test("Game phase progression")
    func testNextPhase() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let players = [UUID(), UUID()]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        try await service.dealCards()
        
        #expect(service.currentGame!.gamePhase == .preFlop)
        
        try await service.nextPhase()
        #expect(service.currentGame!.gamePhase == .flop)
        #expect(service.currentGame!.communityCards.count == 3)
        
        try await service.nextPhase()
        #expect(service.currentGame!.gamePhase == .turn)
        #expect(service.currentGame!.communityCards.count == 4)
        
        try await service.nextPhase()
        #expect(service.currentGame!.gamePhase == .river)
        #expect(service.currentGame!.communityCards.count == 5)
        
        try await service.nextPhase()
        #expect(service.currentGame!.gamePhase == .showdown)
    }
    
    @Test("End game")
    func testEndGame() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let players = [UUID(), UUID()]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        await service.endGame()
        
        #expect(service.currentGame == nil)
    }
    
    @Test("Cannot bet with insufficient chips")
    func testBetInsufficientChips() async throws {
        let service = TexasHoldemService()
        let roomID = UUID()
        let playerID = UUID()
        let players = [playerID, UUID()]
        
        _ = try await service.startGame(roomID: roomID, players: players)
        
        await #expect(throws: GameError.self) {
            try await service.bet(playerID: playerID, amount: 1001)
        }
    }
}
