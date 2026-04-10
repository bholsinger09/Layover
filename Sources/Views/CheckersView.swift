import SwiftUI

public struct CheckersView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel = CheckersViewModel()
    @State private var selectedColor: CheckersGame.PieceColor = .red
    @State private var selectedDifficulty: CheckersAIService.Difficulty = .medium
    @State private var showSignInAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // Check if user is in guest mode
    private var isGuestMode: Bool {
        currentUser.email == nil && currentUser.username == "Guest"
    }
    
    public init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
    }
    
    public var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.15, green: 0.05, blue: 0.05),
                    Color(red: 0.1, green: 0.05, blue: 0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
        .alert("Guest Mode", isPresented: $showSignInAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Multiplayer requires signing in. Single-player is available in guest mode.")
        }
    }
    
    // MARK: - Setup View
    
    @ViewBuilder
    private var setupView: some View {
        VStack(spacing: 30) {
            // Title
            VStack(spacing: 8) {
                Text("♔ Checkers ♚")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Classic Strategy Game")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.bottom, 20)
            
            // Game Mode Selection
            VStack(alignment: .leading, spacing: 20) {
                // Color Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Color")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 15) {
                        ColorButton(
                            color: .red,
                            isSelected: selectedColor == .red,
                            action: { selectedColor = .red }
                        )
                        
                        ColorButton(
                            color: .black,
                            isSelected: selectedColor == .black,
                            action: { selectedColor = .black }
                        )
                    }
                }
                
                // Difficulty Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Difficulty")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(CheckersAIService.Difficulty.allCases, id: \.self) { difficulty in
                            DifficultyButton(
                                difficulty: difficulty,
                                isSelected: selectedDifficulty == difficulty,
                                action: { selectedDifficulty = difficulty }
                            )
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
            
            // Start Button
            Button(action: {
                Task {
                    await viewModel.startAIGame(playerColor: selectedColor, difficulty: selectedDifficulty)
                }
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Game")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(30)
        .frame(maxWidth: 500)
    }
    
    // MARK: - Game View
    
    @ViewBuilder
    private func gameView(_ game: CheckersGame) -> some View {
        VStack(spacing: 20) {
            // Game Status Header
            gameStatusHeader(game)
            
            // Checkers Board
            checkersBoard(game)
                .aspectRatio(1.0, contentMode: .fit)
                .padding()
            
            // Move History
            if !game.moveHistory.isEmpty {
                moveHistoryView(game)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("New Game") {
                    viewModel.resetGame()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Exit") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    private func gameStatusHeader(_ game: CheckersGame) -> some View {
        VStack(spacing: 8) {
            if game.gameState == .won {
                if let winnerID = game.winnerID, let winner = game.players.first(where: { $0.userID == winnerID }) {
                    Text("\(winner.color == .red ? "Red" : "Black") Wins!")
                        .font(.title.bold())
                        .foregroundStyle(winner.color == .red ? .red : .white)
                } else {
                    Text("Game Over")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
            } else if viewModel.isAIThinking {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("AI is thinking...")
                        .font(.headline)
                }
                .foregroundStyle(.white)
            } else {
                Text("\(game.currentTurn == .red ? "Red" : "Black")'s Turn")
                    .font(.title2.bold())
                    .foregroundStyle(game.currentTurn == .red ? .red : .white)
                
                if game.mustContinueCapture != nil {
                    Text("Continue capturing!")
                        .font(.subheadline)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func checkersBoard(_ game: CheckersGame) -> some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let squareSize = boardSize / 8
            
            ZStack {
                // Board squares
                ForEach(0..<8, id: \.self) { row in
                    ForEach(0..<8, id: \.self) { col in
                        let isDark = (row + col) % 2 == 1
                        let isSelected = viewModel.selectedSquare?.row == row && viewModel.selectedSquare?.col == col
                        let isValidMove = viewModel.validMoves.contains(where: { $0.row == row && $0.col == col })
                        
                        Rectangle()
                            .fill(isDark ? Color(red: 0.4, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.8, blue: 0.7))
                            .frame(width: squareSize, height: squareSize)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                            )
                            .overlay(
                                Circle()
                                    .fill(Color.green.opacity(0.5))
                                    .padding(squareSize * 0.25)
                                    .opacity(isValidMove ? 1 : 0)
                            )
                            .position(
                                x: CGFloat(col) * squareSize + squareSize / 2,
                                y: CGFloat(row) * squareSize + squareSize / 2
                            )
                            .onTapGesture {
                                Task {
                                    await viewModel.selectSquare(row: row, col: col)
                                }
                            }
                    }
                }
                
                // Pieces
                ForEach(0..<8, id: \.self) { row in
                    ForEach(0..<8, id: \.self) { col in
                        if let piece = game.board[row][col] {
                            pieceView(piece: piece, size: squareSize)
                                .position(
                                    x: CGFloat(col) * squareSize + squareSize / 2,
                                    y: CGFloat(row) * squareSize + squareSize / 2
                                )
                        }
                    }
                }
            }
            .frame(width: boardSize, height: boardSize)
        }
    }
    
    @ViewBuilder
    private func pieceView(piece: CheckersPiece, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(piece.color == .red ? 
                    LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .shadow(radius: 3)
            
            if piece.isKing {
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(.yellow)
            }
        }
    }
    
    @ViewBuilder
    private func moveHistoryView(_ game: CheckersGame) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Move History")
                .font(.headline)
                .foregroundStyle(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(game.moveHistory.suffix(10).enumerated()), id: \.element.id) { index, move in
                        Text(move.notation)
                            .font(.caption.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

private struct ColorButton: View {
    let color: CheckersGame.PieceColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(color == .red ? 
                        LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)
                
                Text(color == .red ? "Red" : "Black")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct DifficultyButton: View {
    let difficulty: CheckersAIService.Difficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue.capitalized)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(difficultyDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private var difficultyDescription: String {
        switch difficulty {
        case .easy: return "Perfect for beginners"
        case .medium: return "Balanced challenge"
        case .hard: return "Strategic play"
        }
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minWidth: 120)
            .background(Color.white.opacity(configuration.isPressed ? 0.15 : 0.1))
            .foregroundStyle(.white)
            .cornerRadius(10)
    }
}
