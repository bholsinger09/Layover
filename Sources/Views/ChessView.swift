import SwiftUI

public struct ChessView: View {
    let room: Room
    let currentUser: User
    
    @State var viewModel: ChessViewModel
    @State var showingColorSelection = false
    @State var selectedColor: ChessGame.PieceColor = .white
    @State var gameMode: GameMode = .sharePlay
    @State var selectedDifficulty: AIDifficulty = .medium
    @State var showSignInAlert = false
    @Environment(\.dismiss) var dismiss
    
    var isGuestMode: Bool {
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
    
    public var body: some View {
        ZStack {
            ChessUIStyle.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: ChessUILayout.componentSpacing) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .tint(.white)
                        .foregroundStyle(.white)
                } else if let game = viewModel.currentGame {
                    gameViewContent(game)
                } else {
                    setupViewContent
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
            if isGuestMode {
                gameMode = .vsComputer
            }
        }
    }

    private var setupViewContent: some View {
        ScrollView {
            VStack(spacing: ChessUILayout.sectionVerticalSpacing) {
                Spacer().frame(height: 20)
                
                setupViewTitle
                
                VStack(spacing: ChessUILayout.sectionSpacing) {
                    colorSelectionSection
                    gameModeSection
                    
                    if gameMode == .vsComputer {
                        difficultySelectionView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    startGameButton
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: ChessUILayout.buttonIconSize) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundStyle(.white.opacity(ChessUIStyle.highlightOpacity))
                        .padding(.vertical, 14)
                        .padding(.horizontal, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(ChessUIStyle.tertiaryOpacity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(ChessUIStyle.tertiaryOpacity), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal)
        }
    }

    private func gameViewContent(_ game: ChessGame) -> some View {
        VStack(spacing: ChessUILayout.componentSpacing) {
            gameHeader
            gameStatusDisplay(game)
            chessBoard(game)
            
            if !game.capturedPieces.isEmpty {
                capturedPiecesDisplay(game)
            }
            
            gameControlsArea
        }
        .padding()
    }

    private func chessBoard(_ game: ChessGame) -> some View {
        VStack(spacing: ChessUILayout.boardSquareSpacing) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: ChessUILayout.boardSquareSpacing) {
                    ForEach(0..<8, id: \.self) { col in
                        chessSquare(row: row, col: col, game: game, size: 40)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }

    private func chessSquare(row: Int, col: Int, game: ChessGame, size: CGFloat) -> some View {
        let isWhiteSquare = (row + col) % 2 == 0
        let piece = game.board[row][col]
        
        return Button {
            // Handle square tap
        } label: {
            ZStack {
                Rectangle()
                    .fill(isWhiteSquare ? Color.white.opacity(0.9) : Color(red: 0.6, green: 0.4, blue: 0.2))
                
                if let piece = piece {
                    Text(piece.symbol)
                        .font(.system(size: size * 0.6, design: .monospaced))
                        .foregroundColor(piece.color == .white ? .white : .black)
                }
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    func gameStatusText(_ game: ChessGame) -> String {
        switch game.gameState {
        case .active:
            return "Game in progress"
        case .check:
            return "Check!"
        case .checkmate:
            if let winnerID = game.winnerID {
                let winner = game.players.first(where: { $0.userID == winnerID })
                return "Checkmate! \(winner?.color == .white ? "White" : "Black") wins"
            }
            return "Checkmate!"
        case .stalemate:
            return "Stalemate! Game is drawn"
        case .draw:
            return "Draw!"
        case .resigned:
            return "Player resigned"
        }
    }
}
