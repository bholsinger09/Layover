import SwiftUI

public struct ChessView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel: ChessViewModel
    
    public init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
        self._viewModel = State(initialValue: ChessViewModel(gameService: ChessService()))
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else if let game = viewModel.currentGame {
                gameView(game)
            } else {
                setupView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private var setupView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Chess")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 5)
            
            startGameButton
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var startGameButton: some View {
        #if os(tvOS)
        Button {
            Task {
                await viewModel.startGame(room: room, currentUser: currentUser)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Start Game")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
        }
        .buttonStyle(.card)
        #else
        Button {
            Task {
                await viewModel.startGame(room: room, currentUser: currentUser)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Start Game")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        #endif
    }
    
    private func gameView(_ game: ChessGame) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Chess")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                
                Spacer()
                
                if viewModel.isAIThinking {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                        Text("AI thinking...")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
            }
            
            // Game status
            VStack(spacing: 8) {
                Text(gameStatusText(game))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                
                if game.gameState == .check {
                    Text("Check!")
                        .foregroundColor(.red)
                        .bold()
                        .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                }
                
                if game.gameState == .checkmate, let winnerID = game.winnerID {
                    let winnerColor = game.players.first(where: { $0.userID == winnerID })?.color
                    Text("\(winnerColor == .white ? "White" : "Black") wins!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                        .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                }
            }
            
            // Chess board
            chessBoard(game)
            
            // Captured pieces
            if !game.capturedPieces.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured:")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        ForEach(game.capturedPieces.indices, id: \.self) { index in
                            Text(game.capturedPieces[index].symbol)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
            }
            
            // Controls
            HStack(spacing: 30) {
                Button {
                    Task {
                        await viewModel.resign(playerID: currentUser.id)
                    }
                } label: {
                    Text("Resign")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    Task {
                        print("🔄 New Game button pressed")
                        await viewModel.endGame()
                        print("🏁 Game ended, currentGame is now: \(viewModel.currentGame == nil ? "nil" : "not nil")")
                        // Small delay to ensure UI updates
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await viewModel.startGame(room: room, currentUser: currentUser)
                    }
                } label: {
                    Text("New Game")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.8))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private func chessBoard(_ game: ChessGame) -> some View {
        GeometryReader { geometry in
            let squareSize = min(geometry.size.width, geometry.size.height) / 8
            
            VStack(spacing: 0) {
                // Display board from black's perspective (top row is row 7)
                ForEach((0..<8).reversed(), id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { col in
                            chessSquare(row: row, col: col, game: game, size: squareSize)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func chessSquare(row: Int, col: Int, game: ChessGame, size: CGFloat) -> some View {
        let isLight = (row + col) % 2 == 0
        let isSelected = viewModel.selectedSquare?.row == row && viewModel.selectedSquare?.col == col
        
        return Button {
            Task {
                await viewModel.selectSquare(row: row, col: col, currentUserID: currentUser.id)
            }
        } label: {
            ZStack {
                Rectangle()
                    .fill(isSelected ? Color.yellow : (isLight ? Color.white : Color.gray.opacity(0.6)))
                
                if let piece = game.board[row][col] {
                    if piece.color == .white {
                        // White pieces with red background and white fill
                        Text(piece.symbol)
                            .font(.system(size: size * 0.6))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: size * 0.7, height: size * 0.7)
                            )
                    } else {
                        // Black pieces
                        Text(piece.symbol)
                            .font(.system(size: size * 0.6))
                            .foregroundColor(.black)
                    }
                }
            }
            .frame(width: size, height: size)
            .border(Color.black, width: 0.5)
        }
        .buttonStyle(.plain)
    }
    
    private func gameStatusText(_ game: ChessGame) -> String {
        switch game.gameState {
        case .active, .check:
            return "Turn: \(game.currentTurn == .white ? "White" : "Black")"
        case .checkmate:
            return "Checkmate"
        case .stalemate:
            return "Stalemate"
        case .draw:
            return "Draw"
        case .resigned:
            return "Game Over - Player Resigned"
        }
    }
}

#Preview {
    ChessView(
        room: Room(name: "Chess Game", hostID: UUID(), activityType: .chess),
        currentUser: User(username: "Player 1")
    )
}
