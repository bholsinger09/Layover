import Foundation
import Observation

/// ViewModel for Connect Four game
@MainActor
@Observable
public final class ConnectFourViewModel: LayoverViewModel {
    private let gameService: ConnectFourServiceProtocol
    private let aiService: ConnectFourAIService
    
    public private(set) var currentGame: ConnectFourGame?
    public private(set) var isLoading = false
    public var errorMessage: String?
    
    // AI opponent tracking
    public private(set) var aiPlayerID: UUID?
    public private(set) var isAIThinking = false
    
    // Player color tracking
    public var localPlayerColor: ConnectFourGame.PieceColor?
    
    // Animation for dropping piece
    public private(set) var droppingColumn: Int?
    
    public var board: [[ConnectFourPiece?]] {
        currentGame?.board ?? ConnectFourGame.createEmptyBoard()
    }
    
    public var currentTurn: ConnectFourGame.PieceColor {
        currentGame?.currentTurn ?? .yellow
    }
    
    public var gameState: ConnectFourGame.GameState {
        currentGame?.gameState ?? .active
    }
    
    public var validColumns: [Int] {
        guard let game = currentGame else { return [] }
        return gameService.getValidColumns(game: game)
    }
    
    public nonisolated init(
        gameService: ConnectFourServiceProtocol = ConnectFourService(),
        aiService: ConnectFourAIService = ConnectFourAIService()
    ) {
        self.gameService = gameService
        self.aiService = aiService
    }
    
    /// Start a new game against AI
    public func startAIGame(playerColor: ConnectFourGame.PieceColor, difficulty: ConnectFourAIService.Difficulty) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let aiID = UUID()
            aiPlayerID = aiID
            localPlayerColor = playerColor
            
            let players = [
                ConnectFourPlayer(userID: UUID(), color: playerColor),
                ConnectFourPlayer(userID: aiID, color: playerColor == .yellow ? .red : .yellow)
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
    
    /// Drop a piece in a column
    public func dropPiece(column: Int) async {
        guard let game = currentGame, game.gameState == .active else { return }
        guard game.currentTurn == localPlayerColor else { return }
        
        droppingColumn = column
        
        // Add visual delay for drop animation
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        do {
            currentGame = try await gameService.dropPiece(game: game, column: column)
            droppingColumn = nil
            
            // Check if it's now AI's turn
            if currentGame?.currentTurn != localPlayerColor, currentGame?.gameState == .active {
                await makeAIMove()
            }
        } catch {
            errorMessage = error.localizedDescription
            droppingColumn = nil
        }
    }
    
    /// Make AI move
    private func makeAIMove() async {
        guard let game = currentGame else { return }
        guard game.currentTurn != localPlayerColor else { return }
        
        isAIThinking = true
        
        if let column = await aiService.getMove(for: game) {
            droppingColumn = column
            try? await Task.sleep(nanoseconds: 300_000_000) // Visual delay
            
            do {
                currentGame = try await gameService.dropPiece(game: game, column: column)
                droppingColumn = nil
            } catch {
                errorMessage = error.localizedDescription
                droppingColumn = nil
            }
        }
        
        isAIThinking = false
    }
    
    /// Reset the game
    public func resetGame() {
        currentGame = nil
        localPlayerColor = nil
        aiPlayerID = nil
        errorMessage = nil
        droppingColumn = nil
    }
}
