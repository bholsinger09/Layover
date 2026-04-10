import SwiftUI

public struct ConnectFourView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel = ConnectFourViewModel()
    @State private var selectedColor: ConnectFourGame.PieceColor = .yellow
    @State private var selectedDifficulty: ConnectFourAIService.Difficulty = .medium
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
            // Blue gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.1, blue: 0.3),
                    Color(red: 0.0, green: 0.2, blue: 0.5),
                    Color(red: 0.1, green: 0.3, blue: 0.6)
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
    }
    
    // MARK: - Setup View
    
    @ViewBuilder
    private var setupView: some View {
        VStack(spacing: 30) {
            // Title
            VStack(spacing: 8) {
                Text("🔴 Connect Four 🟡")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Get 4 in a Row to Win!")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
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
                            color: .yellow,
                            isSelected: selectedColor == .yellow,
                            action: { selectedColor = .yellow }
                        )
                        
                        ColorButton(
                            color: .red,
                            isSelected: selectedColor == .red,
                            action: { selectedColor = .red }
                        )
                    }
                }
                
                // Difficulty Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Difficulty")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 10) {
                        ForEach(ConnectFourAIService.Difficulty.allCases, id: \.self) { difficulty in
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
            .background(Color.white.opacity(0.1))
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
                        colors: [.blue, .cyan],
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
    private func gameView(_ game: ConnectFourGame) -> some View {
        VStack(spacing: 20) {
            // Game Status Header
            gameStatusHeader(game)
            
            // Connect Four Board
            connectFourBoard(game)
                .aspectRatio(7.0/6.0, contentMode: .fit)
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
    private func gameStatusHeader(_ game: ConnectFourGame) -> some View {
        VStack(spacing: 8) {
            if game.gameState == .won {
                if let winnerID = game.winnerID, let winner = game.players.first(where: { $0.userID == winnerID }) {
                    Text("\(winner.color == .yellow ? "Yellow" : "Red") Wins!")
                        .font(.title.bold())
                        .foregroundStyle(winner.color == .yellow ? .yellow : .red)
                } else {
                    Text("Game Over")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
            } else if game.gameState == .draw {
                Text("It's a Draw!")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            } else if viewModel.isAIThinking {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("AI is thinking...")
                        .font(.headline)
                }
                .foregroundStyle(.white)
            } else {
                Text("\(game.currentTurn == .yellow ? "Yellow" : "Red")'s Turn")
                    .font(.title2.bold())
                    .foregroundStyle(game.currentTurn == .yellow ? .yellow : .red)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func connectFourBoard(_ game: ConnectFourGame) -> some View {
        GeometryReader { geometry in
            let boardWidth = min(geometry.size.width, geometry.size.height * 7.0 / 6.0)
            let boardHeight = boardWidth * 6.0 / 7.0
            let cellSize = boardWidth / 7.0
            
            ZStack {
                // Blue board frame
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: boardWidth, height: boardHeight)
                    .shadow(radius: 10)
                
                // Cells and pieces
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { col in
                                ZStack {
                                    // Cell hole
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                                    
                                    // Piece
                                    if let piece = game.board[row][col] {
                                        let isWinningPiece = game.winningLine?.contains(where: { $0.row == row && $0.col == col }) ?? false
                                        
                                        Circle()
                                            .fill(
                                                piece.color == .yellow ?
                                                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) :
                                                    LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                            )
                                            .frame(width: cellSize * 0.75, height: cellSize * 0.75)
                                            .shadow(radius: 3)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(isWinningPiece ? Color.white : Color.clear, lineWidth: 3)
                                            )
                                    }
                                }
                                .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                
                // Column tap areas (above the board)
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let isValid = viewModel.validColumns.contains(col)
                        let isDropping = viewModel.droppingColumn == col
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: cellSize, height: boardHeight)
                            .overlay(
                                VStack {
                                    if isValid && !isDropping && game.gameState == .active {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .font(.system(size: cellSize * 0.4))
                                            .foregroundStyle(game.currentTurn == .yellow ? .yellow : .red)
                                            .opacity(0.7)
                                    }
                                    Spacer()
                                }
                            )
                            .onTapGesture {
                                if isValid && !viewModel.isAIThinking {
                                    Task {
                                        await viewModel.dropPiece(column: col)
                                    }
                                }
                            }
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
    
    @ViewBuilder
    private func moveHistoryView(_ game: ConnectFourGame) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Move History")
                .font(.headline)
                .foregroundStyle(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(game.moveHistory.suffix(15).enumerated()), id: \.element.id) { index, move in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(move.color == .yellow ? Color.yellow : Color.red)
                                .frame(width: 12, height: 12)
                            Text(move.notation)
                                .font(.caption.monospaced())
                        }
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
    let color: ConnectFourGame.PieceColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(
                        color == .yellow ?
                            LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)
                    .shadow(radius: 2)
                
                Text(color == .yellow ? "Yellow" : "Red")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct DifficultyButton: View {
    let difficulty: ConnectFourAIService.Difficulty
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
            .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
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
            .background(Color.white.opacity(configuration.isPressed ? 0.2 : 0.1))
            .foregroundStyle(.white)
            .cornerRadius(10)
    }
}
