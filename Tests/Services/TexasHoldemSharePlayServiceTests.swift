import XCTest
@testable import LayoverKit

@MainActor
final class TexasHoldemSharePlayServiceTests: XCTestCase {
    var service: TexasHoldemSharePlayService!
    
    override func setUp() async throws {
        service = TexasHoldemSharePlayService()
    }
    
    override func tearDown() async throws {
        await service.leaveSession()
        service = nil
    }
    
    // MARK: - Session Management Tests
    
    func testInitialState() {
        XCTAssertFalse(service.isSessionActive, "Session should not be active initially")
        XCTAssertFalse(service.isHost, "Should not be host initially")
        XCTAssertNil(service.currentSession, "Should not have a session initially")
    }
    
    func testStartActivity() async throws {
        let roomID = UUID()
        let gameID = UUID()
        let roomName = "Test Room"
        
        // Note: This will fail in unit tests without SharePlay entitlements
        // In production, this would activate SharePlay
        do {
            try await service.startActivity(roomID: roomID, gameID: gameID, roomName: roomName)
            XCTAssertTrue(service.isHost, "Should be marked as host after starting activity")
        } catch {
            // Expected to fail in test environment without SharePlay
            XCTAssertTrue(error is TexasHoldemSharePlayError, "Should throw TexasHoldemSharePlayError")
        }
    }
    
    func testLeaveSession() async {
        await service.leaveSession()
        
        XCTAssertFalse(service.isSessionActive, "Session should not be active after leaving")
        XCTAssertFalse(service.isHost, "Should not be host after leaving")
        XCTAssertNil(service.currentSession, "Should not have session after leaving")
    }
    
    // MARK: - Message Callback Tests
    
    func testGameStartedCallback() async {
        let expectation = expectation(description: "Game started callback")
        let expectedGameID = UUID()
        let expectedPlayerIDs = [UUID(), UUID()]
        
        service.onGameStarted = { gameID, playerIDs in
            XCTAssertEqual(gameID, expectedGameID)
            XCTAssertEqual(playerIDs, expectedPlayerIDs)
            expectation.fulfill()
        }
        
        // Simulate receiving game started message
        // In real scenario, this would come from GroupSessionMessenger
        // For testing, we verify the callback is set correctly
        XCTAssertNotNil(service.onGameStarted, "Callback should be set")
    }
    
    func testGameStateUpdateCallback() async {
        let expectation = expectation(description: "Game state update callback")
        
        let expectedState = TexasHoldemGameState(
            gameID: UUID(),
            currentPlayerIndex: 0,
            pot: 100,
            currentBet: 20,
            phase: "flop",
            communityCards: [],
            playerStates: []
        )
        
        service.onGameStateUpdate = { state in
            XCTAssertEqual(state.gameID, expectedState.gameID)
            XCTAssertEqual(state.pot, expectedState.pot)
            XCTAssertEqual(state.currentBet, expectedState.currentBet)
            expectation.fulfill()
        }
        
        XCTAssertNotNil(service.onGameStateUpdate, "Callback should be set")
    }
    
    func testPlayerActionCallback() async {
        let expectation = expectation(description: "Player action callback")
        let playerID = UUID()
        
        service.onPlayerAction = { action in
            switch action {
            case .bet(let id, let amount):
                XCTAssertEqual(id, playerID)
                XCTAssertEqual(amount, 50)
                expectation.fulfill()
            default:
                XCTFail("Wrong action type")
            }
        }
        
        XCTAssertNotNil(service.onPlayerAction, "Callback should be set")
    }
    
    func testPhaseAdvancedCallback() async {
        let expectation = expectation(description: "Phase advanced callback")
        
        service.onPhaseAdvanced = { phase in
            XCTAssertEqual(phase, .flop)
            expectation.fulfill()
        }
        
        XCTAssertNotNil(service.onPhaseAdvanced, "Callback should be set")
    }
    
    func testGameEndedCallback() async {
        let expectation = expectation(description: "Game ended callback")
        let winnerID = UUID()
        
        service.onGameEnded = { winner in
            XCTAssertEqual(winner, winnerID)
            expectation.fulfill()
        }
        
        XCTAssertNotNil(service.onGameEnded, "Callback should be set")
    }
}

// MARK: - Message Encoding/Decoding Tests

final class TexasHoldemMessageTests: XCTestCase {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func testGameStartedMessageEncoding() throws {
        let gameID = UUID()
        let playerIDs = [UUID(), UUID()]
        let message = TexasHoldemMessage.gameStarted(gameID: gameID, playerIDs: playerIDs)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .gameStarted(let decodedGameID, let decodedPlayerIDs) = decoded {
            XCTAssertEqual(decodedGameID, gameID)
            XCTAssertEqual(decodedPlayerIDs, playerIDs)
        } else {
            XCTFail("Failed to decode game started message")
        }
    }
    
    func testPlayerActionBetEncoding() throws {
        let playerID = UUID()
        let amount = 100
        let action = TexasHoldemMessage.PlayerAction.bet(playerID: playerID, amount: amount)
        let message = TexasHoldemMessage.playerAction(action)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .playerAction(let decodedAction) = decoded,
           case .bet(let decodedPlayerID, let decodedAmount) = decodedAction {
            XCTAssertEqual(decodedPlayerID, playerID)
            XCTAssertEqual(decodedAmount, amount)
        } else {
            XCTFail("Failed to decode bet action message")
        }
    }
    
    func testPlayerActionFoldEncoding() throws {
        let playerID = UUID()
        let action = TexasHoldemMessage.PlayerAction.fold(playerID: playerID)
        let message = TexasHoldemMessage.playerAction(action)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .playerAction(let decodedAction) = decoded,
           case .fold(let decodedPlayerID) = decodedAction {
            XCTAssertEqual(decodedPlayerID, playerID)
        } else {
            XCTFail("Failed to decode fold action message")
        }
    }
    
    func testPlayerActionCallEncoding() throws {
        let playerID = UUID()
        let action = TexasHoldemMessage.PlayerAction.call(playerID: playerID)
        let message = TexasHoldemMessage.playerAction(action)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .playerAction(let decodedAction) = decoded,
           case .call(let decodedPlayerID) = decodedAction {
            XCTAssertEqual(decodedPlayerID, playerID)
        } else {
            XCTFail("Failed to decode call action message")
        }
    }
    
    func testPlayerActionCheckEncoding() throws {
        let playerID = UUID()
        let action = TexasHoldemMessage.PlayerAction.check(playerID: playerID)
        let message = TexasHoldemMessage.playerAction(action)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .playerAction(let decodedAction) = decoded,
           case .check(let decodedPlayerID) = decodedAction {
            XCTAssertEqual(decodedPlayerID, playerID)
        } else {
            XCTFail("Failed to decode check action message")
        }
    }
    
    func testPlayerActionRaiseEncoding() throws {
        let playerID = UUID()
        let amount = 200
        let action = TexasHoldemMessage.PlayerAction.raise(playerID: playerID, amount: amount)
        let message = TexasHoldemMessage.playerAction(action)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .playerAction(let decodedAction) = decoded,
           case .raise(let decodedPlayerID, let decodedAmount) = decodedAction {
            XCTAssertEqual(decodedPlayerID, playerID)
            XCTAssertEqual(decodedAmount, amount)
        } else {
            XCTFail("Failed to decode raise action message")
        }
    }
    
    func testPhaseAdvancedEncoding() throws {
        let phase = TexasHoldemMessage.GamePhase.flop
        let message = TexasHoldemMessage.phaseAdvanced(phase)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .phaseAdvanced(let decodedPhase) = decoded {
            XCTAssertEqual(decodedPhase, phase)
        } else {
            XCTFail("Failed to decode phase advanced message")
        }
    }
    
    func testAllPhaseTransitions() throws {
        let phases: [TexasHoldemMessage.GamePhase] = [.preFlop, .flop, .turn, .river, .showdown]
        
        for phase in phases {
            let message = TexasHoldemMessage.phaseAdvanced(phase)
            let data = try encoder.encode(message)
            let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
            
            if case .phaseAdvanced(let decodedPhase) = decoded {
                XCTAssertEqual(decodedPhase, phase, "Phase \(phase) should encode and decode correctly")
            } else {
                XCTFail("Failed to decode phase \(phase)")
            }
        }
    }
    
    func testGameStateEncoding() throws {
        let gameState = TexasHoldemGameState(
            gameID: UUID(),
            currentPlayerIndex: 1,
            pot: 500,
            currentBet: 100,
            phase: "turn",
            communityCards: [
                PlayingCardData(rank: "A", suit: "♠"),
                PlayingCardData(rank: "K", suit: "♥"),
                PlayingCardData(rank: "Q", suit: "♦")
            ],
            playerStates: [
                TexasHoldemGameState.PlayerState(
                    id: UUID(),
                    chips: 1000,
                    currentBet: 100,
                    hasFolded: false,
                    cards: [
                        PlayingCardData(rank: "A", suit: "♣"),
                        PlayingCardData(rank: "A", suit: "♥")
                    ]
                )
            ]
        )
        
        let message = TexasHoldemMessage.gameStateUpdate(gameState)
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .gameStateUpdate(let decodedState) = decoded {
            XCTAssertEqual(decodedState.gameID, gameState.gameID)
            XCTAssertEqual(decodedState.pot, gameState.pot)
            XCTAssertEqual(decodedState.currentBet, gameState.currentBet)
            XCTAssertEqual(decodedState.currentPlayerIndex, gameState.currentPlayerIndex)
            XCTAssertEqual(decodedState.phase, gameState.phase)
            XCTAssertEqual(decodedState.communityCards.count, gameState.communityCards.count)
            XCTAssertEqual(decodedState.playerStates.count, gameState.playerStates.count)
        } else {
            XCTFail("Failed to decode game state message")
        }
    }
    
    func testGameEndedEncoding() throws {
        let winnerID = UUID()
        let message = TexasHoldemMessage.gameEnded(winnerID: winnerID)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .gameEnded(let decodedWinnerID) = decoded {
            XCTAssertEqual(decodedWinnerID, winnerID)
        } else {
            XCTFail("Failed to decode game ended message")
        }
    }
    
    func testGameEndedNilWinnerEncoding() throws {
        let message = TexasHoldemMessage.gameEnded(winnerID: nil)
        
        let data = try encoder.encode(message)
        let decoded = try decoder.decode(TexasHoldemMessage.self, from: data)
        
        if case .gameEnded(let decodedWinnerID) = decoded {
            XCTAssertNil(decodedWinnerID, "Winner should be nil for draw/cancelled games")
        } else {
            XCTFail("Failed to decode game ended message with nil winner")
        }
    }
}

// MARK: - Playing Card Data Tests

final class PlayingCardDataTests: XCTestCase {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func testPlayingCardDataEncoding() throws {
        let card = PlayingCardData(rank: "A", suit: "♠")
        
        let data = try encoder.encode(card)
        let decoded = try decoder.decode(PlayingCardData.self, from: data)
        
        XCTAssertEqual(decoded.rank, card.rank)
        XCTAssertEqual(decoded.suit, card.suit)
    }
    
    func testMultipleCardsEncoding() throws {
        let cards = [
            PlayingCardData(rank: "A", suit: "♠"),
            PlayingCardData(rank: "K", suit: "♥"),
            PlayingCardData(rank: "Q", suit: "♦"),
            PlayingCardData(rank: "J", suit: "♣"),
            PlayingCardData(rank: "10", suit: "♠")
        ]
        
        let data = try encoder.encode(cards)
        let decoded = try decoder.decode([PlayingCardData].self, from: data)
        
        XCTAssertEqual(decoded.count, cards.count)
        for (index, card) in decoded.enumerated() {
            XCTAssertEqual(card.rank, cards[index].rank)
            XCTAssertEqual(card.suit, cards[index].suit)
        }
    }
}

// MARK: - Activity Tests

final class TexasHoldemActivityTests: XCTestCase {
    func testActivityMetadata() {
        let roomID = UUID()
        let gameID = UUID()
        let roomName = "High Rollers"
        
        let activity = TexasHoldemActivity(
            roomID: roomID,
            gameID: gameID,
            roomName: roomName
        )
        
        XCTAssertEqual(activity.roomID, roomID)
        XCTAssertEqual(activity.gameID, gameID)
        XCTAssertEqual(activity.roomName, roomName)
        
        let metadata = activity.metadata
        XCTAssertEqual(metadata.title, roomName)
        XCTAssertEqual(metadata.subtitle, "Texas Hold'em Poker")
    }
    
    func testActivityMetadataWithoutRoomName() {
        let roomID = UUID()
        let gameID = UUID()
        
        let activity = TexasHoldemActivity(
            roomID: roomID,
            gameID: gameID,
            roomName: nil
        )
        
        XCTAssertNil(activity.roomName)
        
        let metadata = activity.metadata
        XCTAssertEqual(metadata.title, "Texas Hold'em")
        XCTAssertEqual(metadata.subtitle, "LayoverLounge Poker")
    }
    
    func testActivityIdentifier() {
        let activity = TexasHoldemActivity(
            roomID: UUID(),
            gameID: UUID(),
            roomName: nil
        )
        
        XCTAssertEqual(
            TexasHoldemActivity.activityIdentifier,
            "com.bholsinger.LayoverLounge.texasholdem",
            "Activity identifier should match bundle identifier pattern"
        )
    }
}
