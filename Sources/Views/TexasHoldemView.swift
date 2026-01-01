import GroupActivities
import OSLog
import SwiftUI

/// View for Texas Hold'em game rooms
struct TexasHoldemView: View {
    private let logger = Logger(
        subsystem: "com.bholsinger.LayoverLounge", category: "TexasHoldemView")
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
        let _ = print("   SharePlay is host: \(viewModel.sharePlayService.isHost)")
        let _ = print("   SharePlay count: \(viewModel.sharePlayService.participantCount)")
        let _ = print("   SharePlay version: \(viewModel.sharePlayStateVersion)")
        
        VStack(spacing: 0) {
            // Participant count and SharePlay indicator
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text(
                    "\(currentRoom.participantIDs.count) player\(currentRoom.participantIDs.count == 1 ? "" : "s")"
                )
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
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(viewModel.sharePlayService.isHost ? "Host" : "Guest")
                            .font(.caption)
                            .foregroundStyle(viewModel.sharePlayService.isHost ? .blue : .purple)
                            .fontWeight(.semibold)
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
        .onAppear {
            print("🟢 TexasHoldemView appeared - setting up callbacks")
            print("🟢 Current SharePlay state:")
            print("   Is active: \(viewModel.sharePlayService.isSessionActive)")
            print("   Is host: \(viewModel.sharePlayService.isHost)")
            
            // Setup SharePlay callbacks - critical for observer to start
            viewModel.setupSharePlayCallbacks()
            
            print("🟢 SharePlay observer should now be listening for sessions")
        }
        .task {
            print("📋 TexasHoldemView .task started")

            // Add current user to room participants if not already there
            if !currentRoom.participantIDs.contains(currentUser.id) {
                var updatedRoom = currentRoom
                updatedRoom.participantIDs.insert(currentUser.id)
                updatedRoom.participants.append(currentUser)
                currentRoom = updatedRoom
                print("➕ Added current user to room participants: \(currentUser.id)")
            }

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
            if currentRoom.participantIDs.count >= 2 && viewModel.currentGame == nil
                && viewModel.sharePlayService.isSessionActive && viewModel.sharePlayService.isHost
            {
                print(
                    "🎮 Auto-starting game as HOST with \(currentRoom.participantIDs.count) players")
                print("   SharePlay session is active and we are the host")
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)  // Wait 2 seconds for SharePlay to fully connect
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
                updatedRoom.participants.append(
                    User(
                        id: sharePlayParticipantID,
                        username: "SharePlay User \(updatedRoom.participantIDs.count)"))
                print("   ➕ Added SharePlay participant #\(updatedRoom.participantIDs.count)")
            }

            if updatedRoom.participantIDs.count != currentRoom.participantIDs.count {
                await MainActor.run {
                    currentRoom = updatedRoom
                    print(
                        "📊 ✅ Updated room participant count to: \(self.currentRoom.participantIDs.count)"
                    )
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

            // SharePlay Status Indicator - reference viewModel.sharePlayStateVersion to trigger updates
            if viewModel.sharePlayService.isSessionActive {
                let _ = viewModel.sharePlayStateVersion  // Force dependency
                VStack(spacing: 8) {
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
                    HStack(spacing: 4) {
                        Text("You are the")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.sharePlayService.isHost ? "Host" : "Guest")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(viewModel.sharePlayService.isHost ? .blue : .purple)
                    }
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
                // SharePlay Button - prominently displayed ONLY if not in a session
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
                } else {
                    // Already in SharePlay session - show status
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Connected via SharePlay")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("You are the \(viewModel.sharePlayService.isHost ? "Host" : "Guest")")
                                    .font(.subheadline)
                                    .foregroundStyle(viewModel.sharePlayService.isHost ? .blue : .purple)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // Debug info - commented out after testing
                // #if DEBUG
                // VStack(alignment: .leading, spacing: 4) {
                //     Text("Debug Info:")
                //         .font(.caption2)
                //         .fontWeight(.bold)
                //     Text("Session Active: \(viewModel.sharePlayService.isSessionActive ? "YES" : "NO")")
                //         .font(.caption2)
                //     Text("Is Host: \(viewModel.sharePlayService.isHost ? "YES" : "NO")")
                //         .font(.caption2)
                //     Text("Participant Count: \(viewModel.sharePlayService.participantCount)")
                //         .font(.caption2)
                //     Text("State Version: \(viewModel.sharePlayStateVersion)")
                //         .font(.caption2)
                // }
                // .padding(8)
                // .background(Color.orange.opacity(0.1))
                // .cornerRadius(6)
                // .padding(.horizontal)
                // #endif
                
                // Test SharePlay Button - commented out after testing
                // if viewModel.sharePlayService.isSessionActive {
                //     testSharePlaySection
                // }

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
                        // First, end any existing game to ensure clean start
                        if viewModel.currentGame != nil {
                            await viewModel.endGame()
                            print("🧹 Cleared existing game before starting new one")
                        }

                        var playerIDs = Array(currentRoom.participantIDs)

                        // Ensure current user is in the player list
                        if !playerIDs.contains(currentUser.id) {
                            playerIDs.append(currentUser.id)
                            print("➕ Added current user to player list: \(currentUser.id)")
                        }

                        // Always add AI/computer player if less than 2 players
                        if playerIDs.count < 2 {
                            let aiPlayerID = UUID()
                            playerIDs.append(aiPlayerID)
                            print("🤖 Added AI player: \(aiPlayerID)")
                        }

                        print("🎮 Starting game with player IDs: \(playerIDs)")
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
    
    // Test SharePlay section - commented out after testing
    // private var testSharePlaySection: some View {
    //     VStack(spacing: 16) {
    //         // Role indicator
    //         VStack(spacing: 8) {
    //             HStack {
    //                 Text("Your Role:")
    //                     .font(.subheadline)
    //                     .foregroundStyle(.secondary)
    //                 Spacer()
    //                 Text(viewModel.sharePlayService.isHost ? "🏠 Host" : "👤 Guest")
    //                     .font(.headline)
    //                     .foregroundStyle(viewModel.sharePlayService.isHost ? .blue : .purple)
    //             }
    //             Text("Participants: \(viewModel.sharePlayService.participantCount + 1)")
    //                 .font(.caption)
    //                 .foregroundStyle(.secondary)
    //                 .frame(maxWidth: .infinity, alignment: .leading)
    //         }
    //         .padding()
    //         .background(Color.secondary.opacity(0.1))
    //         .cornerRadius(10)
    //         .padding(.horizontal)
    //         
    //         // Ping button
    //         Button {
    //             print("🔴 PING BUTTON TAPPED!")
    //             Task {
    //                 await viewModel.sendPingToOtherUser()
    //             }
    //         } label: {
    //             Label(
    //                 viewModel.isTestingConnection ? "Sending..." : "Ping \(viewModel.sharePlayService.isHost ? "Guest" : "Host")",
    //                 systemImage: "antenna.radiowaves.left.and.right"
    //             )
    //             .frame(maxWidth: .infinity)
    //             .padding()
    //             .background(viewModel.sharePlayService.isHost ? Color.blue : Color.purple)
    //             .foregroundStyle(.white)
    //             .cornerRadius(10)
    //         }
    //         .disabled(viewModel.isTestingConnection || viewModel.sharePlayService.participantCount < 1)
    //         .opacity(viewModel.sharePlayService.participantCount < 1 ? 0.5 : 1.0)
    //         .padding(.horizontal)
    //         
    //         if viewModel.sharePlayService.participantCount < 1 {
    //             Text("Waiting for another participant to join...")
    //                 .font(.caption)
    //                 .foregroundStyle(.orange)
    //                 .padding(.horizontal)
    //         }
    //         
    //         // Full test with diagnostics
    //         Button {
    //             Task {
    //                 await viewModel.testSharePlayConnection()
    //             }
    //         } label: {
    //             Label(
    //                 "Advanced Diagnostics",
    //                 systemImage: "stethoscope"
    //             )
    //             .frame(maxWidth: .infinity)
    //             .padding()
    //             .background(Color.orange)
    //             .foregroundStyle(.white)
    //             .cornerRadius(10)
    //         }
    //         .disabled(viewModel.isTestingConnection)
    //         .padding(.horizontal)
    //         
    //         // Test results and messages
    //         if !viewModel.testConnectionStatus.isEmpty {
    //             VStack(alignment: .leading, spacing: 8) {
    //                 Text(viewModel.testConnectionStatus)
    //                     .font(.headline)
    //                     .foregroundStyle(
    //                         viewModel.testConnectionStatus.starts(with: "✅") ? .green : .red
    //                     )
    //                 
    //                 if !viewModel.testMessages.isEmpty {
    //                     ScrollView {
    //                         VStack(alignment: .leading, spacing: 4) {
    //                             ForEach(viewModel.testMessages, id: \.self) { message in
    //                                 Text(message)
    //                                     .font(.caption)
    //                                     .foregroundStyle(
    //                                         message.contains("✅") ? .green :
    //                                         message.contains("❌") ? .red : .secondary
    //                                     )
    //                                     .fontWeight(message.contains("📥") || message.contains("📤") ? .semibold : .regular)
    //                             }
    //                         }
    //                     }
    //                     .frame(maxHeight: 200)
    //                 }
    //             }
    //             .padding()
    //             .frame(maxWidth: .infinity, alignment: .leading)
    //             .background(Color.secondary.opacity(0.1))
    //             .cornerRadius(10)
    //             .padding(.horizontal)
    //         }
    //     }
    // }

    private func isMyTurnInGame(game: TexasHoldemGame) -> Bool {
        // In SharePlay mode, determine turn based on role
        if viewModel.sharePlayService.isSessionActive {
            // Host is player 0, Guest is player 1
            let myPlayerIndex = viewModel.sharePlayService.isHost ? 0 : 1
            return game.currentPlayerIndex == myPlayerIndex
        } else {
            // Non-SharePlay mode: check by currentUser.id
            return game.players[game.currentPlayerIndex].userID == currentUser.id
        }
    }
    
    private func getMyPlayerID(game: TexasHoldemGame) -> UUID {
        // In SharePlay mode, get player ID based on role
        if viewModel.sharePlayService.isSessionActive {
            // Host is player 0, Guest is player 1
            let myPlayerIndex = viewModel.sharePlayService.isHost ? 0 : 1
            return game.players[myPlayerIndex].userID
        } else {
            // Non-SharePlay mode: use currentUser.id
            return currentUser.id
        }
    }

    private func activateSharePlay() async {
        print("🚀 Activating SharePlay...")
        print("   Room ID: \(room.id)")
        print("   Room Name: \(room.name)")

        do {
            // Use the service's startActivity method which properly sets the host flag
            try await viewModel.sharePlayService.startActivity(
                roomID: room.id,
                gameID: viewModel.currentGame?.id ?? UUID(),
                roomName: room.name
            )
            
            print("✅ SharePlay activated successfully via service!")
            
            // Give it a moment to connect
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            if viewModel.sharePlayService.isSessionActive {
                print("🎉 SharePlay session is now active")
                print("   Is Host: \(viewModel.sharePlayService.isHost)")
                print("   Participant count: \(viewModel.sharePlayService.participantCount)")
            } else {
                print("⚠️ SharePlay activated but session not yet active")
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
            updatedRoom.participants.append(
                User(id: sharePlayParticipantID, username: "FaceTime User"))
            currentRoom = updatedRoom

            print("✅ Detected SharePlay participant! Total: \(currentRoom.participantIDs.count)")
        } else {
            // Even if SharePlay isn't reporting active, add a second player for testing
            // This simulates the other device joining
            var updatedRoom = currentRoom
            let remoteParticipantID = UUID()
            updatedRoom.participantIDs.insert(remoteParticipantID)
            updatedRoom.participants.append(
                User(id: remoteParticipantID, username: "Remote Player"))
            currentRoom = updatedRoom

            print("✅ Added remote player for testing. Total: \(currentRoom.participantIDs.count)")
        }
    }

    private func gameView(_ game: TexasHoldemGame) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Opponent's hand (face down until showdown)
                if let opponentPlayer = game.players.first(where: { $0.userID != currentUser.id }) {
                    opponentHandView(
                        opponentPlayer,
                        showCards: game.gamePhase == .showdown || game.gamePhase == .ended)
                }
                // Game phase and pot
                VStack(spacing: 8) {
                    Text(game.gamePhase.rawValue.capitalized)
                        .font(.headline)

                    Text("Pot: $\(game.pot)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Winner announcement (showdown phase)
                    if game.gamePhase == .showdown, let winnerID = game.winnerID {
                        VStack(spacing: 8) {
                            Text("🏆 Winner!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.yellow)
                            
                            if winnerID == currentUser.id {
                                Text("You won $\(game.winningAmount)!")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            } else {
                                Text("Opponent won $\(game.winningAmount)")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                    } else if game.gamePhase == .showdown && game.winnerID == nil && game.winningAmount > 0 {
                        // Tie game
                        VStack(spacing: 8) {
                            Text("🤝 It's a Tie!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text("Pot split: $\(game.winningAmount) each")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                    }

                    // Turn indicator
                    if game.currentPlayerIndex < game.players.count && game.gamePhase != .showdown {
                        let isMyTurn = isMyTurnInGame(game: game)
                        let _ = print("🎮 VIEW: isMyTurn=\(isMyTurn), currentPlayerIndex=\(game.currentPlayerIndex), isHost=\(viewModel.sharePlayService.isHost)")
                        Text(isMyTurn ? "Your Turn" : "Opponent's Turn")
                            .font(.subheadline)
                            .foregroundStyle(isMyTurn ? .green : .orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                isMyTurn ? Color.green.opacity(0.2) : Color.orange.opacity(0.2)
                            )
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Deck - Click to advance phase (host only in SharePlay)
                if game.gamePhase != .ended && game.gamePhase != .showdown {
                    if !viewModel.sharePlayService.isSessionActive
                        || viewModel.sharePlayService.isHost
                    {
                        Button {
                            Task {
                                await advancePhase()
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.blue)
                                Text("Tap to deal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 100, height: 100)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        // Waiting indicator for non-host participants
                        VStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.gray)
                            Text("Waiting for host")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 100, height: 100)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Community cards
                if !game.communityCards.isEmpty {
                    let _ = print("🎴 Displaying \(game.communityCards.count) community cards:")
                    let _ = game.communityCards.forEach {
                        print("   - \($0.rank.rawValue) of \($0.suit.rawValue)")
                    }
                    communityCardsView(game.communityCards)
                }

                // Player's hand
                if let player = viewModel.getPlayer(for: currentUser.id) {
                    playerHandView(player)
                    let _ = print("✅ Showing player hand for currentUser.id: \(currentUser.id)")
                } else {
                    // Fallback: if we can't find by currentUser.id, show the second player (participant)
                    // or first player (host) depending on who we are
                    if let game = viewModel.currentGame, game.players.count >= 2 {
                        let playerIndex = viewModel.sharePlayService.isHost ? 0 : 1
                        let fallbackPlayer = game.players[playerIndex]
                        playerHandView(fallbackPlayer)
                        let _ = print(
                            "⚠️ Using fallback player[\(playerIndex)] for display (isHost=\(viewModel.sharePlayService.isHost)): \(fallbackPlayer.userID)"
                        )
                        let _ = print(
                            "   Cards: \(fallbackPlayer.hand.map { "\($0.rank.rawValue) of \($0.suit.rawValue)" })"
                        )
                    } else if let game = viewModel.currentGame, let firstPlayer = game.players.first
                    {
                        playerHandView(firstPlayer)
                        let _ = print("⚠️ Using first player as fallback: \(firstPlayer.userID)")
                        let _ = print(
                            "   Cards: \(firstPlayer.hand.map { "\($0.rank.rawValue) of \($0.suit.rawValue)" })"
                        )
                    }
                }

                // Controls
                if game.gamePhase == .showdown {
                    // Showdown - offer to start new hand
                    VStack(spacing: 12) {
                        Button("Start New Hand") {
                            Task {
                                // Reset game for new hand
                                await viewModel.endGame()
                                
                                // Start new game with same players
                                let playerIDs = game.players.map { $0.userID }
                                await viewModel.startGame(roomID: room.id, players: playerIDs)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        
                        Button("End Game") {
                            Task {
                                await viewModel.endGame()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                } else if game.gamePhase != .ended {
                    VStack(spacing: 12) {
                        gameControls(
                            game: game,
                            phase: game.gamePhase,
                            isMyTurn: isMyTurnInGame(game: game)
                        )

                        // New Game button
                        Button("Start New Game") {
                            Task {
                                await viewModel.endGame()

                                var playerIDs = Array(currentRoom.participantIDs)
                                if !playerIDs.contains(currentUser.id) {
                                    playerIDs.append(currentUser.id)
                                }
                                if playerIDs.count < 2 {
                                    playerIDs.append(UUID())
                                }

                                await viewModel.startGame(
                                    roomID: currentRoom.id, players: playerIDs)
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
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
            .padding(.bottom, 20)
        }
        #if os(macOS)
            .frame(minHeight: 600)
        #endif
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
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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

    private func gameControls(game: TexasHoldemGame, phase: TexasHoldemGame.GamePhase, isMyTurn: Bool) -> some View {
        let myPlayerID = getMyPlayerID(game: game)
        
        return VStack(spacing: 12) {
            // Show waiting message when not your turn, but keep controls visible (disabled)
            if !isMyTurn {
                Text("Waiting for opponent...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            // Bet amount slider - always visible
            VStack(spacing: 8) {
                HStack {
                    Text("Bet Amount:")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(betAmount)")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Slider(
                    value: Binding(
                        get: { Double(betAmount) },
                        set: { betAmount = Int($0) }
                    ), in: 10...100, step: 10
                )
                .tint(.green)
                .disabled(!isMyTurn)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(isMyTurn ? 1.0 : 0.6)

            // All poker actions available - always visible
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Fold") {
                        Task {
                            await viewModel.fold(playerID: myPlayerID)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .frame(maxWidth: .infinity)

                    Button("Check") {
                        Task {
                            await viewModel.check(playerID: myPlayerID)
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(!isMyTurn || phase == .preFlop || phase == .flop)
                    .opacity((!isMyTurn || phase == .preFlop || phase == .flop) ? 0.5 : 1.0)
                }

                HStack(spacing: 12) {
                    Button(game.currentBet == 0 ? "Bet $10" : "Call $\(game.currentBet)") {
                        Task {
                            await viewModel.call(playerID: myPlayerID)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button("Raise $\(betAmount)") {
                        Task {
                            await viewModel.bet(playerID: myPlayerID, amount: betAmount)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                    .disabled(game.currentBet == 0)
                    .opacity(game.currentBet == 0 ? 0.5 : 1.0)
                }
            }
            .disabled(!isMyTurn)
            .opacity(isMyTurn ? 1.0 : 0.6)
        }
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
