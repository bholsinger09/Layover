import Foundation
import Observation

/// ViewModel for Texas Hold'em game rooms
@MainActor
@Observable
final class TexasHoldemViewModel: LayoverViewModel {
    private let gameService: TexasHoldemServiceProtocol
    let sharePlayService: TexasHoldemSharePlayService

    private(set) var currentGame: TexasHoldemGame?
    private(set) var isLoading = false
    var errorMessage: String?

    var currentPhase: TexasHoldemGame.GamePhase {
        currentGame?.gamePhase ?? .preFlop
    }

    var pot: Int {
        currentGame?.pot ?? 0
    }

    var communityCards: [PlayingCard] {
        currentGame?.communityCards ?? []
    }

    init(gameService: TexasHoldemServiceProtocol) {
        self.gameService = gameService
        self.sharePlayService = TexasHoldemSharePlayService()
    }
    
    func setupSharePlayCallbacks() {
        print("🔧 Setting up SharePlay callbacks...")
        print("   Current session active: \(sharePlayService.isSessionActive)")
        print("   Is host: \(sharePlayService.isHost)")
        
        sharePlayService.onGameStarted = { [weak self] roomID, gameID, playerIDs in
            print("📨 RECEIVED gameStarted message!")
            print("   Room ID: \(roomID)")
            print("   Game ID: \(gameID)")
            print("   Player IDs: \(playerIDs)")
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("   Current game: \(self.currentGame?.id.uuidString ?? "none")")
                print("   Is host: \(self.sharePlayService.isHost)")
                
                // Participant receives game start notification - start the game locally
                if !self.sharePlayService.isHost && self.currentGame == nil {
                    print("📱 Participant received game start message - starting game locally")
                    print("   Using roomID: \(roomID)")
                    
                    // Start the game with the same roomID and player IDs as the host
                    isLoading = true
                    do {
                        let game = try await gameService.startGame(roomID: roomID, players: playerIDs)
                        currentGame = game
                        try await gameService.dealCards()
                        currentGame = gameService.currentGame
                        print("✅ Participant game started successfully")
                        print("   Game ID: \(game.id)")
                    } catch {
                        errorMessage = error.localizedDescription
                        print("❌ Participant failed to start game: \(error)")
                    }
                    isLoading = false
                } else {
                    print("ℹ️ Skipping game start - either host or game already exists")
                }
            }
        }
        
        sharePlayService.onGameStateUpdate = { [weak self] state in
            Task { @MainActor [weak self] in
                await self?.applyGameState(state)
            }
        }
        
        sharePlayService.onPlayerAction = { [weak self] action in
            Task { @MainActor [weak self] in
                await self?.handlePlayerAction(action)
            }
        }
        
        sharePlayService.onPhaseAdvanced = { [weak self] phase in
            Task { @MainActor [weak self] in
                await self?.syncGameState()
            }
        }
        
        sharePlayService.onParticipantJoined = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🆕 New participant joined - re-broadcasting game state")
                
                // If we're the host and have a game, re-broadcast the state
                if self.sharePlayService.isHost, let game = self.currentGame {
                    print("   Broadcasting gameStarted and game state to new participant")
                    await self.sharePlayService.sendMessage(.gameStarted(roomID: game.roomID, gameID: game.id, playerIDs: game.players.map { $0.userID }))
                    // Small delay to ensure participant has set up their listener
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.broadcastGameState()
                }
            }
        }
        
        // Start observing for SharePlay sessions AFTER callbacks are configured
        sharePlayService.startObserving()
        print("✅ SharePlay callbacks configured and observer started")
    }

    func startGame(roomID: UUID, players: [UUID]) async {
        print("🎮 Starting game...")
        print("   Room ID: \(roomID)")
        print("   Players: \(players)")
        print("   SharePlay active: \(sharePlayService.isSessionActive)")
        print("   Is host: \(sharePlayService.isHost)")
        
        isLoading = true
        errorMessage = nil

        do {
            let game = try await gameService.startGame(roomID: roomID, players: players)
            currentGame = game
            try await gameService.dealCards()
            currentGame = gameService.currentGame
            
            print("✅ Game started successfully")
            print("   Game ID: \(game.id)")
            print("   Current game instance: \(currentGame != nil)")
            
            // Broadcast game start to all participants
            if sharePlayService.isSessionActive {
                print("📤 Broadcasting game start to SharePlay participants...")
                print("   Sending gameStarted message with roomID: \(roomID)")
                await sharePlayService.sendMessage(.gameStarted(roomID: roomID, gameID: game.id, playerIDs: players))
                // Wait a moment for participants to create their game instance
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await broadcastGameState()
                print("✅ Game state broadcasted")
            } else {
                print("⚠️ SharePlay NOT active - cannot broadcast to other devices")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to start game: \(error)")
        }

        isLoading = false
    }

    func bet(playerID: UUID, amount: Int) async {
        errorMessage = nil

        do {
            try await gameService.bet(playerID: playerID, amount: amount)
            currentGame = gameService.currentGame
            
            // Broadcast action to all participants
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.playerAction(.bet(playerID: playerID, amount: amount)))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fold(playerID: UUID) async {
        errorMessage = nil

        do {
            try await gameService.fold(playerID: playerID)
            currentGame = gameService.currentGame
            
            // Broadcast action to all participants
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.playerAction(.fold(playerID: playerID)))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func call(playerID: UUID) async {
        errorMessage = nil

        do {
            try await gameService.call(playerID: playerID)
            currentGame = gameService.currentGame
            
            // Broadcast action to all participants
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.playerAction(.call(playerID: playerID)))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func raise(playerID: UUID, amount: Int) async {
        errorMessage = nil

        do {
            try await gameService.raise(playerID: playerID, amount: amount)
            currentGame = gameService.currentGame
            
            // Broadcast action to all participants
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.playerAction(.raise(playerID: playerID, amount: amount)))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nextPhase() async {
        errorMessage = nil

        do {
            try await gameService.nextPhase()
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endGame() async {
        await gameService.endGame()
        currentGame = nil
    }

    func getPlayer(for userID: UUID) -> TexasHoldemPlayer? {
        currentGame?.players.first { $0.userID == userID }
    }
    
    func check(playerID: UUID) async {
        errorMessage = nil
        
        do {
            try await gameService.check(playerID: playerID)
            currentGame = gameService.currentGame
            
            // Broadcast action to all participants
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.playerAction(.check(playerID: playerID)))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func dealFlop() async {
        errorMessage = nil
        
        do {
            try await gameService.dealFlop()
            currentGame = gameService.currentGame
            
            // Broadcast phase change
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.phaseAdvanced(.flop))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func dealTurn() async {
        errorMessage = nil
        
        do {
            try await gameService.dealTurn()
            currentGame = gameService.currentGame
            
            // Broadcast phase change
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.phaseAdvanced(.turn))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func dealRiver() async {
        errorMessage = nil
        
        do {
            try await gameService.dealRiver()
            currentGame = gameService.currentGame
            
            // Broadcast phase change
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.phaseAdvanced(.river))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func showdown() async {
        errorMessage = nil
        
        do {
            try await gameService.showdown()
            currentGame = gameService.currentGame
            
            // Broadcast phase change
            if sharePlayService.isSessionActive {
                await sharePlayService.sendMessage(.phaseAdvanced(.showdown))
                await broadcastGameState()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - SharePlay Methods
    
    func startSharePlay(roomID: UUID, roomName: String?) async throws {
        print("📱 Activating SharePlay session...")
        // Start SharePlay activity - game doesn't need to exist yet
        // We'll use a temporary gameID and update when the actual game starts
        let tempGameID = UUID()
        try await sharePlayService.startActivity(roomID: roomID, gameID: tempGameID, roomName: roomName)
        print("✅ SharePlay session activated successfully")
    }
    
    private func broadcastGameState() async {
        guard let game = currentGame else { return }
        
        let state = TexasHoldemGameState(
            gameID: game.id,
            currentPlayerIndex: game.currentPlayerIndex,
            pot: game.pot,
            currentBet: game.currentBet,
            phase: game.gamePhase.rawValue,
            communityCards: game.communityCards.map { PlayingCardData(rank: $0.rank.rawValue, suit: $0.suit.rawValue) },
            playerStates: game.players.map { player in
                TexasHoldemGameState.PlayerState(
                    id: player.userID,
                    chips: player.chips,
                    currentBet: player.currentBet,
                    hasFolded: player.isFolded,
                    cards: player.hand.map { PlayingCardData(rank: $0.rank.rawValue, suit: $0.suit.rawValue) }
                )
            }
        )
        
        await sharePlayService.sendMessage(.gameStateUpdate(state))
    }
    
    private func syncGameState() async {
        // Request current game state from host
        // In a real implementation, this would query the host for the latest state
        // For now, we rely on broadcast updates
    }
    
    private func applyGameState(_ state: TexasHoldemGameState) async {
        // Update local game state from SharePlay message
        guard var game = currentGame else { return }
        
        // Update basic game state
        game.currentPlayerIndex = state.currentPlayerIndex
        game.pot = state.pot
        game.currentBet = state.currentBet
        
        // Update phase
        if let phase = TexasHoldemGame.GamePhase(rawValue: state.phase) {
            game.gamePhase = phase
        }
        
        // Update community cards
        game.communityCards = state.communityCards.compactMap { cardData in
            guard let rank = PlayingCard.Rank(rawValue: cardData.rank),
                  let suit = PlayingCard.Suit(rawValue: cardData.suit) else {
                return nil
            }
            return PlayingCard(rank: rank, suit: suit)
        }
        
        // Update player states
        for playerState in state.playerStates {
            if let index = game.players.firstIndex(where: { $0.userID == playerState.id }) {
                game.players[index].chips = playerState.chips
                game.players[index].currentBet = playerState.currentBet
                game.players[index].isFolded = playerState.hasFolded
                
                // Only update hand if cards are visible (showdown)
                if let cards = playerState.cards {
                    game.players[index].hand = cards.compactMap { cardData in
                        guard let rank = PlayingCard.Rank(rawValue: cardData.rank),
                              let suit = PlayingCard.Suit(rawValue: cardData.suit) else {
                            return nil
                        }
                        return PlayingCard(rank: rank, suit: suit)
                    }
                }
            }
        }
        
        currentGame = game
    }
    
    private func handlePlayerAction(_ action: TexasHoldemMessage.PlayerAction) async {
        switch action {
        case .fold(let playerID):
            await fold(playerID: playerID)
            
        case .check(let playerID):
            await check(playerID: playerID)
            
        case .bet(let playerID, let amount):
            await bet(playerID: playerID, amount: amount)
            
        case .call(let playerID):
            await call(playerID: playerID)
            
        case .raise(let playerID, let amount):
            await self.raise(playerID: playerID, amount: amount)
        }
    }
}
