import SwiftUI

public struct ChessView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel: ChessViewModel
    @State private var showingColorSelection = false
    @State private var selectedColor: ChessGame.PieceColor = .white
    @State private var gameMode: GameMode = .sharePlay
    @State private var selectedDifficulty: AIDifficulty = .medium
    @State private var showSignInAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // Check if user is in guest mode
    private var isGuestMode: Bool {
        currentUser.email == nil && currentUser.username == "Guest"
    }
    
    enum GameMode {
        case sharePlay
        case vsComputer
    }
    
    enum AIDifficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"
        
        var description: String {
            switch self {
            case .easy: return "Perfect for beginners"
            case .medium: return "Balanced challenge"
            case .hard: return "Strategic play"
            case .expert: return "Master level"
            }
        }
    }
    
    public init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
        self._viewModel = State(initialValue: ChessViewModel(gameService: ChessService()))
    }
    
    /// Get SF Symbol name for chess piece
    func getPieceSFSymbol(_ piece: ChessPiece) -> String {
        switch piece.type {
        case .pawn:
            return "circle.fill"
        case .knight:
            return "star.fill"
        case .bishop:
            return "triangle.fill"
        case .rook:
            return "square.fill"
        case .queen:
            return "diamond.fill"
        case .king:
            return "crown.fill"
        }
    }
    
    public var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
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
        .alert("Account Required", isPresented: $showSignInAlert) {
            Button("OK") {
                showSignInAlert = false
            }
        } message: {
            Text("SharePlay features require an account. Please sign in to play with friends in real-time. Single player mode is available without an account.")
        }
        .onAppear {
            viewModel.setupSharePlayCallbacks()
            // Default to single-player mode for guest users
            if isGuestMode {
                gameMode = .vsComputer
            }
        }
    }
    
    private var setupView: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Top spacing
                Spacer()
                    .frame(height: 20)
                
                Text("Chess")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 5)
                
                VStack(spacing: 30) {
                    Text("Choose Your Pieces")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                
                // Color selection
                HStack(spacing: 30) {
                    Button {
                        selectedColor = .white
                    } label: {
                        VStack(spacing: 12) {
                            ZStack {
                                // Outer glow for selected state
                                if selectedColor == .white {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 8)
                                }
                                
                                // Main circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                if selectedColor == .white {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.green)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 44, height: 44)
                                        )
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text("White")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text("Goes First")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedColor == .white ? Color.white.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedColor == .white ? Color.white : Color.white.opacity(0.25), lineWidth: selectedColor == .white ? 3 : 1)
                                )
                        )
                        .shadow(color: selectedColor == .white ? .white.opacity(0.3) : .clear, radius: 12, x: 0, y: 0)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        selectedColor = .black
                    } label: {
                        VStack(spacing: 12) {
                            ZStack {
                                // Outer glow for selected state
                                if selectedColor == .black {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 8)
                                }
                                
                                // Main circle
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.black, Color.black.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                                
                                if selectedColor == .black {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.green)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 44, height: 44)
                                        )
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text("Black")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text("Goes Second")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedColor == .black ? Color.white.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedColor == .black ? Color.white : Color.white.opacity(0.25), lineWidth: selectedColor == .black ? 3 : 1)
                                )
                        )
                        .shadow(color: selectedColor == .black ? .white.opacity(0.3) : .clear, radius: 12, x: 0, y: 0)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical)
                
                // Game Mode Selection
                Text("Choose Game Mode")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.top, 10)
                
                VStack(spacing: 16) {
                    // SharePlay Mode
                    Button {
                        if isGuestMode {
                            showSignInAlert = true
                        } else {
                            gameMode = .sharePlay
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "shareplay")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Play with SharePlay")
                                    .font(.headline)
                                if isGuestMode {
                                    Text("Account required")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("Multiplayer with friends")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                            }
                            Spacer()
                            if gameMode == .sharePlay && !isGuestMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            } else if isGuestMode {
                                Image(systemName: "lock.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange.opacity(0.8))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(gameMode == .sharePlay && !isGuestMode ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(gameMode == .sharePlay && !isGuestMode ? Color.blue : Color.white.opacity(0.3), lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Computer Mode
                    Button {
                        gameMode = .vsComputer
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cpu")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Play vs Computer")
                                    .font(.headline)
                                Text("Challenge the AI")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            if gameMode == .vsComputer {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(gameMode == .vsComputer ? Color.purple.opacity(0.3) : Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(gameMode == .vsComputer ? Color.purple : Color.white.opacity(0.3), lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Difficulty Selection (shown only when vs Computer is selected)
                if gameMode == .vsComputer {
                    VStack(spacing: 12) {
                        Text("Select Difficulty")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.top, 8)
                        
                        VStack(spacing: 8) {
                            ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                                Button {
                                    selectedDifficulty = difficulty
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(difficulty.rawValue)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            Text(difficulty.description)
                                                .font(.caption)
                                                .opacity(0.7)
                                        }
                                        Spacer()
                                        if selectedDifficulty == difficulty {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedDifficulty == difficulty ? Color.purple.opacity(0.2) : Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedDifficulty == difficulty ? Color.purple.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                startGameButton()
                
                // Exit button
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                }
            
            // Bottom spacing for safe area
            Spacer()
                .frame(height: 40)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func startGameButton() -> some View {
        #if os(tvOS)
        return Button {
            Task {
                // Start game with selected color
                await viewModel.startGame(room: room, currentUser: currentUser, playerColor: selectedColor, includeAI: gameMode == .vsComputer)
                // Then connect to SharePlay if in SharePlay mode (skip eligibility check)
                if gameMode == .sharePlay {
                    await viewModel.startSharePlay(room: room, currentUser: currentUser, playerColor: selectedColor)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: gameMode == .sharePlay ? "shareplay" : "cpu")
                    .font(.title2)
                Text(gameMode == .sharePlay ? "Connect with SharePlay" : "Start Game")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
        }
        .buttonStyle(.card)
        #else
        return Button {
            Task {
                // Start game with selected color
                await viewModel.startGame(room: room, currentUser: currentUser, playerColor: selectedColor)
                // Then connect to SharePlay if in SharePlay mode
                if gameMode == .sharePlay {
                    await viewModel.startSharePlay(room: room, currentUser: currentUser, playerColor: selectedColor)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: gameMode == .sharePlay ? "shareplay" : "cpu")
                    .font(.title2)
                Text(gameMode == .sharePlay ? "Connect with SharePlay" : "Start Game vs \(selectedDifficulty.rawValue)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gameMode == .sharePlay ? 
                                [Color.blue.opacity(0.95), Color.blue.opacity(0.85)] :
                                [Color.purple.opacity(0.95), Color.purple.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
    
    @ViewBuilder
    private func gameView(_ game: ChessGame) -> some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Chess")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                
                // Hidden view to force refresh on SharePlay updates
                Text("")
                    .hidden()
                    .id(viewModel.sharePlayStateVersion)
                
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
                            let piece = game.capturedPieces[index]
                            ZStack {
                                Circle()
                                    .fill(piece.color == .white ? Color.red.opacity(0.9) : Color.gray.opacity(0.7))
                                    .frame(width: 24, height: 24)
                                
                                VStack(spacing: 0) {
                                    Image(systemName: getPieceSFSymbol(piece))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(piece.color == .white ? .white : .black)
                                    
                                    if piece.type != .pawn {
                                        Text(piece.textSymbol)
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(piece.color == .white ? .white : .black)
                                    }
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
            }
            
            // Controls
            HStack(spacing: 20) {
                Button {
                    Task {
                        await viewModel.resign(playerID: currentUser.id)
                    }
                } label: {
                    Text("Resign")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .red.opacity(0.5), radius: 8, x: 0, y: 4)
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
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                
                Button {
                    Task {
                        await viewModel.endGame()
                    }
                } label: {
                    Text("Exit")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    @ViewBuilder
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
    
    @ViewBuilder
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
                    // Use SF Symbols for reliable rendering
                    ZStack {
                        Circle()
                            .fill(piece.color == .white ? Color.red : Color.gray.opacity(0.7))
                            .frame(width: size * 0.75, height: size * 0.75)
                        
                        VStack(spacing: 1) {
                            Image(systemName: getPieceSFSymbol(piece))
                                .font(.system(size: size * 0.4, weight: .bold))
                                .foregroundColor(piece.color == .white ? .white : .black)
                            
                            if piece.type != .pawn {
                                Text(piece.textSymbol)
                                    .font(.system(size: size * 0.18, weight: .bold))
                                    .foregroundColor(piece.color == .white ? .white : .black)
                            }
                        }
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
