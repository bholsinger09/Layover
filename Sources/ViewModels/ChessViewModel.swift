import Foundation
import Observation

/// ViewModel for Chess game rooms
@MainActor
@Observable
public final class ChessViewModel: LayoverViewModel {
    private let gameService: ChessServiceProtocol
    public let sharePlayService: ChessSharePlayService
    private let roomService: RoomServiceProtocol
    private let aiService = ChessAIService(difficulty: .experienced)
    
    public private(set) var currentGame: ChessGame?
    public private(set) var isLoading = false
    public var errorMessage: String?
    
    // AI opponent tracking
    public private(set) var aiPlayerID: UUID?
    public private(set) var isAIThinking = false
    
    // Selected square for moves
    public private(set) var selectedSquare: (row: Int, col: Int)?
    
    // Trigger for SharePlay state changes
    public private(set) var sharePlayStateVersion: Int = 0
    
    public var board: [[ChessPiece?]] {
        currentGame?.board ?? ChessGame.createInitialBoard()
    }
    
    public var currentTurn: ChessGame.PieceColor {
        currentGame?.currentTurn ?? .white
    }
    
    public var gameState: ChessGame.GameState {
        currentGame?.gameState ?? .active
    }
    
    public nonisolated init(gameService: ChessServiceProtocol, roomService: RoomServiceProtocol? = nil) {
        self.gameService = gameService
        self.sharePlayService = ChessSharePlayService()
        self.roomService = roomService ?? RoomService()
    }
    
    public func setupSharePlayCallbacks() {
        print("🔧 Setting up Chess SharePlay callbacks...")
        
        sharePlayService.onSessionStarted = { [weak self] in
            Task { @MainActor in
                print("🎊 Chess SharePlay session started")
                self?.sharePlayStateVersion += 1
            }
        }
        
        sharePlayService.onGameStateUpdate = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("📨 Received game state update")
                await self.applyGameState(state)
            }
        }
        
        sharePlayService.onPlayerMove = { [weak self] move in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🎯 Received player move")
                await self.handlePlayerMove(move)
            }
        }
        
        sharePlayService.onPlayerResign = { [weak self] playerID in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🏳️ Player resigned: \(playerID)")
                try? await self.gameService.resign(playerID: playerID)
                self.currentGame = self.gameService.currentGame
            }
        }
    }
    
    public func startGame(room: Room, currentUser: User, includeAI: Bool = true) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // User is always white, AI is always black
            aiPlayerID = UUID()
            let players = [currentUser.id, aiPlayerID!]
            
            let game = try await gameService.startGame(roomID: room.id, players: players)
            currentGame = game
            
            print("✅ Chess game started")
            print("   Game ID: \(game.id)")
            print("   Players: \(players)")
            print("   User (White): \(currentUser.id)")
            print("   AI (Black): \(aiPlayerID!)")
            
            // If SharePlay is active, broadcast game state
            if sharePlayService.isActive {
                await broadcastGameState()
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to start chess game: \(error)")
        }
        
        isLoading = false
    }
    
    public func selectSquare(row: Int, col: Int, currentUserID: UUID) async {
        guard let game = currentGame else { return }
        
        // Check if it's the current user's turn
        guard let currentPlayer = game.players.first(where: { $0.userID == currentUserID }) else {
            return
        }
        
        guard currentPlayer.color == game.currentTurn else {
            errorMessage = "Not your turn"
            return
        }
        
        if let selected = selectedSquare {
            // Attempting to move
            do {
                _ = try await gameService.makeMove(
                    fromRow: selected.row,
                    fromCol: selected.col,
                    toRow: row,
                    toCol: col
                )
                
                currentGame = gameService.currentGame
                selectedSquare = nil
                
                // Broadcast move via SharePlay
                if sharePlayService.isActive {
                    let move = ChessMessage.Move(
                        playerID: currentUserID,
                        fromRow: selected.row,
                        fromCol: selected.col,
                        toRow: row,
                        toCol: col
                    )
                    await sharePlayService.sendMessage(.playerMove(move))
                }
                
                // Check for AI turn - use updated currentGame
                if let aiID = aiPlayerID, let updatedGame = currentGame {
                    if updatedGame.currentTurn == .black {
                        await makeAIMove(aiID: aiID)
                    }
                }
                
            } catch {
                errorMessage = error.localizedDescription
                selectedSquare = nil
            }
        } else {
            // Selecting a piece
            if let piece = game.board[row][col], piece.color == currentPlayer.color {
                selectedSquare = (row, col)
            }
        }
    }
    
    private func makeAIMove(aiID: UUID) async {
        guard let game = currentGame else { return }
        guard let aiPlayer = game.players.first(where: { $0.userID == aiID }) else { return }
        
        isAIThinking = true
        
        // Small delay for visual feedback
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        if let move = await aiService.makeAIMove(game: game, aiColor: aiPlayer.color) {
            do {
                _ = try await gameService.makeMove(
                    fromRow: move.fromRow,
                    fromCol: move.fromCol,
                    toRow: move.toRow,
                    toCol: move.toCol
                )
                currentGame = gameService.currentGame
                
                // Broadcast AI move via SharePlay
                if sharePlayService.isActive {
                    let moveMsg = ChessMessage.Move(
                        playerID: aiID,
                        fromRow: move.fromRow,
                        fromCol: move.fromCol,
                        toRow: move.toRow,
                        toCol: move.toCol
                    )
                    await sharePlayService.sendMessage(.playerMove(moveMsg))
                }
            } catch {
                print("❌ AI move failed: \(error)")
            }
        }
        
        isAIThinking = false
    }
    
    public func resign(playerID: UUID) async {
        do {
            try await gameService.resign(playerID: playerID)
            currentGame = gameService.currentGame
            
            if sharePlayService.isActive {
                await sharePlayService.sendMessage(.playerResign(playerID: playerID))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func startSharePlay(room: Room) async {
        guard let game = currentGame else {
            errorMessage = "No active game to share"
            return
        }
        
        do {
            try await sharePlayService.startSharePlay(
                roomID: room.id,
                gameID: game.id,
                roomName: room.name
            )
            
            await broadcastGameState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func broadcastGameState() async {
        guard let game = currentGame else { return }
        
        let state = ChessGameState(
            gameID: game.id,
            board: game.board.map { row in
                row.map { piece in
                    piece.map { ChessPieceData(type: $0.type.rawValue, color: $0.color.rawValue, hasMoved: $0.hasMoved) }
                }
            },
            currentTurn: game.currentTurn.rawValue,
            gameState: game.gameState.rawValue,
            winnerID: game.winnerID,
            capturedPieces: game.capturedPieces.map { ChessPieceData(type: $0.type.rawValue, color: $0.color.rawValue, hasMoved: $0.hasMoved) },
            moveHistory: game.moveHistory.map {
                ChessGameState.MoveData(
                    fromRow: $0.fromRow,
                    fromCol: $0.fromCol,
                    toRow: $0.toRow,
                    toCol: $0.toCol,
                    pieceType: $0.piece.type.rawValue,
                    pieceColor: $0.piece.color.rawValue,
                    isCheck: $0.isCheck,
                    isCheckmate: $0.isCheckmate
                )
            }
        )
        
        await sharePlayService.sendMessage(.gameStateUpdate(state))
    }
    
    private func applyGameState(_ state: ChessGameState) async {
        guard var game = currentGame else { return }
        
        game.board = state.board.map { row in
            row.map { pieceData in
                pieceData.map { data in
                    ChessPiece(
                        type: ChessPiece.PieceType(rawValue: data.type) ?? .pawn,
                        color: ChessGame.PieceColor(rawValue: data.color) ?? .white,
                        hasMoved: data.hasMoved
                    )
                }
            }
        }
        
        if let turn = ChessGame.PieceColor(rawValue: state.currentTurn) {
            game.currentTurn = turn
        }
        
        if let gameState = ChessGame.GameState(rawValue: state.gameState) {
            game.gameState = gameState
        }
        
        game.winnerID = state.winnerID
        
        gameService.loadGame(game)
        currentGame = game
    }
    
    private func handlePlayerMove(_ move: ChessMessage.Move) async {
        do {
            _ = try await gameService.makeMove(
                fromRow: move.fromRow,
                fromCol: move.fromCol,
                toRow: move.toRow,
                toCol: move.toCol
            )
            currentGame = gameService.currentGame
        } catch {
            print("❌ Failed to apply remote move: \(error)")
        }
    }
    
    public func endGame() async {
        if sharePlayService.isActive {
            await sharePlayService.endSession()
        }
        await gameService.endGame()
        currentGame = nil
        selectedSquare = nil
        aiPlayerID = nil
    }
}
