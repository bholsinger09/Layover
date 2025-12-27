import SwiftUI

/// View for Texas Hold'em game rooms
struct TexasHoldemView: View {
    let room: Room
    let currentUser: User

    @State private var viewModel = TexasHoldemViewModel(gameService: TexasHoldemService())
    @State private var betAmount = 10
    @State private var sharePlayService = SharePlayService()
    @State private var sharePlayStarted = false
    @State private var currentRoom: Room
    @State private var refreshTimer: Timer?
    
    init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
        self._currentRoom = State(initialValue: room)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Participant count indicator
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("\(currentRoom.participantIDs.count) player\(currentRoom.participantIDs.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // SharePlay prompt banner
            if !sharePlayStarted && !sharePlayService.isSessionActive {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await startSharePlay()
                        }
                    } label: {
                        Label("Start SharePlay to play together", systemImage: "shareplay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }

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
            // Periodically refresh room data to get updated participant list
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task {
                    await refreshRoomData()
                }
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
        // Update participant count based on SharePlay if active
        if sharePlayService.isSessionActive {
            // SharePlay is active - assume multiple participants
            var updatedRoom = currentRoom
            
            // Add a second participant if SharePlay is active but room only has 1
            if updatedRoom.participantIDs.count < 2 {
                // Add a placeholder for SharePlay participant
                let sharePlayParticipantID = UUID()
                updatedRoom.participantIDs.insert(sharePlayParticipantID)
                updatedRoom.participants.append(User(id: sharePlayParticipantID, username: "SharePlay User"))
                currentRoom = updatedRoom
                print("📊 SharePlay active - added SharePlay participant. Total: \(currentRoom.participantIDs.count)")
            }
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

            Button("Start Game") {
                Task {
                    var playerIDs = Array(currentRoom.participantIDs)
                    
                    // For demo/testing: Add AI players if less than 2 players
                    if playerIDs.count < 2 {
                        // Add demo AI players
                        for i in 0..<(2 - playerIDs.count) {
                            playerIDs.append(UUID())
                        }
                    }
                    
                    await viewModel.startGame(roomID: currentRoom.id, players: playerIDs)
                }
            }
            .buttonStyle(.borderedProminent)

            if currentRoom.participantIDs.count < 2 {
                Text("Playing with AI players for demo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(currentRoom.participantIDs.count) players ready")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    private func gameView(_ game: TexasHoldemGame) -> some View {
        VStack(spacing: 20) {
            // Game phase and pot
            VStack(spacing: 8) {
                Text(game.gamePhase.rawValue.capitalized)
                    .font(.headline)

                Text("Pot: $\(game.pot)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

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
                gameControls
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

    private var gameControls: some View {
        HStack(spacing: 12) {
            Button("Fold") {
                Task {
                    await viewModel.fold(playerID: currentUser.id)
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button("Call") {
                Task {
                    await viewModel.call(playerID: currentUser.id)
                }
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button("Raise") {
                Task {
                    await viewModel.raise(playerID: currentUser.id, amount: betAmount)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Next Phase") {
                Task {
                    await viewModel.nextPhase()
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func startSharePlay() async {
        print("🃏 Starting SharePlay for Texas Hold'em room: \(room.name)")
        let activity = LayoverActivity(
            roomID: room.id,
            activityType: .texasHoldem,
            customMetadata: ["roomName": room.name]
        )

        do {
            try await sharePlayService.startActivity(activity)
            sharePlayStarted = true
            print("✅ SharePlay started successfully")
        } catch {
            print("❌ Failed to start SharePlay: \(error)")
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
