import Foundation
import Observation

/// ViewModel for Texas Hold'em game rooms
@MainActor
@Observable
final class TexasHoldemViewModel: LayoverViewModel {
    private let gameService: TexasHoldemServiceProtocol
    let sharePlayService: TexasHoldemSharePlayService
    private let roomService: RoomServiceProtocol
    private let aiService = TexasHoldemAIService()

    private(set) var currentGame: TexasHoldemGame?
    private(set) var isLoading = false
    var errorMessage: String?
    
    // AI opponent tracking
    private(set) var aiPlayerID: UUID?
    private(set) var isAIThinking = false
    
    // Test SharePlay connectivity
    private(set) var testMessages: [String] = []
    private(set) var testConnectionStatus: String = ""
    private(set) var isTestingConnection = false

    // Trigger for SharePlay state changes
    private(set) var sharePlayStateVersion: Int = 0

    var currentPhase: TexasHoldemGame.GamePhase {
        currentGame?.gamePhase ?? .preFlop
    }

    var pot: Int {
        currentGame?.pot ?? 0
    }

    var communityCards: [PlayingCard] {
        currentGame?.communityCards ?? []
    }

    init(gameService: TexasHoldemServiceProtocol, roomService: RoomServiceProtocol? = nil) {
        self.gameService = gameService
        self.sharePlayService = TexasHoldemSharePlayService()
        self.roomService = roomService ?? RoomService()
    }

    func setupSharePlayCallbacks() {
        print("🔧 ===== SETTING UP SHAREPLAY CALLBACKS =====")
        print("🔧 Setting up SharePlay callbacks...")
        print("   Current session active: \(sharePlayService.isSessionActive)")
        print("   Is host: \(sharePlayService.isHost)")
        print("   This will start the session observer")

        sharePlayService.onSessionActivated = { [weak self] in
            Task { @MainActor in
                print("🎊 SharePlay session activated - triggering UI update")
                print("   Is host: \(self?.sharePlayService.isHost ?? false)")
                print("   Session active: \(self?.sharePlayService.isSessionActive ?? false)")
                self?.sharePlayStateVersion += 1
            }
        }

        sharePlayService.onGameStarted = { [weak self] roomID, gameID, playerIDs in
            print("📨 RECEIVED gameStarted message!")
            print("   Room ID: \(roomID)")
            print("   Game ID: \(gameID)")
            print("   Player IDs from host: \(playerIDs)")

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("   Current game: \(self.currentGame?.id.uuidString ?? "none")")
                print("   Is host: \(self.sharePlayService.isHost)")

                // Participant receives game start notification - start the game locally
                if !self.sharePlayService.isHost && self.currentGame == nil {
                    print("📱 Participant received game start message - starting game locally")
                    print("   Using roomID: \(roomID)")

                    // Use the same player IDs from the host
                    // This ensures both devices have the same player list
                    isLoading = true
                    do {
                        let game = try await gameService.startGame(
                            roomID: roomID, players: playerIDs)
                        
                        // DO NOT deal cards - guest will receive cards from host's broadcast
                        // Just create the game structure without cards
                        currentGame = game

                        print(
                            "✅ Participant game started - waiting for host's card broadcast"
                        )
                        print("   Game ID: \(game.id)")
                        print("   Players in game: \(game.players.map { $0.userID })")
                        print("   Cards NOT dealt locally - will receive from host")
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
                guard let self = self else { return }
                
                // Only the HOST should execute incoming player actions from guests
                if self.sharePlayService.isHost {
                    print("📨 HOST received player action from guest: \(action)")
                    print("   💰 POT BEFORE ACTION: $\(self.gameService.currentGame?.pot ?? -1)")
                    print("   Executing action and broadcasting result...")
                    
                    let phaseBefore = self.gameService.currentGame?.gamePhase
                    
                    // Execute the action
                    print("   ⚙️ Executing action in service...")
                    switch action {
                    case .fold(let playerID):
                        try? await self.gameService.fold(playerID: playerID)
                    case .check(let playerID):
                        try? await self.gameService.check(playerID: playerID)
                    case .call(let playerID):
                        try? await self.gameService.call(playerID: playerID)
                    case .bet(let playerID, let amount):
                        print("   💰 Executing bet: playerID=\(playerID), amount=$\(amount)")
                        try? await self.gameService.bet(playerID: playerID, amount: amount)
                    case .raise(let playerID, let amount):
                        try? await self.gameService.raise(playerID: playerID, amount: amount)
                    }
                    
                    print("   ⚙️ Action execution complete, updating currentGame...")
                    print("   💰 POT AFTER SERVICE EXECUTION: $\(self.gameService.currentGame?.pot ?? -1)")
                    
                    // CRITICAL: Get the absolute latest game state from service
                    guard let updatedGame = self.gameService.currentGame else {
                        print("   ⚠️ gameService.currentGame is nil!")
                        return
                    }
                    
                    print("   📊 Service game state after action:")
                    print("      💰💰 Pot: $\(updatedGame.pot) 💰💰")
                    print("      CurrentBet: $\(updatedGame.currentBet)")
                    print("      Phase: \(updatedGame.gamePhase.rawValue)")
                    
                    // Force a new object to trigger @Observable change detection
                    print("   🔄 Creating new game object with pot=$\(updatedGame.pot)")
                    self.currentGame = TexasHoldemGame(
                        id: updatedGame.id,
                        roomID: updatedGame.roomID,
                        players: updatedGame.players,
                        dealerIndex: updatedGame.dealerIndex,
                        currentBet: updatedGame.currentBet,
                        pot: updatedGame.pot,
                        communityCards: updatedGame.communityCards,
                        gamePhase: updatedGame.gamePhase,
                        currentPlayerIndex: updatedGame.currentPlayerIndex
                    )
                    
                    print("   ✅ HOST currentGame updated with new reference")
                    print("   💰 POT IN NEW currentGame OBJECT: $\(self.currentGame?.pot ?? -1)")
                    print("   📊 ViewModel currentGame after update:")
                    if let game = self.currentGame {
                        print("      💰💰 Pot: $\(game.pot) 💰💰")
                        print("      CurrentBet: $\(game.currentBet)")
                        print("      Phase: \(game.gamePhase.rawValue)")
                    }
                    
                    let phaseAfter = self.gameService.currentGame?.gamePhase
                    print("   📊 STATE AFTER EXECUTION:")
                    print("      Phase: \(phaseBefore?.rawValue ?? "nil") → \(phaseAfter?.rawValue ?? "nil")")
                    
                    if let game = self.currentGame {
                        print("      Pot: $\(game.pot)")
                        print("      Current Bet: $\(game.currentBet)")
                        print("      Current Player Index: \(game.currentPlayerIndex)")
                        print("      Player 0: chips=$\(game.players[0].chips), bet=$\(game.players[0].currentBet)")
                        if game.players.count > 1 {
                            print("      Player 1: chips=$\(game.players[1].chips), bet=$\(game.players[1].currentBet)")
                        }
                        print("      Host is player \(self.sharePlayService.isHost ? 0 : 1)")
                        let hostTurn = game.currentPlayerIndex == 0
                        print("      Is it host's turn? \(hostTurn)")
                    } else {
                        print("      ⚠️ WARNING: currentGame is nil after execution!")
                    }
                    
                    // Broadcast IMMEDIATELY - no delays
                    print("   📡 Broadcasting state to all participants...")
                    await self.broadcastGameState()
                    
                    // CRITICAL: Force UI update on host
                    self.sharePlayStateVersion += 1
                    print("✅ HOST executed action, broadcast complete, UI version: \(self.sharePlayStateVersion)")
                    
                    // If phase changed, send one more broadcast to ensure sync
                    if phaseBefore != phaseAfter {
                        print("   Phase auto-advanced - broadcasting again")
                        await self.broadcastGameState()
                        self.sharePlayStateVersion += 1
                    }
                } else {
                    print("📨 GUEST received player action echo: \(action) - waiting for state update")
                }
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
                    await self.sharePlayService.sendMessage(
                        .gameStarted(
                            roomID: game.roomID, gameID: game.id,
                            playerIDs: game.players.map { $0.userID }))
                    // Small delay to ensure participant has set up their listener
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.broadcastGameState()
                }
            }
        }

        sharePlayService.onParticipantCountChanged = { [weak self] count in
            Task { @MainActor in
                print("👥 SharePlay participant count changed to: \(count)")
                // Trigger UI refresh by updating version counter
                self?.sharePlayStateVersion += 1
            }
        }
        
        sharePlayService.onTestPingReceived = { [weak self] (from: String, message: String, senderID: UUID) in
            Task { @MainActor in
                guard let self = self else { return }
                print("🏓 Test ping received from: \(from), message: \(message), senderID: \(senderID)")
                
                // Determine if this is from host or guest
                let senderRole = from == "host" ? "Host" : "Guest"
                self.testMessages.append("📥 \(senderRole) says: \(message)")
                
                // Auto-respond with pong
                let myRole = self.sharePlayService.isHost ? "host" : "guest"
                let responseMessage = "Hello \(from)"  // Reply to whoever sent the ping
                
                print("🏓 Auto-responding to \(senderRole) with pong")
                await self.sharePlayService.sendTestPong(from: myRole, message: responseMessage)
                self.testMessages.append("📤 Replied: \(responseMessage)")
                
                // Update status
                if self.testConnectionStatus.isEmpty || self.testConnectionStatus.starts(with: "🔄") {
                    self.testConnectionStatus = "✅ Connected to \(senderRole)"
                }
            }
        }
        
        sharePlayService.onTestPongReceived = { [weak self] (from: String, message: String, senderID: UUID) in
            Task { @MainActor in
                guard let self = self else { return }
                print("🏓 Test pong received from: \(from), message: \(message), senderID: \(senderID)")
                
                // Determine if this is from host or guest
                let senderRole = from == "host" ? "Host" : "Guest"
                self.testMessages.append("📥 \(senderRole) says: \(message)")
                
                // Mark test as successful
                self.testConnectionStatus = "✅ \(senderRole) responded!"
                self.isTestingConnection = false
            }
        }

        // Start observing for SharePlay sessions AFTER callbacks are configured
        print("📡 Calling sharePlayService.startObserving()...")
        sharePlayService.startObserving()
        print("✅ SharePlay callbacks configured and observer started")
        print("✅ The session observer should now be listening for sessions from other devices")
    }

    func startGame(roomID: UUID, players: [UUID]) async {
        print("🎮 Starting game...")
        print("   Room ID: \(roomID)")
        print("   Players: \(players)")
        print("   SharePlay active: \(sharePlayService.isSessionActive)")
        print("   Is host: \(sharePlayService.isHost)")

        isLoading = true
        errorMessage = nil
        
        // Detect AI player (if there are exactly 2 players and not in SharePlay)
        if players.count == 2 && !sharePlayService.isSessionActive {
            // The second player is likely the AI
            aiPlayerID = players[1]
            print("🤖 AI player detected: \(aiPlayerID!)")
        } else {
            aiPlayerID = nil
        }

        do {
            let game = try await gameService.startGame(roomID: roomID, players: players)
            currentGame = game
            try await gameService.dealCards()
            currentGame = gameService.currentGame

            print("✅ Game started successfully")
            print("   Game ID: \(game.id)")
            print("   Current game instance: \(currentGame != nil)")
            print("   Players: \(currentGame?.players.count ?? 0)")
            if let currentGame = currentGame {
                for (index, player) in currentGame.players.enumerated() {
                    print("   Player \(index) (\(player.userID)): \(player.hand.count) cards")
                    if player.userID == aiPlayerID {
                        print("      [AI - cards hidden]")
                    } else {
                        for card in player.hand {
                            print("      - \(card.rank.rawValue) of \(card.suit.rawValue)")
                        }
                    }
                }
            }

            // Save game to iCloud for cross-device sync
            if let currentGame = currentGame {
                roomService.saveGame(currentGame)
                print("💾 Saved game to iCloud")
            }

            // Broadcast game start to all participants
            if sharePlayService.isSessionActive {
                print("📤 Broadcasting game start to SharePlay participants...")
                print("   Sending gameStarted message with roomID: \(roomID)")
                await sharePlayService.sendMessage(
                    .gameStarted(roomID: roomID, gameID: game.id, playerIDs: players))
                // Wait a moment for participants to create their game instance
                try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
                await broadcastGameState()
                print("✅ Game state broadcasted")
            } else {
                print("⚠️ SharePlay NOT active - local game mode")
                
                // If it's AI's turn to start, let AI play
                if let game = currentGame, let aiID = aiPlayerID {
                    if game.players[game.currentPlayerIndex].userID == aiID {
                        print("🤖 AI starts first - executing AI turn")
                        await executeAITurn()
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to start game: \(error)")
        }

        isLoading = false
    }

    func bet(playerID: UUID, amount: Int) async {
        print("💰 BET called: playerID=\(playerID), amount=$\(amount)")
        print("   Is host: \(sharePlayService.isHost)")
        print("   SharePlay active: \(sharePlayService.isSessionActive)")
        errorMessage = nil

        // If guest in SharePlay, only send action request to host
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("📤 GUEST sending bet action to host")
            await sharePlayService.sendMessage(
                .playerAction(.bet(playerID: playerID, amount: amount)))
            print("   Waiting for host to execute and broadcast result...")
            return
        }

        // Host or single-player: execute locally
        do {
            print("   Executing bet in service...")
            try await gameService.bet(playerID: playerID, amount: amount)
            currentGame = gameService.currentGame
            
            if let game = currentGame {
                print("   ✅ Bet executed - new state:")
                print("      Pot: $\(game.pot)")
                print("      Current bet: $\(game.currentBet)")
                print("      Current player index: \(game.currentPlayerIndex)")
                for (i, player) in game.players.enumerated() {
                    print("      Player \(i): chips=$\(player.chips), bet=$\(player.currentBet)")
                }
            }
            
            saveGameState()

            // Broadcast to all participants (if host in SharePlay)
            if sharePlayService.isSessionActive {
                print("   Broadcasting game state via SharePlay...")
                await broadcastGameState()
            } else {
                print("   ⚠️ SharePlay not active - not broadcasting")
            }
        } catch {
            print("   ❌ Bet failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func fold(playerID: UUID) async {
        errorMessage = nil

        // If guest in SharePlay, only send action request to host
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("📤 GUEST sending fold action to host")
            await sharePlayService.sendMessage(.playerAction(.fold(playerID: playerID)))
            print("   Waiting for host to execute and broadcast result...")
            return
        }

        // Host or single-player: execute locally
        do {
            try await gameService.fold(playerID: playerID)
            currentGame = gameService.currentGame
            saveGameState()

            // Broadcast to all participants (if host in SharePlay)
            if sharePlayService.isSessionActive {
                await broadcastGameState()
            } else {
                // Check if AI should play next
                await checkAndExecuteAITurn()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func call(playerID: UUID) async {
        errorMessage = nil

        // If guest in SharePlay, only send action request to host
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("📤 GUEST sending call action to host")
            await sharePlayService.sendMessage(.playerAction(.call(playerID: playerID)))
            print("   Waiting for host to execute and broadcast result...")
            return
        }

        // Host or single-player: execute locally
        do {
            let phaseBefore = gameService.currentGame?.gamePhase
            
            try await gameService.call(playerID: playerID)
            currentGame = gameService.currentGame
            saveGameState()

            let phaseAfter = gameService.currentGame?.gamePhase
            print("📞 Call executed - phase: \(phaseBefore?.rawValue ?? "nil") → \(phaseAfter?.rawValue ?? "nil")")
            
            // Broadcast to all participants (if host in SharePlay)
            if sharePlayService.isSessionActive {
                await broadcastGameState()
                
                // If phase auto-advanced, broadcast again to ensure sync
                if phaseBefore != phaseAfter {
                    print("   Phase auto-advanced after call - broadcasting again")
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await broadcastGameState()
                }
            } else {
                // Check if AI should play next
                await checkAndExecuteAITurn()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func raise(playerID: UUID, amount: Int) async {
        errorMessage = nil

        // If guest in SharePlay, only send action request to host
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("📤 GUEST sending bet action to host")
            await sharePlayService.sendMessage(
                .playerAction(.bet(playerID: playerID, amount: amount)))
            print("   Waiting for host to execute and broadcast result...")
            return
        }

        // Host or single-player: execute locally
        do {
            try await gameService.raise(playerID: playerID, amount: amount)
            currentGame = gameService.currentGame

            // Broadcast to all participants (if host in SharePlay)
            if sharePlayService.isSessionActive {
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
        if let game = currentGame {
            // Clear game from iCloud
            roomService.deleteGame(game)
            print("🗑️ Deleted game from iCloud: \(game.id)")
        }
        await gameService.endGame()
        currentGame = nil
    }

    func getPlayer(for userID: UUID) -> TexasHoldemPlayer? {
        print("🔍 getPlayer looking for userID: \(userID)")
        if let game = currentGame {
            print("   Available players: \(game.players.map { $0.userID })")
        }
        let player = currentGame?.players.first { $0.userID == userID }
        if let player = player {
            print("🃏 getPlayer for \(userID): found with \(player.hand.count) cards")
        } else {
            print("⚠️ getPlayer for \(userID): not found")
        }
        return player
    }

    func check(playerID: UUID) async {
        errorMessage = nil

        // If guest in SharePlay, only send action request to host
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("📤 GUEST sending check action to host")
            await sharePlayService.sendMessage(.playerAction(.check(playerID: playerID)))
            print("   Waiting for host to execute and broadcast result...")
            return
        }

        // Host or single-player: execute locally
        do {
            let phaseBefore = gameService.currentGame?.gamePhase
            
            try await gameService.check(playerID: playerID)
            currentGame = gameService.currentGame

            let phaseAfter = gameService.currentGame?.gamePhase
            print("✅ Check executed - phase: \(phaseBefore?.rawValue ?? "nil") → \(phaseAfter?.rawValue ?? "nil")")
            
            // Broadcast to all participants (if host in SharePlay)
            if sharePlayService.isSessionActive {
                await broadcastGameState()
                
                // If phase auto-advanced, broadcast again
                if phaseBefore != phaseAfter {
                    print("   Phase auto-advanced after check - broadcasting again")
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await broadcastGameState()
                }
            } else {
                // Check if AI should play next
                await checkAndExecuteAITurn()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dealFlop() async {
        errorMessage = nil

        // Only host should deal community cards
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("⚠️ Non-host tried to deal flop - ignoring")
            return
        }

        do {
            print(
                "🎴 dealFlop called - current community cards: \(currentGame?.communityCards.count ?? 0)"
            )
            try await gameService.dealFlop()
            currentGame = gameService.currentGame
            print(
                "✅ Flop dealt - now have \(currentGame?.communityCards.count ?? 0) community cards")
            if let cards = currentGame?.communityCards {
                for card in cards {
                    print("   - \(card.rank.rawValue) of \(card.suit.rawValue)")
                }
            }

            // Broadcast phase change
            if sharePlayService.isSessionActive {
                print("📤 Broadcasting flop to SharePlay...")
                await sharePlayService.sendMessage(.phaseAdvanced(.flop))
                await broadcastGameState()
                print("✅ Flop broadcast complete")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ dealFlop failed: \(error)")
        }
    }

    func dealTurn() async {
        errorMessage = nil

        // Only host should deal community cards
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("⚠️ Non-host tried to deal turn - ignoring")
            return
        }

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

        // Only host should deal community cards
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("⚠️ Non-host tried to deal river - ignoring")
            return
        }

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
        try await sharePlayService.startActivity(
            roomID: roomID, gameID: tempGameID, roomName: roomName)
        print("✅ SharePlay session activated successfully")
    }

    private func broadcastGameState() async {
        guard let game = currentGame else {
            print("⚠️ broadcastGameState: No current game to broadcast")
            return
        }

        print("📡 ===== BROADCASTING GAME STATE =====")
        print("   💰💰 POT BEING BROADCAST: $\(game.pot) 💰💰")
        print("   Phase: \(game.gamePhase.rawValue)")
        print("   Current bet: $\(game.currentBet)")
        print("   Current player index: \(game.currentPlayerIndex)")
        print("   Community cards: \(game.communityCards.count)")
        for card in game.communityCards {
            print("      - \(card.rank.rawValue) of \(card.suit.rawValue)")
        }
        for (i, player) in game.players.enumerated() {
            print("   Player \(i): chips=$\(player.chips), currentBet=$\(player.currentBet), folded=\(player.isFolded), cards=\(player.hand.count)")
            if !player.hand.isEmpty {
                print("      Cards: \(player.hand.map { "\($0.rank.rawValue)\($0.suit.rawValue)" }.joined(separator: ", "))")
            }
        }

        let state = TexasHoldemGameState(
            gameID: game.id,
            currentPlayerIndex: game.currentPlayerIndex,
            pot: game.pot,
            currentBet: game.currentBet,
            phase: game.gamePhase.rawValue,
            communityCards: game.communityCards.map {
                PlayingCardData(rank: $0.rank.rawValue, suit: $0.suit.rawValue)
            },
            playerStates: game.players.map { player in
                TexasHoldemGameState.PlayerState(
                    id: player.userID,
                    chips: player.chips,
                    currentBet: player.currentBet,
                    hasFolded: player.isFolded,
                    cards: player.hand.map {
                        PlayingCardData(rank: $0.rank.rawValue, suit: $0.suit.rawValue)
                    }
                )
            },
            winnerID: game.winnerID,
            winningAmount: game.winningAmount
        )

        print("📤 Sending gameStateUpdate message:")
        print("   💰 State object pot: $\(state.pot)")
        print("   Community cards: \(state.communityCards.count)")
        for (i, playerState) in state.playerStates.enumerated() {
            print("   Player \(i): \(playerState.cards?.count ?? 0) cards being sent")
        }
        print("   🚀 SENDING MESSAGE WITH POT=$\(state.pot)")
        await sharePlayService.sendMessage(.gameStateUpdate(state))
        print("✅ Game state broadcast complete - sent pot=$\(state.pot)")
    }

    private func syncGameState() async {
        // Request current game state from host
        // In a real implementation, this would query the host for the latest state
        // For now, we rely on broadcast updates
    }

    private func applyGameState(_ state: TexasHoldemGameState) async {
        // Update local game state from SharePlay message
        guard var game = currentGame else {
            print("⚠️ applyGameState: No current game")
            return
        }

        print("📥 ===== APPLYING GAME STATE FROM SHAREPLAY =====")
        print("   💰 Previous POT: $\(game.pot)")
        print("   💰💰 INCOMING POT: $\(state.pot) 💰💰")
        print("   Previous state - Phase: \(game.gamePhase.rawValue), CurrentBet: $\(game.currentBet)")
        print("   Incoming state - Phase: \(state.phase), CurrentBet: $\(state.currentBet)")
        print("   Community cards: \(state.communityCards.count)")
        print("   Players: \(state.playerStates.count)")
        print("   Current player index: \(state.currentPlayerIndex)")

        // Update basic game state
        game.currentPlayerIndex = state.currentPlayerIndex
        print("   🔄 Updating game.pot from $\(game.pot) to $\(state.pot)")
        game.pot = state.pot
        game.currentBet = state.currentBet
        print("   ✅ game.pot updated to $\(game.pot)")
        
        // Update winner info
        game.winnerID = state.winnerID
        game.winningAmount = state.winningAmount
        if let winnerID = state.winnerID {
            print("   🏆 Winner updated: \(winnerID) won $\(state.winningAmount)")
        }

        // Update phase
        if let phase = TexasHoldemGame.GamePhase(rawValue: state.phase) {
            game.gamePhase = phase
        }

        // Update community cards (but don't clear them if we already have cards and incoming is empty)
        let incomingCards = state.communityCards.compactMap { cardData -> PlayingCard? in
            guard let rank = PlayingCard.Rank(rawValue: cardData.rank),
                let suit = PlayingCard.Suit(rawValue: cardData.suit)
            else {
                return nil
            }
            return PlayingCard(rank: rank, suit: suit)
        }

        print(
            "🃏 Community card sync - current: \(game.communityCards.count), incoming: \(incomingCards.count)"
        )

        // Only update if incoming has cards OR if we don't have any yet
        if !incomingCards.isEmpty || game.communityCards.isEmpty {
            game.communityCards = incomingCards
            print("✅ Applied \(game.communityCards.count) community cards")
            for card in game.communityCards {
                print("   - \(card.rank.rawValue) of \(card.suit.rawValue)")
            }
        } else {
            print(
                "⚠️ Skipping community card update - keeping existing \(game.communityCards.count) cards"
            )
        }

        // Update player states
        for playerState in state.playerStates {
            if let index = game.players.firstIndex(where: { $0.userID == playerState.id }) {
                print(
                    "   Updating player \(index): chips=\(playerState.chips), bet=\(playerState.currentBet)"
                )
                print("      Current hand size: \(game.players[index].hand.count)")
                print("      Incoming cards: \(playerState.cards?.count ?? 0)")
                
                game.players[index].chips = playerState.chips
                game.players[index].currentBet = playerState.currentBet
                game.players[index].isFolded = playerState.hasFolded

                // ALWAYS update cards if the broadcast includes them
                // This ensures guest receives host's dealt cards
                if let incomingCards = playerState.cards, !incomingCards.isEmpty {
                    let incomingHand = incomingCards.compactMap { cardData -> PlayingCard? in
                        guard let rank = PlayingCard.Rank(rawValue: cardData.rank),
                            let suit = PlayingCard.Suit(rawValue: cardData.suit)
                        else {
                            return nil
                        }
                        return PlayingCard(rank: rank, suit: suit)
                    }
                    
                    // Only update if we don't have cards OR if it's showdown
                    if game.players[index].hand.isEmpty || game.gamePhase == .showdown {
                        game.players[index].hand = incomingHand
                        print(
                            "   ✅ Player \(index) (\(playerState.id)) cards updated: \(incomingHand.count) cards"
                        )
                        for card in incomingHand {
                            print("      - \(card.rank.rawValue) of \(card.suit.rawValue)")
                        }
                    } else {
                        print("   ℹ️ Player \(index) already has \(game.players[index].hand.count) cards - preserving")
                    }
                } else {
                    print("   ⚠️ No cards in broadcast for player \(index)")
                }
            }
        }

        currentGame = game
        print("✅ Game state applied successfully")
        print("   💰 FINAL POT AFTER APPLY: $\(game.pot)")
        print("   💰 currentGame.pot: $\(self.currentGame?.pot ?? -1)")
        print("   Triggering UI refresh...")
        
        // Force UI refresh by updating a published property
        sharePlayStateVersion += 1
        print("   📺 UI refresh triggered, version: \(sharePlayStateVersion)")
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

    // MARK: - iCloud Sync Methods

    private func saveGameState() {
        guard let game = currentGame else { return }
        roomService.saveGame(game)
        print("💾 Saved game state to iCloud")
    }

    func startWatchingForGameUpdates(roomID: UUID) {
        print("👀 Starting to watch for game updates in room: \(roomID)")

        Task { @MainActor in
            isLoading = true

            // Check for existing game - keep checking for up to 10 seconds
            var attempts = 0
            while currentGame == nil && attempts < 10 {
                // Check if a game has been created
                if let game = roomService.getActiveGame(for: roomID) {
                    print("🎮 Found active game in iCloud!")
                    currentGame = game
                    gameService.loadGame(game)
                    break
                }

                // Check every second, up to 10 attempts
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1

                if attempts % 3 == 0 {
                    print("⏳ Still checking for game... attempt \(attempts)/10")
                }
            }

            isLoading = false
            print(
                currentGame == nil
                    ? "ℹ️ No existing game found after 10 seconds - ready to start new game"
                    : "✅ Loaded existing game from iCloud")

            // Continue polling for updates while waiting for a game OR while a game is active
            while true {
                // Skip iCloud updates if we're in an active SharePlay session
                // SharePlay uses its own synchronization, iCloud polling would cause conflicts
                if sharePlayService.isSessionActive {
                    if sharePlayService.isHost {
                        print("🚫 Host in SharePlay - ignoring iCloud updates (host is authoritative)")
                    } else {
                        print("🚫 Guest in SharePlay - ignoring iCloud updates (receiving from host)")
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000)  // Still sleep to avoid tight loop
                    continue
                }
                
                if let game = roomService.getActiveGame(for: roomID) {
                    if currentGame == nil {
                        // Game was just created - load it
                        print("🆕 New game detected in iCloud!")
                        currentGame = game
                        gameService.loadGame(game)
                    } else if game.id == currentGame?.id {
                        // Update existing game if state changed
                        // But DON'T overwrite if we have more community cards locally
                        let shouldUpdate =
                            game.currentPlayerIndex != currentGame?.currentPlayerIndex
                            || game.pot != currentGame?.pot
                            || game.gamePhase != currentGame?.gamePhase

                        if shouldUpdate {
                            print("🔄 Game state updated from iCloud")
                            // Preserve community cards if we have more locally
                            if let current = currentGame,
                                game.communityCards.count < current.communityCards.count
                            {
                                print(
                                    "   ⚠️ iCloud has fewer community cards (\(game.communityCards.count)) than local (\(current.communityCards.count)) - keeping local"
                                )
                                var updatedGame = game
                                updatedGame.communityCards = current.communityCards
                                currentGame = updatedGame
                                gameService.loadGame(updatedGame)
                            } else {
                                currentGame = game
                                gameService.loadGame(game)
                            }
                        }
                    }
                }

                // Poll every 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    // MARK: - Test SharePlay Connectivity
    
    /// Simple ping to the other user - host pings guest, guest pings host
    func sendPingToOtherUser() async {
        print("🏓 ========== PING TO OTHER USER ==========")
        
        // Clear previous messages for a fresh start
        testMessages = []
        testConnectionStatus = "🔄 Sending ping..."
        isTestingConnection = true
        
        // Determine our role and the target role
        let myRole = sharePlayService.isHost ? "host" : "guest"
        let targetRole = sharePlayService.isHost ? "guest" : "host"
        let greeting = "Hello \(targetRole)"
        
        print("🏓 My role: \(myRole)")
        print("🏓 Target role: \(targetRole)")
        print("🏓 Message: \(greeting)")
        print("🏓 Session active: \(sharePlayService.isSessionActive)")
        print("🏓 Participant count: \(sharePlayService.participantCount)")
        
        // Send the ping
        testMessages.append("📤 Sent: \(greeting)")
        await sharePlayService.sendTestPing(from: myRole, message: greeting)
        print("🏓 Ping sent successfully")
        
        // Wait for response (5 second timeout)
        var attempts = 0
        let maxAttempts = 50 // 5 seconds (50 * 0.1s)
        
        while isTestingConnection && attempts < maxAttempts {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
        }
        
        // If we timed out
        if isTestingConnection {
            testConnectionStatus = "⏱️ No response"
            testMessages.append("⚠️ \(targetRole.capitalized) didn't respond")
            testMessages.append("Check that both devices are on this screen")
            isTestingConnection = false
        }
        
        print("🏓 ========================================")
    }
    
    func testSharePlayConnection() async {
        print("🧪 ========== BUTTON PRESSED ==========")
        print("🧪 Testing SharePlay connection...")
        print("🧪 Current thread: \(Thread.current)")
        print("🧪 Is main thread: \(Thread.isMainThread)")
        
        testMessages = []
        testConnectionStatus = ""
        isTestingConnection = true
        
        print("🧪 About to call getDiagnostics...")
        // Get detailed diagnostics
        let diagnostics = sharePlayService.getDiagnostics()
        print("🧪 Got diagnostics: \(diagnostics)")
        
        testMessages.append("📊 Advanced Diagnostics:")
        testMessages.append("Role: \(sharePlayService.isHost ? "Host" : "Guest")")
        testMessages.append("Device ID: \(diagnostics["deviceID"] as? String ?? "unknown")")
        
        // Check if SharePlay is active
        if !sharePlayService.isSessionActive {
            testConnectionStatus = "❌ SharePlay is not active"
            testMessages.append("❌ SharePlay session is not active")
            testMessages.append("Please start SharePlay during a FaceTime call")
            isTestingConnection = false
            return
        }
        testMessages.append("✅ SharePlay session is active")
        
        // Session details
        if let sessionID = diagnostics["sessionID"] as? String {
            testMessages.append("Session ID: \(String(sessionID.prefix(8)))...")
        }
        
        if let sessionState = diagnostics["sessionState"] as? String {
            testMessages.append("Session State: \(sessionState)")
        }
        
        // Messenger and task status
        let hasMessenger = diagnostics["hasMessenger"] as? Bool ?? false
        let hasMessageTask = diagnostics["hasMessageTask"] as? Bool ?? false
        testMessages.append(hasMessenger ? "✅ Messenger exists" : "❌ Messenger is nil")
        testMessages.append(hasMessageTask ? "✅ Message listener running" : "❌ Message listener not running")
        
        // Participant details
        let participantCount = diagnostics["participantCount"] as? Int ?? 0
        let activeParticipantCount = diagnostics["activeParticipantCount"] as? Int ?? 0
        testMessages.append("Stored participants: \(participantCount)")
        testMessages.append("Active participants: \(activeParticipantCount)")
        
        if let participants = diagnostics["activeParticipants"] as? [[String: String]] {
            for participant in participants {
                let index = participant["index"] ?? "?"
                let id = participant["id"] ?? "unknown"
                testMessages.append("  Participant \(index): \(String(id.prefix(8)))...")
            }
        }
        
        if participantCount < 1 {
            testConnectionStatus = "❌ No other participants"
            testMessages.append("❌ No other participants in SharePlay session")
            testMessages.append("SharePlay requires at least 2 participants")
            isTestingConnection = false
            return
        }
        testMessages.append("")
        
        // Check if callbacks are registered
        let hasPingCallback = sharePlayService.onTestPingReceived != nil
        let hasPongCallback = sharePlayService.onTestPongReceived != nil
        testMessages.append(hasPingCallback ? "✅ Ping callback registered" : "⚠️ Ping callback not registered")
        testMessages.append(hasPongCallback ? "✅ Pong callback registered" : "⚠️ Pong callback not registered")
        
        // Send test ping
        let role = sharePlayService.isHost ? "host" : "guest"
        let targetRole = sharePlayService.isHost ? "guest" : "host"
        let message = "Hello \(targetRole)"
        
        testMessages.append("")
        testMessages.append("📤 Sending test ping...")
        testMessages.append("From: \(role)")
        testMessages.append("Message: \(message)")
        testConnectionStatus = "🔄 Testing..."
        
        // Record start time
        let startTime = Date()
        
        await sharePlayService.sendTestPing(from: role, message: message)
        testMessages.append("✅ Ping sent at \(startTime.formatted(date: .omitted, time: .standard))")
        
        // Wait for response (timeout after 5 seconds)
        var attempts = 0
        while isTestingConnection && attempts < 50 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
            
            // Update status every second
            if attempts % 10 == 0 {
                let elapsed = attempts / 10
                testConnectionStatus = "🔄 Testing... (\(elapsed)s)"
            }
        }
        
        if isTestingConnection {
            // Timeout
            let endTime = Date()
            let elapsed = endTime.timeIntervalSince(startTime)
            
            testConnectionStatus = "❌ Connection timeout"
            testMessages.append("")
            testMessages.append("❌ No response received after \(String(format: "%.1f", elapsed))s")
            testMessages.append("")
            testMessages.append("🔍 Possible Issues:")
            
            // Analyze specific issues based on diagnostics
            if !hasMessageTask {
                testMessages.append("⚠️ Message listener is not running on this device")
                testMessages.append("   This means callbacks won't be triggered")
            }
            
            if activeParticipantCount != participantCount + 1 {
                testMessages.append("⚠️ Participant count mismatch:")
                testMessages.append("   Expected: \(participantCount + 1), Actual: \(activeParticipantCount)")
            }
            
            testMessages.append("")
            testMessages.append("📋 Troubleshooting Steps:")
            testMessages.append("1. Verify other device has app open")
            testMessages.append("2. Check both devices show same Session ID")
            testMessages.append("3. Restart SharePlay on both devices")
            testMessages.append("4. Try ending and restarting FaceTime call")
            testMessages.append("5. Ensure both devices on same WiFi/network")
            testMessages.append("6. Check Console logs for SharePlay errors")
            isTestingConnection = false
        } else {
            let endTime = Date()
            let elapsed = endTime.timeIntervalSince(startTime)
            testConnectionStatus = "✅ Connection successful (\(String(format: "%.1f", elapsed))s)"
        }
    }
    
    // MARK: - AI Opponent Methods
    
    /// Execute AI player's turn
    private func executeAITurn() async {
        guard let game = currentGame,
              let aiID = aiPlayerID,
              game.players[game.currentPlayerIndex].userID == aiID,
              !isAIThinking else {
            return
        }
        
        print("🤖 ===== AI TURN START =====")
        isAIThinking = true
        
        // Add a short delay to make it feel more natural
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        
        // Get AI decision
        let decision = await aiService.makeDecision(game: game, aiPlayerID: aiID)
        
        print("🤖 AI decided: \(decision.description)")
        
        // Execute the decision
        switch decision {
        case .fold:
            try? await gameService.fold(playerID: aiID)
        case .check:
            try? await gameService.check(playerID: aiID)
        case .call:
            try? await gameService.call(playerID: aiID)
        case .bet(let amount):
            try? await gameService.bet(playerID: aiID, amount: amount)
        }
        
        // Update current game
        currentGame = gameService.currentGame
        saveGameState()
        
        isAIThinking = false
        print("🤖 ===== AI TURN END =====")
        
        // Force UI update
        sharePlayStateVersion += 1
    }
    
    /// Check if it's AI's turn and execute if needed
    private func checkAndExecuteAITurn() async {
        guard let game = currentGame,
              let aiID = aiPlayerID,
              game.gamePhase != .showdown,
              game.gamePhase != .ended else {
            return
        }
        
        // Check if it's AI's turn
        if game.currentPlayerIndex < game.players.count {
            let currentPlayer = game.players[game.currentPlayerIndex]
            if currentPlayer.userID == aiID && !currentPlayer.isFolded {
                print("🤖 It's AI's turn - executing")
                await executeAITurn()
            }
        }
    }
}
// MARK: - CodeAI Output
// *** MAXIMUM NUMBER OF LINES IS `600` **
/// Please consolidate your selection to under `600` lines
