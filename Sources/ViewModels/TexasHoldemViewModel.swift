import Foundation
import Observation

/// ViewModel for Texas Hold'em game rooms
@MainActor
@Observable
final class TexasHoldemViewModel: LayoverViewModel {
    private let gameService: TexasHoldemServiceProtocol
    let sharePlayService: TexasHoldemSharePlayService
    private let roomService: RoomServiceProtocol

    private(set) var currentGame: TexasHoldemGame?
    private(set) var isLoading = false
    var errorMessage: String?
    
    // Test SharePlay connectivity
    var testMessages: [String] = []
    var testConnectionStatus: String = ""
    var isTestingConnection = false
    
    // Track which player is local to this device
    private(set) var localPlayerID: UUID?
    
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
        print("🔧 Setting up SharePlay callbacks...")
        print("   Current session active: \(sharePlayService.isSessionActive)")
        print("   Is host: \(sharePlayService.isHost)")
        
        sharePlayService.onSessionActivated = { [weak self] in
            Task { @MainActor in
                print("🎊 SharePlay session activated - triggering UI update")
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
                        let game = try await gameService.startGame(roomID: roomID, players: playerIDs)
                        currentGame = game
                        
                        // Deal cards locally - each device gets its own unique random cards
                        // Cards are private until showdown, so each device deals independently
                        try await gameService.dealCards()
                        currentGame = gameService.currentGame
                        
                        print("✅ Participant game started successfully - cards dealt locally")
                        print("   Game ID: \(game.id)")
                        print("   Players in game: \(game.players.map { $0.userID })")
                        if let currentGame = currentGame {
                            for (index, player) in currentGame.players.enumerated() {
                                print("   Player \(index) (\(player.userID)): \(player.hand.count) cards")
                                for card in player.hand {
                                    print("      - \(card.rank.rawValue) of \(card.suit.rawValue)")
                                }
                            }
                        }
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
        
        sharePlayService.onParticipantCountChanged = { [weak self] count in
            Task { @MainActor in
                print("👥 SharePlay participant count changed to: \(count)")
                // Trigger UI refresh by updating version counter
                self?.sharePlayStateVersion += 1
            }
        }
        
        sharePlayService.onTestPingReceived = { [weak self] from, message in
            Task { @MainActor in
                guard let self = self else { return }
                print("🏓 Test ping received from: \(from), message: \(message)")
                self.testMessages.append("Received from \(from): \(message)")
                
                // Auto-respond with pong
                let responseRole = self.sharePlayService.isHost ? "host" : "guest"
                let responseMessage = "Hello \(from == "host" ? "host" : "guest")"
                await self.sharePlayService.sendTestPong(from: responseRole, message: responseMessage)
                self.testMessages.append("Sent: \(responseMessage)")
            }
        }
        
        sharePlayService.onTestPongReceived = { [weak self] from, message in
            Task { @MainActor in
                guard let self = self else { return }
                print("🏓 Test pong received from: \(from), message: \(message)")
                self.testMessages.append("Received from \(from): \(message)")
                self.isTestingConnection = false
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
        
        // Set local player ID (first player for host, second for participant)
        localPlayerID = sharePlayService.isHost ? players.first : (players.count > 1 ? players[1] : players.first)
        print("   Local player ID: \(localPlayerID?.uuidString ?? "none")")
        
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
            print("   Players: \(currentGame?.players.count ?? 0)")
            if let currentGame = currentGame {
                for (index, player) in currentGame.players.enumerated() {
                    print("   Player \(index) (\(player.userID)): \(player.hand.count) cards")
                    for card in player.hand {
                        print("      - \(card.rank.rawValue) of \(card.suit.rawValue)")
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
            saveGameState()
            
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
            saveGameState()
            
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
            saveGameState()
            
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
        
        // Only host should deal community cards
        if sharePlayService.isSessionActive && !sharePlayService.isHost {
            print("⚠️ Non-host tried to deal flop - ignoring")
            return
        }
        
        do {
            print("🎴 dealFlop called - current community cards: \(currentGame?.communityCards.count ?? 0)")
            try await gameService.dealFlop()
            currentGame = gameService.currentGame
            print("✅ Flop dealt - now have \(currentGame?.communityCards.count ?? 0) community cards")
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
        try await sharePlayService.startActivity(roomID: roomID, gameID: tempGameID, roomName: roomName)
        print("✅ SharePlay session activated successfully")
    }
    
    private func broadcastGameState() async {
        guard let game = currentGame else {
            print("⚠️ broadcastGameState: No current game to broadcast")
            return
        }
        
        print("📡 Broadcasting game state...")
        print("   Community cards: \(game.communityCards.count)")
        for card in game.communityCards {
            print("      - \(card.rank.rawValue) of \(card.suit.rawValue)")
        }
        
        let state = TexasHoldemGameState(
            gameID: game.id,
            currentPlayerIndex: game.currentPlayerIndex,
            pot: game.pot,
            currentBet: game.currentBet,
            phase: game.gamePhase.rawValue,
            communityCards: game.communityCards.map { PlayingCardData(rank: $0.rank.rawValue, suit: $0.suit.rawValue) },
            playerStates: game.players.map { player in
                // Only include cards during showdown OR if this is not the receiving player's hand
                // During normal play, we don't broadcast each player's private cards
                let shouldIncludeCards = game.gamePhase == .showdown
                return TexasHoldemGameState.PlayerState(
                    id: player.userID,
                    chips: player.chips,
                    currentBet: player.currentBet,
                    hasFolded: player.isFolded,
                    cards: shouldIncludeCards ? player.hand.map { PlayingCardData(rank: $0.rank.rawValue, suit: $0.suit.rawValue) } : nil
                )
            }
        )
        
        print("📤 Sending gameStateUpdate message with \(state.communityCards.count) community cards")
        await sharePlayService.sendMessage(.gameStateUpdate(state))
        print("✅ Game state broadcast complete")
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
        
        print("📥 Applying game state from SharePlay")
        print("   Phase: \(state.phase)")
        print("   Community cards: \(state.communityCards.count)")
        print("   Players: \(state.playerStates.count)")
        
        // Update basic game state
        game.currentPlayerIndex = state.currentPlayerIndex
        game.pot = state.pot
        game.currentBet = state.currentBet
        
        // Update phase
        if let phase = TexasHoldemGame.GamePhase(rawValue: state.phase) {
            game.gamePhase = phase
        }
        
        // Update community cards (but don't clear them if we already have cards and incoming is empty)
        let incomingCards = state.communityCards.compactMap { cardData -> PlayingCard? in
            guard let rank = PlayingCard.Rank(rawValue: cardData.rank),
                  let suit = PlayingCard.Suit(rawValue: cardData.suit) else {
                return nil
            }
            return PlayingCard(rank: rank, suit: suit)
        }
        
        print("🃏 Community card sync - current: \(game.communityCards.count), incoming: \(incomingCards.count)")
        
        // Only update if incoming has cards OR if we don't have any yet
        if !incomingCards.isEmpty || game.communityCards.isEmpty {
            game.communityCards = incomingCards
            print("✅ Applied \(game.communityCards.count) community cards")
            for card in game.communityCards {
                print("   - \(card.rank.rawValue) of \(card.suit.rawValue)")
            }
        } else {
            print("⚠️ Skipping community card update - keeping existing \(game.communityCards.count) cards")
        }
        
        // Update player states
        for playerState in state.playerStates {
            if let index = game.players.firstIndex(where: { $0.userID == playerState.id }) {
                print("   Updating player \(index): chips=\(playerState.chips), bet=\(playerState.currentBet)")
                game.players[index].chips = playerState.chips
                game.players[index].currentBet = playerState.currentBet
                game.players[index].isFolded = playerState.hasFolded
                
                // NEVER overwrite our own player's cards (unless during showdown)
                // Only update opponent's cards
                let isLocalPlayer = game.players[index].userID == localPlayerID
                
                if !isLocalPlayer && playerState.cards != nil {
                    // This is an opponent - update their hand (usually during showdown)
                    let incomingHand = playerState.cards!.compactMap { cardData -> PlayingCard? in
                        guard let rank = PlayingCard.Rank(rawValue: cardData.rank),
                              let suit = PlayingCard.Suit(rawValue: cardData.suit) else {
                            return nil
                        }
                        return PlayingCard(rank: rank, suit: suit)
                    }
                    game.players[index].hand = incomingHand
                    print("   ✅ Updated opponent player \(index) cards (showdown)")
                } else if isLocalPlayer {
                    print("   ⏭️  Skipping card update for local player \(index) - keeping own cards")
                }
            }
        }
        
        currentGame = game
        print("✅ Game state applied successfully")
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
            print(currentGame == nil ? "ℹ️ No existing game found after 10 seconds - ready to start new game" : "✅ Loaded existing game from iCloud")
            
            // Continue polling for updates while waiting for a game OR while a game is active
            while true {
                if let game = roomService.getActiveGame(for: roomID) {
                    if currentGame == nil {
                        // Game was just created - load it
                        print("🆕 New game detected in iCloud!")
                        currentGame = game
                        gameService.loadGame(game)
                    } else if game.id == currentGame?.id {
                        // Update existing game if state changed
                        // But DON'T overwrite if we have more community cards locally
                        let shouldUpdate = game.currentPlayerIndex != currentGame?.currentPlayerIndex ||
                           game.pot != currentGame?.pot ||
                           game.gamePhase != currentGame?.gamePhase
                        
                        if shouldUpdate {
                            print("🔄 Game state updated from iCloud")
                            // Preserve community cards if we have more locally
                            if let current = currentGame, game.communityCards.count < current.communityCards.count {
                                print("   ⚠️ iCloud has fewer community cards (\(game.communityCards.count)) than local (\(current.communityCards.count)) - keeping local")
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
}
    
    // MARK: - Test SharePlay Connectivity
    
    func testSharePlayConnection() async {
        print("🧪 Testing SharePlay connection...")
        testMessages = []
        testConnectionStatus = ""
        isTestingConnection = true
        
        // Check if SharePlay is active
        if !sharePlayService.isSessionActive {
            testConnectionStatus = "❌ SharePlay is not active"
            testMessages.append("Error: SharePlay session is not active")
            testMessages.append("Please start SharePlay during a FaceTime call")
            isTestingConnection = false
            return
        }
        
        // Check participant count
        if sharePlayService.participantCount < 1 {
            testConnectionStatus = "❌ No other participants"
            testMessages.append("Error: No other participants in SharePlay session")
            testMessages.append("SharePlay requires at least 2 participants")
            isTestingConnection = false
            return
        }
        
        // Send test ping
        let role = sharePlayService.isHost ? "host" : "guest"
        let targetRole = sharePlayService.isHost ? "guest" : "host"
        let message = "Hello \(targetRole)"
        
        testMessages.append("Sending test ping as \(role)...")
        testMessages.append("Message: \(message)")
        testConnectionStatus = "🔄 Testing..."
        
        await sharePlayService.sendTestPing(from: role, message: message)
        
        // Wait for response (timeout after 5 seconds)
        var attempts = 0
        while isTestingConnection && attempts < 50 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
        }
        
        if isTestingConnection {
            // Timeout
            testConnectionStatus = "❌ Connection timeout"
            testMessages.append("Error: No response received after 5 seconds")
            testMessages.append("Possible issues:")
            testMessages.append("- Other participant may not have the app open")
            testMessages.append("- Network connectivity issues")
            testMessages.append("- SharePlay session may not be properly synced")
            isTestingConnection = false
        } else {
            testConnectionStatus = "✅ Connection successful"
        }
    
    // MARK: - Test SharePlay Connectivity
    
    func testSharePlayConnection() async {
        print("🧪 Testing SharePlay connection...")
        testMessages = []
        testConnectionStatus = ""
        isTestingConnection = true
        
        // Check if SharePlay is active
        if !sharePlayService.isSessionActive {
            testConnectionStatus = "❌ SharePlay is not active"
            testMessages.append("Error: SharePlay session is not active")
            testMessages.append("Please start SharePlay during a FaceTime call")
            isTestingConnection = false
            return
        }
        
        // Check participant count
        if sharePlayService.participantCount < 1 {
            testConnectionStatus = "❌ No other participants"
            testMessages.append("Error: No other participants in SharePlay session")
            testMessages.append("SharePlay requires at least 2 participants")
            isTestingConnection = false
            return
        }
        
        // Send test ping
        let role = sharePlayService.isHost ? "host" : "guest"
        let targetRole = sharePlayService.isHost ? "guest" : "host"
        let message = "Hello \(targetRole)"
        
        testMessages.append("Sending test ping as \(role)...")
        testMessages.append("Message: \(message)")
        testConnectionStatus = "🔄 Testing..."
        
        await sharePlayService.sendTestPing(from: role, message: message)
        
        // Wait for response (timeout after 5 seconds)
        var attempts = 0
        while isTestingConnection && attempts < 50 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
        }
        
        if isTestingConnection {
            // Timeout
            testConnectionStatus = "❌ Connection timeout"
            testMessages.append("Error: No response received after 5 seconds")
            testMessages.append("Possible issues:")
            testMessages.append("- Other participant may not have the app open")
            testMessages.append("- Network connectivity issues")
            testMessages.append("- SharePlay session may not be properly synced")
            isTestingConnection = false
        } else {
            testConnectionStatus = "✅ Connection successful"
        }
    }
}
