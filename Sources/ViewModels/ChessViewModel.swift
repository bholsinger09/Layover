import Foundation
import Observation
import GroupActivities

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
    
    // Player color tracking for multiplayer
    public var localPlayerColor: ChessGame.PieceColor?
    
    // Selected square for moves
    public private(set) var selectedSquare: (row: Int, col: Int)?
    
    // Trigger for SharePlay state changes
    public private(set) var sharePlayStateVersion: Int = 0
    
    // Track if this device started the SharePlay session
    private var didStartSharePlay = false
    
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
                guard let self = self else { return }
                print("🎊 Chess SharePlay session started")
                print("   Host status: \(self.didStartSharePlay ? "HOST" : "PARTICIPANT")")
                print("   Local color: \(self.localPlayerColor?.rawValue ?? "not set yet")")
                self.sharePlayStateVersion += 1
                
                // Only the device that initiated SharePlay should broadcast the initial game state
                // The other device will receive it and synchronize
                if self.didStartSharePlay {
                    print("📤 This device started SharePlay - broadcasting initial game state")
                    print("👑 Host color that will be sent: \(self.localPlayerColor?.rawValue ?? "ERROR: not set!")")
                    // Add a small delay to ensure both devices are ready
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    await self.broadcastGameState()
                    self.didStartSharePlay = false // Reset flag
                } else {
                    print("📥 This device joined SharePlay - waiting to receive game state")
                    print("👥 Participant will receive color from host's broadcast")
                }
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
    
    public func startGame(room: Room, currentUser: User, playerColor: ChessGame.PieceColor = .white, includeAI: Bool = true) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let players: [UUID]
            
            // Store local player's color
            localPlayerColor = playerColor
            
            // If SharePlay is active, set up for multiplayer (no AI)
            if sharePlayService.isActive {
                // In SharePlay mode, assign colors based on selection
                // First player gets chosen color, second player gets opposite
                if playerColor == .white {
                    players = [currentUser.id, UUID()] // Placeholder for remote player
                } else {
                    players = [UUID(), currentUser.id] // Placeholder, current user is black
                }
                aiPlayerID = nil
                print("🎮 Starting SharePlay multiplayer game (no AI)")
                print("   Local player color: \(playerColor)")
            } else {
                // Single player mode with AI
                aiPlayerID = UUID()
                if playerColor == .white {
                    players = [currentUser.id, aiPlayerID!]
                } else {
                    players = [aiPlayerID!, currentUser.id]
                }
                print("🤖 Starting single player game with AI")
            }
            
            let game = try await gameService.startGame(roomID: room.id, players: players)
            currentGame = game
            
            print("✅ Chess game started")
            print("   Game ID: \(game.id)")
            print("   Players: \(players)")
            print("   Player color: \(playerColor)")
            if let aiID = aiPlayerID {
                print("   AI opponent: \(aiID)")
            }
            
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
        
        print("🎯 selectSquare called")
        print("   SharePlay active: \(sharePlayService.isActive)")
        print("   Local player color: \(localPlayerColor?.rawValue ?? "none")")
        print("   Current turn: \(game.currentTurn.rawValue)")
        print("   Current user ID: \(currentUserID)")
        
        // For SharePlay games, check against local player color
        let playerColor: ChessGame.PieceColor
        if sharePlayService.isActive, let localColor = localPlayerColor {
            playerColor = localColor
            print("   Using SharePlay color: \(playerColor.rawValue)")
        } else {
            // For non-SharePlay, look up player color from game
            print("   Looking up player from game.players")
            guard let currentPlayer = game.players.first(where: { $0.userID == currentUserID }) else {
                print("   ❌ Player not found in game.players")
                return
            }
            playerColor = currentPlayer.color
            print("   Using game player color: \(playerColor.rawValue)")
        }
        
        guard playerColor == game.currentTurn else {
            errorMessage = "Not your turn"
            print("   ❌ Not your turn: player is \(playerColor.rawValue), current turn is \(game.currentTurn.rawValue)")
            return
        }
        
        print("   ✅ Turn check passed")
        
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
                    print("📤 Broadcasting move: (\(selected.row),\(selected.col)) -> (\(row),\(col))")
                    await sharePlayService.sendMessage(.playerMove(move))
                    
                    // Also broadcast the full game state to keep everyone in sync
                    print("📤 Broadcasting game state update")
                    await broadcastGameState()
                }
                
                // Check for AI turn only if not in SharePlay mode
                if !sharePlayService.isActive {
                    if let aiID = aiPlayerID, let updatedGame = currentGame {
                        if updatedGame.currentTurn == .black {
                            await makeAIMove(aiID: aiID)
                        }
                    }
                }
                
            } catch {
                errorMessage = error.localizedDescription
                selectedSquare = nil
            }
        } else {
            // Selecting a piece
            if let piece = game.board[row][col], piece.color == playerColor {
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
    
    public func startSharePlay(room: Room, currentUser: User, playerColor: ChessGame.PieceColor) async {
        guard let game = currentGame else {
            errorMessage = "No active game to share"
            return
        }
        
        // IMPORTANT: Set local player color BEFORE activating SharePlay
        // This ensures broadcastGameState includes the host's color
        localPlayerColor = playerColor
        print("👑 Host starting SharePlay with color: \(playerColor.rawValue)")
        
        do {
            // Mark that this device is initiating SharePlay
            didStartSharePlay = true
            
            // Create and activate Chess activity directly
            let activity = ChessActivity(roomID: room.id, gameID: game.id, roomName: room.name)
            
            print("🎬 Preparing Chess activity for SharePlay...")
            let result = await activity.prepareForActivation()
            
            print("📋 PrepareForActivation result: \(result)")
            
            switch result {
            case .activationPreferred:
                print("✅ Activating SharePlay session...")
                _ = try await activity.activate()
                print("✅ SharePlay session activated!")
                
            case .activationDisabled:
                print("⚠️ SharePlay activation disabled")
                #if os(macOS)
                // On macOS, SharePlay requires an active FaceTime call
                errorMessage = "SharePlay requires an active FaceTime call. Start a FaceTime call first, then try again."
                #else
                errorMessage = "SharePlay is not available. Make sure you're in a FaceTime call."
                #endif
                didStartSharePlay = false
                
            case .cancelled:
                print("ℹ️ SharePlay activation cancelled by user")
                didStartSharePlay = false
                // Don't show error for user cancellation
                
            @unknown default:
                print("❓ Unknown SharePlay activation result")
                errorMessage = "SharePlay activation returned an unknown result"
                didStartSharePlay = false
            }
            
        } catch {
            didStartSharePlay = false // Reset on error
            print("❌ SharePlay activation error: \(error)")
            // Provide more helpful error message
            if error.localizedDescription.contains("disabled") {
                #if os(macOS)
                errorMessage = "Start a FaceTime call first to use SharePlay"
                #else
                errorMessage = "Join a FaceTime call to use SharePlay"
                #endif
            } else {
                errorMessage = error.localizedDescription
            }
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
            },
            hostPlayerColor: localPlayerColor?.rawValue
        )
        
        print("📤 Broadcasting game state with host color: \(localPlayerColor?.rawValue ?? "none")")
        await sharePlayService.sendMessage(.gameStateUpdate(state))
    }
    
    private func applyGameState(_ state: ChessGameState) async {
        print("📥 Applying game state update")
        print("   Game ID: \(state.gameID)")
        print("   Current turn: \(state.currentTurn)")
        print("   Game state: \(state.gameState)")
        print("   Current local color: \(localPlayerColor?.rawValue ?? "none")")
        
        // If the host sent their color, assign the participant the opposite color
        // This ensures proper color assignment regardless of what was initially selected
        if let hostColorStr = state.hostPlayerColor,
           let hostColor = ChessGame.PieceColor(rawValue: hostColorStr) {
            let newColor = hostColor == .white ? ChessGame.PieceColor.black : ChessGame.PieceColor.white
            if localPlayerColor != newColor {
                localPlayerColor = newColor
                print("🎮 Participant color updated to: \(localPlayerColor?.rawValue ?? "unknown") (host is \(hostColor.rawValue))")
            }
        }
        
        // Always replace with received game state to ensure sync
        // This handles the case where both devices create their own games
        print("🔄 Synchronizing to received game state")
        
        // Create/update game with the received state
        var newGame = ChessGame(
            id: state.gameID,
            roomID: currentGame?.roomID ?? UUID()
        )
        
        newGame.board = state.board.map { row in
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
            newGame.currentTurn = turn
        }
        
        if let gameState = ChessGame.GameState(rawValue: state.gameState) {
            newGame.gameState = gameState
        }
        
        newGame.winnerID = state.winnerID
        
        gameService.loadGame(newGame)
        currentGame = newGame
        print("✅ Game state updated from SharePlay")
        print("   New turn: \(newGame.currentTurn.rawValue)")
        print("   Local player color: \(localPlayerColor?.rawValue ?? "none")")
    }
    
    private func handlePlayerMove(_ move: ChessMessage.Move) async {
        print("📥 Handling remote move: (\(move.fromRow),\(move.fromCol)) -> (\(move.toRow),\(move.toCol))")
        print("   Current game state before move:")
        print("   - Turn: \(currentGame?.currentTurn.rawValue ?? "none")")
        print("   - Game ID: \(currentGame?.id.uuidString ?? "none")")
        
        do {
            _ = try await gameService.makeMove(
                fromRow: move.fromRow,
                fromCol: move.fromCol,
                toRow: move.toRow,
                toCol: move.toCol
            )
            
            // Force property update to trigger observation
            let updatedGame = gameService.currentGame
            currentGame = updatedGame
            
            print("✅ Remote move applied successfully")
            print("   Current turn: \(currentGame?.currentTurn.rawValue ?? "unknown")")
            print("   Piece at destination (\(move.toRow),\(move.toCol)): \(currentGame?.board[move.toRow][move.toCol]?.symbol ?? "empty")")
            
            // Force a state version increment to ensure UI updates
            sharePlayStateVersion += 1
            
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
