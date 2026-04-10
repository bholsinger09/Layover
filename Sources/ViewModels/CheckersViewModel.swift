import Foundation
import Observation

/// ViewModel for Checkers game
@MainActor
@Observable
public final class CheckersViewModel: LayoverViewModel {
    private let gameService: CheckersServiceProtocol
    private let aiService: CheckersAIService
    
    public private(set) var currentGame: CheckersGame?
    public private(set) var isLoading = false
    public var errorMessage: String?
    
    // AI opponent tracking
    public private(set) var aiPlayerID: UUID?
    public private(set) var isAIThinking = false
    
    // Player color tracking
    public var localPlayerColor: CheckersGame.PieceColor?
    
    // Selected square for moves
    public private(set) var selectedSquare: BoardPosition?
    public private(set) var validMoves: [BoardPosition] = []
    
    public var board: [[CheckersPiece?]] {
        currentGame?.board ?? CheckersGame.createInitialBoard()
    }
    
    public var currentTurn: CheckersGame.PieceColor {
        currentGame?.currentTurn ?? .red
    }
    
    public var gameState: CheckersGame.GameState {
        currentGame?.gameState ?? .active
    }
    
    public nonisolated init(
        gameService: CheckersServiceProtocol = CheckersService(),
        aiService: CheckersAIService = CheckersAIService()
    ) {
        self.gameService = gameService
        self.aiService = aiService
    }
    
    /// Start a new game against AI
    public func startAIGame(playerColor: CheckersGame.PieceColor, difficulty: CheckersAIService.Difficulty) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let aiID = UUID()
            aiPlayerID = aiID
            localPlayerColor = playerColor
            
            let players = [
                CheckersPlayer(userID: UUID(), color: playerColor),
                CheckersPlayer(userID: aiID, color: playerColor == .red ? .black : .red)
            ]
            
            currentGame = try await gameService.createGame(roomID: UUID(), players: players)
            isLoading = false
            
            // If AI goes first, make its move
            if currentGame?.currentTurn != playerColor {
                await makeAIMove()
            }
        } catch {
            errorMessage = "Failed to start game: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Select a square for moving
    public func selectSquare(row: Int, col: Int) async {
        guard let game = currentGame, game.gameState == .active else { return }
        guard game.currentTurn == localPlayerColor else { return }
        
        // If there's a forced capture, only allow selecting that piece
        if let mustCapture = game.mustContinueCapture {
            if mustCapture.row == row && mustCapture.col == col {
                selectedSquare = BoardPosition(row: row, col: col)
                validMoves = gameService.getValidMoves(game: game, row: row, col: col)
                return
            } else {
                errorMessage = "You must continue capturing with your piece"
                return
            }
        }
        
        // Check if clicking on a piece of current player's color
        if let piece = game.board[row][col], piece.color == game.currentTurn {
            selectedSquare = BoardPosition(row: row, col: col)
            validMoves = gameService.getValidMoves(game: game, row: row, col: col)
        }
        // Check if clicking on a valid move destination
        else if let selected = selectedSquare {
            if validMoves.contains(where: { $0.row == row && $0.col == col }) {
                await makeMove(fromRow: selected.row, fromCol: selected.col, toRow: row, toCol: col)
            }
            selectedSquare = nil
            validMoves = []
        }
    }
    
    /// Make a move
    private func makeMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) async {
        guard let game = currentGame else { return }
        
        do {
            currentGame = try await gameService.makeMove(
                game: game,
                fromRow: fromRow,
                fromCol: fromCol,
                toRow: toRow,
                toCol: toCol
            )
            
            selectedSquare = nil
            validMoves = []
            
            // If there's a forced multi-jump, reselect the piece
            if let mustCapture = currentGame?.mustContinueCapture {
                selectedSquare = mustCapture
                validMoves = gameService.getValidMoves(game: currentGame!, row: mustCapture.row, col: mustCapture.col)
                return
            }
            
            // Check if it's now AI's turn
            if currentGame?.currentTurn != localPlayerColor, currentGame?.gameState == .active {
                await makeAIMove()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Make AI move
    private func makeAIMove() async {
        guard let game = currentGame else { return }
        guard game.currentTurn != localPlayerColor else { return }
        
        isAIThinking = true
        
        if let move = await aiService.getMove(for: game) {
            do {
                currentGame = try await gameService.makeMove(
                    game: game,
                    fromRow: move.fromRow,
                    fromCol: move.fromCol,
                    toRow: move.toRow,
                    toCol: move.toCol
                )
                
                // AI might have multi-jump
                while let mustCapture = currentGame?.mustContinueCapture, currentGame?.gameState == .active {
                    guard let jumpMove = await aiService.getMove(for: currentGame!) else { break }
                    
                    currentGame = try await gameService.makeMove(
                        game: currentGame!,
                        fromRow: jumpMove.fromRow,
                        fromCol: jumpMove.fromCol,
                        toRow: jumpMove.toRow,
                        toCol: jumpMove.toCol
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isAIThinking = false
    }
    
    /// Reset the game
    public func resetGame() {
        currentGame = nil
        selectedSquare = nil
        validMoves = []
        localPlayerColor = nil
        aiPlayerID = nil
        errorMessage = nil
    }
}
