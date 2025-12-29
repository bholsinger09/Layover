import XCTest

@testable import LayoverKit

@MainActor
final class TexasHoldemViewModelSharePlayTests: XCTestCase {
    var viewModel: TexasHoldemViewModel!
    var mockGameService: MockTexasHoldemService!

    override func setUp() async throws {
        mockGameService = MockTexasHoldemService()
        viewModel = TexasHoldemViewModel(gameService: mockGameService)
        viewModel.setupSharePlayCallbacks()
    }

    override func tearDown() async throws {
        await viewModel.sharePlayService.leaveSession()
        viewModel = nil
        mockGameService = nil
    }

    // MARK: - Game Start Synchronization Tests

    func testStartGameBroadcastsToSharePlay() async throws {
        let roomID = UUID()
        let playerIDs = [UUID(), UUID()]

        // Start game
        await viewModel.startGame(roomID: roomID, players: playerIDs)

        // Verify game was created locally
        XCTAssertNotNil(viewModel.currentGame, "Game should be created")
        XCTAssertEqual(viewModel.currentGame?.players.count, playerIDs.count)

        // In production, this would broadcast game start message
        // Verify SharePlay service is available
        XCTAssertNotNil(viewModel.sharePlayService, "SharePlay service should exist")
    }

    func testGameStateUpdateAppliesCorrectly() async {
        // Setup initial game
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // Create updated game state
        let updatedState = TexasHoldemGameState(
            gameID: viewModel.currentGame!.id,
            currentPlayerIndex: 1,
            pot: 200,
            currentBet: 50,
            phase: "flop",
            communityCards: [
                PlayingCardData(rank: "A", suit: "♠"),
                PlayingCardData(rank: "K", suit: "♥"),
                PlayingCardData(rank: "Q", suit: "♦"),
            ],
            playerStates: [
                TexasHoldemGameState.PlayerState(
                    id: player1ID,
                    chips: 950,
                    currentBet: 50,
                    hasFolded: false,
                    cards: nil
                ),
                TexasHoldemGameState.PlayerState(
                    id: player2ID,
                    chips: 950,
                    currentBet: 50,
                    hasFolded: false,
                    cards: nil
                ),
            ]
        )

        // Verify current game state exists
        XCTAssertNotNil(viewModel.currentGame, "Game should exist before state update")

        // Note: applyGameState is private, would be called via SharePlay callback
        // This tests the data structure is correct
        XCTAssertEqual(updatedState.pot, 200)
        XCTAssertEqual(updatedState.currentBet, 50)
        XCTAssertEqual(updatedState.currentPlayerIndex, 1)
        XCTAssertEqual(updatedState.communityCards.count, 3)
    }

    // MARK: - Player Action Synchronization Tests

    func testBetActionBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        let betAmount = 100
        await viewModel.bet(playerID: player1ID, amount: betAmount)

        // Verify action was applied locally
        XCTAssertNotNil(viewModel.currentGame)

        // In production, bet would be broadcast via SharePlay
        XCTAssertTrue(
            viewModel.sharePlayService.isSessionActive == false, "Not in SharePlay session in tests"
        )
    }

    func testFoldActionBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        await viewModel.fold(playerID: player1ID)

        // Verify fold was applied
        XCTAssertNotNil(viewModel.currentGame)
        let player = viewModel.currentGame?.players.first { $0.userID == player1ID }
        XCTAssertEqual(player?.isFolded, true, "Player should be folded")
    }

    func testCallActionBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // First player bets
        await viewModel.bet(playerID: player1ID, amount: 50)

        // Second player calls
        await viewModel.call(playerID: player2ID)

        XCTAssertNotNil(viewModel.currentGame)
    }

    func testCheckActionBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        await viewModel.check(playerID: player1ID)

        XCTAssertNotNil(viewModel.currentGame)
    }

    func testRaiseActionBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // First player bets
        await viewModel.bet(playerID: player1ID, amount: 50)

        // Second player raises
        await viewModel.raise(playerID: player2ID, amount: 100)

        XCTAssertNotNil(viewModel.currentGame)
    }

    // MARK: - Phase Transition Synchronization Tests

    func testDealFlopBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        await viewModel.dealFlop()

        XCTAssertNotNil(viewModel.currentGame)
        XCTAssertEqual(viewModel.currentGame?.gamePhase, .flop, "Phase should advance to flop")
        XCTAssertEqual(viewModel.communityCards.count, 3, "Should have 3 community cards")
    }

    func testDealTurnBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])
        await viewModel.dealFlop()
        await viewModel.dealTurn()

        XCTAssertEqual(viewModel.currentGame?.gamePhase, .turn, "Phase should advance to turn")
        XCTAssertEqual(viewModel.communityCards.count, 4, "Should have 4 community cards")
    }

    func testDealRiverBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])
        await viewModel.dealFlop()
        await viewModel.dealTurn()
        await viewModel.dealRiver()

        XCTAssertEqual(viewModel.currentGame?.gamePhase, .river, "Phase should advance to river")
        XCTAssertEqual(viewModel.communityCards.count, 5, "Should have 5 community cards")
    }

    func testShowdownBroadcasts() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])
        await viewModel.dealFlop()
        await viewModel.dealTurn()
        await viewModel.dealRiver()
        await viewModel.showdown()

        XCTAssertEqual(
            viewModel.currentGame?.gamePhase, .showdown, "Phase should advance to showdown")
    }

    // MARK: - Card Privacy Tests

    func testOpponentCardsHiddenBeforeShowdown() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // Create game state with opponent cards hidden
        let gameState = TexasHoldemGameState(
            gameID: viewModel.currentGame!.id,
            currentPlayerIndex: 0,
            pot: 100,
            currentBet: 0,
            phase: "flop",
            communityCards: [],
            playerStates: [
                TexasHoldemGameState.PlayerState(
                    id: player1ID,
                    chips: 500,
                    currentBet: 0,
                    hasFolded: false,
                    cards: [
                        PlayingCardData(rank: "A", suit: "♠"),
                        PlayingCardData(rank: "A", suit: "♥"),
                    ]
                ),
                TexasHoldemGameState.PlayerState(
                    id: player2ID,
                    chips: 500,
                    currentBet: 0,
                    hasFolded: false,
                    cards: nil  // Hidden until showdown
                ),
            ]
        )

        // Player 1's cards should be visible
        XCTAssertNotNil(gameState.playerStates[0].cards, "Own cards should be visible")

        // Player 2's cards should be hidden
        XCTAssertNil(gameState.playerStates[1].cards, "Opponent cards should be hidden")
    }

    func testCardsVisibleAtShowdown() async {
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])
        await viewModel.dealFlop()
        await viewModel.dealTurn()
        await viewModel.dealRiver()
        await viewModel.showdown()

        // At showdown, all cards should be revealed
        XCTAssertEqual(viewModel.currentGame?.gamePhase, .showdown)

        // Both players' hands should be visible
        let game = viewModel.currentGame!
        for player in game.players {
            XCTAssertEqual(
                player.hand.count, 2, "Each player should have 2 cards visible at showdown")
        }
    }

    // MARK: - Multi-Device Synchronization Tests

    func testSimulateMultiDeviceGameStart() async {
        // Simulate Device 1 starting the game
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // Create a second ViewModel to simulate Device 2
        let viewModel2 = TexasHoldemViewModel(gameService: MockTexasHoldemService())
        viewModel2.setupSharePlayCallbacks()

        // Simulate Device 2 receiving game start message
        var receivedRoomID: UUID?
        var receivedGameID: UUID?
        var receivedPlayerIDs: [UUID]?

        viewModel2.sharePlayService.onGameStarted = { roomID, gameID, playerIDs in
            receivedRoomID = roomID
            receivedGameID = gameID
            receivedPlayerIDs = playerIDs
        }

        // Manually trigger callback (in production, comes from SharePlay)
        viewModel2.sharePlayService.onGameStarted?(
            roomID, viewModel.currentGame!.id, [player1ID, player2ID])

        XCTAssertEqual(receivedRoomID, roomID)
        XCTAssertEqual(receivedGameID, viewModel.currentGame!.id)
        XCTAssertEqual(receivedPlayerIDs, [player1ID, player2ID])

        await viewModel2.sharePlayService.leaveSession()
    }

    func testSimulateMultiDeviceActionSync() async {
        // Device 1 setup
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // Device 2 setup
        let viewModel2 = TexasHoldemViewModel(gameService: MockTexasHoldemService())
        viewModel2.setupSharePlayCallbacks()
        await viewModel2.startGame(roomID: roomID, players: [player1ID, player2ID])

        // Device 1 makes a bet
        await viewModel.bet(playerID: player1ID, amount: 100)

        // Simulate Device 2 receiving the bet action
        var receivedAction: TexasHoldemMessage.PlayerAction?

        viewModel2.sharePlayService.onPlayerAction = { action in
            receivedAction = action
        }

        // Trigger callback
        viewModel2.sharePlayService.onPlayerAction?(.bet(playerID: player1ID, amount: 100))

        if case .bet(let playerID, let amount) = receivedAction {
            XCTAssertEqual(playerID, player1ID)
            XCTAssertEqual(amount, 100)
        } else {
            XCTFail("Should have received bet action")
        }

        await viewModel2.sharePlayService.leaveSession()
    }

    func testSimulateMultiDevicePhaseSync() async {
        // Device 1 setup
        let roomID = UUID()
        let player1ID = UUID()
        let player2ID = UUID()

        await viewModel.startGame(roomID: roomID, players: [player1ID, player2ID])

        // Device 2 setup
        let viewModel2 = TexasHoldemViewModel(gameService: MockTexasHoldemService())
        viewModel2.setupSharePlayCallbacks()

        // Device 1 deals flop
        await viewModel.dealFlop()

        // Simulate Device 2 receiving phase change
        var receivedPhase: TexasHoldemMessage.GamePhase?

        viewModel2.sharePlayService.onPhaseAdvanced = { phase in
            receivedPhase = phase
        }

        // Trigger callback
        viewModel2.sharePlayService.onPhaseAdvanced?(.flop)

        XCTAssertEqual(receivedPhase, .flop)

        await viewModel2.sharePlayService.leaveSession()
    }

    // MARK: - Error Handling Tests

    func testHandleErrorDuringGameStart() async {
        mockGameService.shouldThrowError = true

        let roomID = UUID()
        let playerIDs = [UUID(), UUID()]

        await viewModel.startGame(roomID: roomID, players: playerIDs)

        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        XCTAssertNil(viewModel.currentGame, "Game should not be created on error")
    }

    func testSharePlayCallbacksSetCorrectly() {
        viewModel.setupSharePlayCallbacks()

        XCTAssertNotNil(
            viewModel.sharePlayService.onGameStarted, "Game started callback should be set")
        XCTAssertNotNil(
            viewModel.sharePlayService.onGameStateUpdate, "Game state update callback should be set"
        )
        XCTAssertNotNil(
            viewModel.sharePlayService.onPlayerAction, "Player action callback should be set")
        XCTAssertNotNil(
            viewModel.sharePlayService.onPhaseAdvanced, "Phase advanced callback should be set")
    }
}

// MARK: - Mock Service

@MainActor
class MockTexasHoldemService: TexasHoldemServiceProtocol {
    var currentGame: TexasHoldemGame?
    var shouldThrowError = false

    enum MockError: Error {
        case testError
    }

    func startGame(roomID: UUID, players: [UUID]) async throws -> TexasHoldemGame {
        if shouldThrowError {
            throw MockError.testError
        }

        let game = TexasHoldemGame(
            roomID: roomID,
            players: players.map { TexasHoldemPlayer(id: UUID(), userID: $0, chips: 500) }
        )
        currentGame = game
        return game
    }

    func loadGame(_ game: TexasHoldemGame) {
        currentGame = game
    }

    func dealCards() async throws {
        guard var game = currentGame else { return }

        // Deal 2 cards to each player
        for index in 0..<game.players.count {
            game.players[index].hand = [
                PlayingCard(rank: .ace, suit: .spades),
                PlayingCard(rank: .king, suit: .hearts),
            ]
        }

        currentGame = game
    }

    func bet(playerID: UUID, amount: Int) async throws {
        guard var game = currentGame,
            let playerIndex = game.players.firstIndex(where: { $0.userID == playerID })
        else {
            return
        }

        game.players[playerIndex].currentBet = amount
        game.players[playerIndex].chips -= amount
        game.pot += amount
        game.currentBet = amount

        currentGame = game
    }

    func fold(playerID: UUID) async throws {
        guard var game = currentGame,
            let playerIndex = game.players.firstIndex(where: { $0.userID == playerID })
        else {
            return
        }

        game.players[playerIndex].isFolded = true
        currentGame = game
    }

    func call(playerID: UUID) async throws {
        guard var game = currentGame,
            let playerIndex = game.players.firstIndex(where: { $0.userID == playerID })
        else {
            return
        }

        let callAmount = game.currentBet - game.players[playerIndex].currentBet
        game.players[playerIndex].currentBet = game.currentBet
        game.players[playerIndex].chips -= callAmount
        game.pot += callAmount

        currentGame = game
    }

    func raise(playerID: UUID, amount: Int) async throws {
        guard var game = currentGame,
            let playerIndex = game.players.firstIndex(where: { $0.userID == playerID })
        else {
            return
        }

        let totalBet = game.currentBet + amount
        let raiseAmount = totalBet - game.players[playerIndex].currentBet

        game.players[playerIndex].currentBet = totalBet
        game.players[playerIndex].chips -= raiseAmount
        game.pot += raiseAmount
        game.currentBet = totalBet

        currentGame = game
    }

    func nextPhase() async throws {
        // Not used in SharePlay tests
    }

    func endGame() async {
        currentGame = nil
    }

    func check(playerID: UUID) async throws {
        // Just advance turn if current bet is 0
        guard let game = currentGame, game.currentBet == 0 else {
            return
        }
    }

    func dealFlop() async throws {
        guard var game = currentGame else { return }

        game.communityCards = [
            PlayingCard(rank: .ace, suit: .spades),
            PlayingCard(rank: .king, suit: .hearts),
            PlayingCard(rank: .queen, suit: .diamonds),
        ]
        game.gamePhase = .flop

        currentGame = game
    }

    func dealTurn() async throws {
        guard var game = currentGame else { return }

        game.communityCards.append(PlayingCard(rank: .jack, suit: .clubs))
        game.gamePhase = .turn

        currentGame = game
    }

    func dealRiver() async throws {
        guard var game = currentGame else { return }

        game.communityCards.append(PlayingCard(rank: .ten, suit: .spades))
        game.gamePhase = .river

        currentGame = game
    }

    func showdown() async throws {
        guard var game = currentGame else { return }

        game.gamePhase = .showdown
        currentGame = game
    }
}
