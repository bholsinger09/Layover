import SwiftUI

/// View for Texas Hold'em game rooms
struct TexasHoldemView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel = TexasHoldemViewModel(gameService: TexasHoldemService())
    @State private var betAmount = 10
    @State private var sharePlayService = SharePlayService()
    @State private var sharePlayStarted = false
    
    var body: some View {
        VStack(spacing: 0) {
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
                    let playerIDs = Array(room.participantIDs)
                    await viewModel.startGame(roomID: room.id, players: playerIDs)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(room.participantIDs.count < 2)
            
            if room.participantIDs.count < 2 {
                Text("Need at least 2 players to start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
