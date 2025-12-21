import Testing
import Foundation
@testable import Layover

/// Tests for TexasHoldemViewModel
@Suite("Texas Hold'em ViewModel Tests")
@MainActor
struct TexasHoldemViewModelTests {
    
    @Test("Initialize view model")
    func testInitialization() {
        let viewModel = TexasHoldemViewModel()
        
        #expect(viewModel.currentGame == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.pot == 0)
        #expect(viewModel.communityCards.isEmpty)
    }
    
    @Test("Start game")
    func testStartGame() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let players = [UUID(), UUID()]
        
        await viewModel.startGame(roomID: roomID, players: players)
        
        #expect(viewModel.currentGame != nil)
        #expect(viewModel.currentGame?.players.count == 2)
        #expect(viewModel.currentPhase == .preFlop)
    }
    
    @Test("Bet action")
    func testBet() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let playerID = UUID()
        let players = [playerID, UUID()]
        
        await viewModel.startGame(roomID: roomID, players: players)
        await viewModel.bet(playerID: playerID, amount: 50)
        
        #expect(viewModel.pot == 50)
        let player = viewModel.getPlayer(for: playerID)
        #expect(player?.currentBet == 50)
        #expect(player?.chips == 950)
    }
    
    @Test("Fold action")
    func testFold() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let playerID = UUID()
        let players = [playerID, UUID()]
        
        await viewModel.startGame(roomID: roomID, players: players)
        await viewModel.fold(playerID: playerID)
        
        let player = viewModel.getPlayer(for: playerID)
        #expect(player?.isFolded == true)
    }
    
    @Test("Call action")
    func testCall() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()
        let players = [player1ID, player2ID]
        
        await viewModel.startGame(roomID: roomID, players: players)
        await viewModel.bet(playerID: player1ID, amount: 50)
        await viewModel.call(playerID: player2ID)
        
        let player2 = viewModel.getPlayer(for: player2ID)
        #expect(player2?.currentBet == 50)
        #expect(viewModel.pot == 100)
    }
    
    @Test("Raise action")
    func testRaise() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()
        let players = [player1ID, player2ID]
        
        await viewModel.startGame(roomID: roomID, players: players)
        await viewModel.bet(playerID: player1ID, amount: 50)
        await viewModel.raise(playerID: player2ID, amount: 50)
        
        let player2 = viewModel.getPlayer(for: player2ID)
        #expect(player2?.currentBet == 100)
    }
    
    @Test("Next phase progression")
    func testNextPhase() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let players = [UUID(), UUID()]
        
        await viewModel.startGame(roomID: roomID, players: players)
        
        await viewModel.nextPhase()
        #expect(viewModel.currentPhase == .flop)
        #expect(viewModel.communityCards.count == 3)
        
        await viewModel.nextPhase()
        #expect(viewModel.currentPhase == .turn)
        #expect(viewModel.communityCards.count == 4)
    }
    
    @Test("End game")
    func testEndGame() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let players = [UUID(), UUID()]
        
        await viewModel.startGame(roomID: roomID, players: players)
        await viewModel.endGame()
        
        #expect(viewModel.currentGame == nil)
    }
    
    @Test("Get player")
    func testGetPlayer() async {
        let viewModel = TexasHoldemViewModel()
        let roomID = UUID()
        let playerID = UUID()
        let players = [playerID, UUID()]
        
        await viewModel.startGame(roomID: roomID, players: players)
        
        let player = viewModel.getPlayer(for: playerID)
        #expect(player != nil)
        #expect(player?.userID == playerID)
    }
}
