import SwiftUI
import GroupActivities
import OSLog

/// View for Texas Hold'em game rooms
struct TexasHoldemView: View {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "TexasHoldemView")
    let room: Room
    let currentUser: User

    @State private var viewModel = TexasHoldemViewModel(gameService: TexasHoldemService())
    @State private var betAmount = 10
    @State private var sharePlayStarted = false
    @State private var currentRoom: Room
    @State private var refreshTimer: Timer?
    
    init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
        self._currentRoom = State(initialValue: room)
    }

    var body: some View {
        let _ = print("🟢 TexasHoldemView body rendering")
        let _ = print("   Room participants: \(currentRoom.participantIDs.count)")
        let _ = print("   SharePlay active: \(viewModel.sharePlayService.isSessionActive)")
        let _ = print("   SharePlay count: \(viewModel.sharePlayService.participantCount)")
        VStack(spacing: 0) {
            // Participant count and SharePlay indicator
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("\(currentRoom.participantIDs.count) player\(currentRoom.participantIDs.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // SharePlay status indicator
                if viewModel.sharePlayService.isSessionActive {
                    HStack(spacing: 4) {
                        Image(systemName: "shareplay")
                            .foregroundStyle(.green)
                        Text("SharePlay Active")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if let game = viewModel.currentGame {
                gameView(game)
            } else {
                startGameView
            }
        }
        .navigationTitle(room.name)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            // Setup SharePlay callbacks
            viewModel.setupSharePlayCallbacks()
            
            // Start watching for game updates from iCloud
            viewModel.startWatchingForGameUpdates(roomID: currentRoom.id)
            
            // Periodically refresh room data to get updated participant list
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task {
                    await refreshRoomData()
                }
            }
            
            // Auto-start game ONLY if we're the host and SharePlay is active
            // This prevents participants from auto-starting their own game
            if currentRoom.participantIDs.count >= 2 && 
               viewModel.currentGame == nil && 
               viewModel.sharePlayService.isSessionActive &&
               viewModel.sharePlayService.isHost {
                print("🎮 Auto-starting game as HOST with \(currentRoom.participantIDs.count) players")
                print("   SharePlay session is active and we are the host")
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds for SharePlay to fully connect
                    if viewModel.currentGame == nil {
                        let playerIDs = Array(currentRoom.participantIDs)
                        await viewModel.startGame(roomID: currentRoom.id, players: playerIDs)
                    }
                }
            } else {
                print("ℹ️ Not auto-starting game:")
                print("   Participants: \(currentRoom.participantIDs.count)")
                print("   Has game: \(viewModel.currentGame != nil)")
                print("   SharePlay active: \(viewModel.sharePlayService.isSessionActive)")
                print("   Is host: \(viewModel.sharePlayService.isHost)")
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private func refreshRoomData() async {
        print("🔄 refreshRoomData called")
        print("   SharePlay active: \(viewModel.sharePlayService.isSessionActive)")
        print("   SharePlay participant count: \(viewModel.sharePlayService.participantCount)")
        print("   Room participant count: \(currentRoom.participantIDs.count)")
        
        // Update participant count based on SharePlay if active
        if viewModel.sharePlayService.isSessionActive {
            // SharePlay is active - use actual participant count from session
            var updatedRoom = currentRoom
            let sharePlayParticipantCount = viewModel.sharePlayService.participantCount
            
            print("📊 SharePlay active with \(sharePlayParticipantCount) participants")
            
            // Ensure room has the correct number of participants
            while updatedRoom.participantIDs.count < sharePlayParticipantCount {
                let sharePlayParticipantID = UUID()
                updatedRoom.participantIDs.insert(sharePlayParticipantID)
                updatedRoom.participants.append(User(id: sharePlayParticipantID, username: "SharePlay User \(updatedRoom.participantIDs.count)"))
                print("   ➕ Added SharePlay participant #\(updatedRoom.participantIDs.count)")
            }
            
            if updatedRoom.participantIDs.count != currentRoom.participantIDs.count {
                await MainActor.run {
                    currentRoom = updatedRoom
                    print("📊 ✅ Updated room participant count to: \(self.currentRoom.participantIDs.count)")
                }
            } else {
                print("   ✓ Participant count already correct")
            }
        } else {
            print("   ⚠️ SharePlay not active, skipping update")
        }
    }

    private var startGameView: some View {
        VStack(spacing: 20) {
            Image(systemName: "suit.spade.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)

            Text("Texas Hold'em")
                .font(.title)
                .fontWeight(.bold)
            
            // SharePlay Status Indicator
            if viewModel.sharePlayService.isSessionActive {
                HStack(spacing: 8) {
                    Image(systemName: "shareplay")
                        .foregroundStyle(.green)
                    Text("SharePlay Active")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.sharePlayService.participantCount + 1) connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.15))
                .cornerRadius(12)
            }
            
            // Show loading state if checking for existing game
            if viewModel.isLoading {
                ProgressView("Checking for active game...")
                    .padding()
                Text("Game syncs automatically via SharePlay")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // SharePlay Button - prominently displayed
                if !viewModel.sharePlayService.isSessionActive {
                    Button {
                        Task {
                            await activateSharePlay()
                        }
                    } label: {
                        Label("Start SharePlay", systemImage: "shareplay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Text("Start SharePlay during a FaceTime call to sync with other players")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Detect Players Button
                if currentRoom.participantIDs.count < 2 {
                    Button {
                        Task {
                            await detectPlayers()
                        }
                    } label: {
                        Label("Detect Players", systemImage: "person.2.badge.gearshape")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                Button("Start Game") {
                    Task {
                        var playerIDs = Array(currentRoom.participantIDs)
                        
                        // Always add AI/computer player if less than 2 players
                        if playerIDs.count < 2 {
                            let aiPlayerID = UUID()
                            playerIDs.append(aiPlayerID)
                            print("🤖 Added AI player: \(aiPlayerID)")
                        }
                        
                        await viewModel.startGame(roomID: currentRoom.id, players: playerIDs)
                    }
                }
                .buttonStyle(.borderedProminent)

                if currentRoom.participantIDs.count < 2 {
                    Text("Playing against computer opponent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 4) {
                        Text("\(currentRoom.participantIDs.count) players ready")
                            .font(.caption)
                            .foregroundStyle(.green)
                        if viewModel.sharePlayService.isSessionActive {
                            Text("Syncs via SharePlay")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func createSharePlayActivity() -> TexasHoldemActivity? {
        // Create the activity for SharePlay
        return TexasHoldemActivity(
            roomID: room.id,
            gameID: viewModel.currentGame?.id ?? UUID(),
            roomName: room.name
        )
    }
    
    private func activateSharePlay() async {
        guard let activity = createSharePlayActivity() else {
            print("❌ Failed to create SharePlay activity")
            return
        }
        
        print("🚀 Activating SharePlay...")
        print("   Room ID: \(activity.roomID)")
        print("   Game ID: \(activity.gameID)")
        print("   Room Name: \(activity.roomName ?? "nil")")
        
        do {
            // Mark as host before activating
            viewModel.sharePlayService.isHost = true
            print("   🏠 Marked as host")
            
            // Activate the SharePlay session
            switch await activity.prepareForActivation() {
            case .activationPreferred:
                print("✅ SharePlay activation preferred - activating...")
                let result = try await activity.activate()
                print("✅ SharePlay activated successfully! Result: \(result)")
                
                // Give it a moment to connect
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                if viewModel.sharePlayService.isSessionActive {
                    print("🎉 SharePlay session is now active")
                    print("   Participant count: \(viewModel.sharePlayService.participantCount)")
                } else {
                    print("⚠️ SharePlay activated but session not yet active")
                }
                
            case .activationDisabled:
                print("⚠️ SharePlay activation disabled - not in FaceTime call?")
                
            case .cancelled:
                print("⚠️ SharePlay activation cancelled by user")
                
            @unknown default:
                print("⚠️ Unknown SharePlay activation result")
            }
        } catch {
            print("❌ SharePlay activation failed: \(error)")
        }
    }
    
    private func detectPlayers() async {
        print("🔍 Manually detecting players...")
        
        // Check if SharePlay/FaceTime is active
        if viewModel.sharePlayService.isSessionActive {
            var updatedRoom = currentRoom
            
            // Add SharePlay participants
            let sharePlayParticipantID = UUID()
            updatedRoom.participantIDs.insert(sharePlayParticipantID)
            updatedRoom.participants.append(User(id: sharePlayParticipantID, username: "FaceTime User"))
            currentRoom = updatedRoom
            
            print("✅ Detected SharePlay participant! Total: \(currentRoom.participantIDs.count)")
        } else {
            // Even if SharePlay isn't reporting active, add a second player for testing
            // This simulates the other device joining
            var updatedRoom = currentRoom
            let remoteParticipantID = UUID()
            updatedRoom.participantIDs.insert(remoteParticipantID)
            updatedRoom.participants.append(User(id: remoteParticipantID, username: "Remote Player"))
            currentRoom = updatedRoom
            
            print("✅ Added remote player for testing. Total: \(currentRoom.participantIDs.count)")
        }
    }

    private func gameView(_ game: TexasHoldemGame) -> some View {
        VStack(spacing: 20) {
            // Opponent's hand (face down until showdown)
            if let opponentPlayer = game.players.first(where: { $0.id != currentUser.id }) {
                opponentHandView(opponentPlayer, showCards: game.gamePhase == .showdown || game.gamePhase == .ended)
            }
            
            // Game phase and pot
            VStack(spacing: 8) {
                Text(game.gamePhase.rawValue.capitalized)
                    .font(.headline)

                Text("Pot: $\(game.pot)")
                    .font(.title2)
                    .fontWeight(.bold)
                    
                // Turn indicator
                if game.currentPlayerIndex < game.players.count {
                    let currentPlayer = game.players[game.currentPlayerIndex]
                    let isMyTurn = currentPlayer.id == currentUser.id
                    Text(isMyTurn ? "Your Turn" : "Opponent's Turn")
                        .font(.subheadline)
                        .foregroundStyle(isMyTurn ? .green : .orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(isMyTurn ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Deck - Click to advance phase
            if game.gamePhase != .ended && game.gamePhase != .showdown {
                Button {
                    Task {
                        await advancePhase()
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Tap to deal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100, height: 120)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Community cards
            if !game.communityCards.isEmpty {
                communityCardsView(game.communityCards)
            }

            Spacer()

            // Player's hand
            if let player = viewModel.getPlayer(for: currentUser.id) {
                playerHandView(player)
            }

            // Controls
            if game.gamePhase != .ended {
                gameControls(phase: game.gamePhase, isMyTurn: game.players[game.currentPlayerIndex].id == currentUser.id)
            } else {
                Button("End Game") {
                    Task {
                        await viewModel.endGame()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func advancePhase() async {
        guard let game = viewModel.currentGame else { return }
        
        switch game.gamePhase {
        case .preFlop:
            // Deal flop (3 cards)
            await viewModel.dealFlop()
        case .flop:
            // Deal turn (1 card)
            await viewModel.dealTurn()
        case .turn:
            // Deal river (1 card)
            await viewModel.dealRiver()
        case .river:
            // Go to showdown
            await viewModel.showdown()
        default:
            break
        }
    }

    private func communityCardsView(_ cards: [PlayingCard]) -> some View {
        HStack(spacing: 8) {
            ForEach(cards) { card in
                CardView(card: card)
            }
        }
    }

    private func playerHandView(_ player: TexasHoldemPlayer) -> some View {
        VStack(spacing: 12) {
            Text("Your Hand")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(player.hand) { card in
                    CardView(card: card)
                }
            }

            HStack {
                Text("Chips: $\(player.chips)")
                    .font(.subheadline)

                Spacer()

                Text("Current Bet: $\(player.currentBet)")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func opponentHandView(_ player: TexasHoldemPlayer, showCards: Bool) -> some View {
        VStack(spacing: 12) {
            Text(showCards ? "Opponent's Hand" : "Opponent")
                .font(.headline)

            HStack(spacing: 12) {
                if showCards {
                    // Showdown - reveal opponent's cards
                    ForEach(player.hand) { card in
                        CardView(card: card)
                    }
                } else {
                    // Show card backs (face down)
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 84)
                            .overlay {
                                Image(systemName: "suit.spade.fill")
                                    .font(.title)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                    }
                }
            }

            HStack {
                Text("Chips: $\(player.chips)")
                    .font(.subheadline)

                Spacer()

                Text("Current Bet: $\(player.currentBet)")
                    .font(.subheadline)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func gameControls(phase: TexasHoldemGame.GamePhase, isMyTurn: Bool) -> some View {
        VStack(spacing: 12) {
            if !isMyTurn {
                Text("Waiting for opponent...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                // Actions based on phase
                if phase == .preFlop || phase == .flop {
                    // Preflop and Flop: Call or Fold only
                    HStack(spacing: 12) {
                        Button("Fold") {
                            Task {
                                await viewModel.fold(playerID: currentUser.id)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .frame(maxWidth: .infinity)

                        Button("Call") {
                            Task {
                                await viewModel.call(playerID: currentUser.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Turn and River: Call, Check, Raise, or Fold
                    HStack(spacing: 12) {
                        Button("Fold") {
                            Task {
                                await viewModel.fold(playerID: currentUser.id)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)

                        Button("Check") {
                            Task {
                                await viewModel.check(playerID: currentUser.id)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Call") {
                            Task {
                                await viewModel.call(playerID: currentUser.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Raise") {
                            Task {
                                await viewModel.bet(playerID: currentUser.id, amount: betAmount)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
        }
        .disabled(!isMyTurn)
    }

    private func startSharePlay() async {
        print("🃏 Starting Texas Hold'em SharePlay for room: \(room.name)")
        
        do {
            try await viewModel.startSharePlay(roomID: room.id, roomName: room.name)
            sharePlayStarted = true
            print("✅ Texas Hold'em SharePlay started successfully")
        } catch {
            print("❌ Failed to start Texas Hold'em SharePlay: \(error)")
        }
    }
}

/// Card view component
struct CardView: View {
    let card: PlayingCard

    var body: some View {
        VStack(spacing: 4) {
            Text(card.rank.rawValue)
                .font(.title2)
                .fontWeight(.bold)

            Text(card.suit.rawValue)
                .font(.title3)
        }
        .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
        .frame(width: 60, height: 90)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
}

#Preview {
    NavigationStack {
        TexasHoldemView(
            room: Room(name: "Poker Night", hostID: UUID(), activityType: .texasHoldem),
            currentUser: User(username: "Test User")
        )
    }
}
