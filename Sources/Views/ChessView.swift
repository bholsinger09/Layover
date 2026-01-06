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
            } else if let game = viewModel.currentGame {
                gameView(game)
            } else {
                setupView
            }
        }
        .padding()
        .task {
            viewModel.setupSharePlayCallbacks()
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
    
    private var setupView: some View {
        VStack(spacing: 20) {
            Text("Chess")
                .font(.largeTitle)
                .bold()
            
            Button("Start Game") {
                Task {
                    await viewModel.startGame(room: room, currentUser: currentUser)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func gameView(_ game: ChessGame) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Chess")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                if viewModel.isAIThinking {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("AI thinking...")
                            .font(.caption)
                    }
                }
            }
            
            // Game status
            VStack(spacing: 8) {
                Text(gameStatusText(game))
                    .font(.headline)
                
                if game.gameState == .check {
                    Text("Check!")
                        .foregroundColor(.red)
                        .bold()
                }
                
                if game.gameState == .checkmate, let winnerID = game.winnerID {
                    let winnerColor = game.players.first(where: { $0.userID == winnerID })?.color
                    Text("\(winnerColor == .white ? "White" : "Black") wins!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
            }
            
            // Chess board
            chessBoard(game)
            
            // Captured pieces
            if !game.capturedPieces.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Captured:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(game.capturedPieces.indices, id: \.self) { index in
                            Text(game.capturedPieces[index].symbol)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            
            // Controls
            HStack(spacing: 16) {
                if !viewModel.sharePlayService.isActive {
                    Button("Start SharePlay") {
                        Task {
                            await viewModel.startSharePlay(room: room)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Resign") {
                    Task {
                        await viewModel.resign(playerID: currentUser.id)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button("New Game") {
                    Task {
                        await viewModel.endGame()
                        await viewModel.startGame(room: room, currentUser: currentUser)
                    }
                }
                .buttonStyle(.bordered)
            }
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
        
        return ZStack {
            Rectangle()
                .fill(isSelected ? Color.yellow : (isLight ? Color.white : Color.gray.opacity(0.6)))
            
            if let piece = game.board[row][col] {
                Text(piece.symbol)
                    .font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size)
        .border(Color.black, width: 0.5)
        .onTapGesture {
            Task {
                await viewModel.selectSquare(row: row, col: col, currentUserID: currentUser.id)
            }
        }
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
