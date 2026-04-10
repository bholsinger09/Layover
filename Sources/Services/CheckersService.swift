import Foundation

public protocol CheckersServiceProtocol: LayoverService {
    func createGame(roomID: UUID, players: [CheckersPlayer]) async throws -> CheckersGame
    func makeMove(game: CheckersGame, fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) async throws -> CheckersGame
    func getValidMoves(game: CheckersGame, row: Int, col: Int) -> [(row: Int, col: Int)]
    func checkGameOver(game: CheckersGame) -> (isOver: Bool, winner: CheckersGame.PieceColor?)
}

public final class CheckersService: CheckersServiceProtocol {
    public init() {}
    
    public func createGame(roomID: UUID, players: [CheckersPlayer]) async throws -> CheckersGame {
        return CheckersGame(
            roomID: roomID,
            players: players,
            board: CheckersGame.createInitialBoard()
        )
    }
    
    public func makeMove(game: CheckersGame, fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) async throws -> CheckersGame {
        var updatedGame = game
        
        guard let piece = updatedGame.board[fromRow][fromCol] else {
            throw CheckersError.noPieceAtPosition
        }
        
        guard piece.color == updatedGame.currentTurn else {
            throw CheckersError.notYourTurn
        }
        
        let validMoves = getValidMoves(game: updatedGame, row: fromRow, col: fromCol)
        guard validMoves.contains(where: { $0.row == toRow && $0.col == toCol }) else {
            throw CheckersError.invalidMove
        }
        
        // Check if this is a capture move
        let rowDiff = abs(toRow - fromRow)
        var capturedPiece: CheckersPiece?
        var capturedPosition: (row: Int, col: Int)?
        
        if rowDiff == 2 {
            // Capture move
            let capturedRow = (fromRow + toRow) / 2
            let capturedCol = (fromCol + toCol) / 2
            capturedPiece = updatedGame.board[capturedRow][capturedCol]
            capturedPosition = (capturedRow, capturedCol)
            updatedGame.board[capturedRow][capturedCol] = nil
        }
        
        // Move the piece
        updatedGame.board[toRow][toCol] = piece
        updatedGame.board[fromRow][fromCol] = nil
        
        // Check for king promotion
        var becameKing = false
        if !piece.isKing {
            if (piece.color == .red && toRow == 7) || (piece.color == .black && toRow == 0) {
                updatedGame.board[toRow][toCol]?.isKing = true
                becameKing = true
            }
        }
        
        // Record the move
        let move = CheckersMove(
            fromRow: fromRow,
            fromCol: fromCol,
            toRow: toRow,
            toCol: toCol,
            capturedPiece: capturedPiece,
            capturedPosition: capturedPosition,
            becameKing: becameKing
        )
        updatedGame.moveHistory.append(move)
        
        // Check if player can capture again (multi-jump)
        if capturedPiece != nil && !becameKing {
            let additionalCaptures = getCaptureMoves(game: updatedGame, row: toRow, col: toCol)
            if !additionalCaptures.isEmpty {
                updatedGame.mustContinueCapture = (toRow, toCol)
                return updatedGame  // Don't switch turns yet
            }
        }
        
        // Clear forced capture flag and switch turns
        updatedGame.mustContinueCapture = nil
        updatedGame.currentTurn = updatedGame.currentTurn == .red ? .black : .red
        
        // Check for game over
        let (isOver, winner) = checkGameOver(game: updatedGame)
        if isOver {
            updatedGame.gameState = .won
            if let winner = winner {
                let winningPlayer = updatedGame.players.first { $0.color == winner }
                updatedGame.winnerID = winningPlayer?.userID
            } else {
                updatedGame.gameState = .draw
            }
        }
        
        return updatedGame
    }
    
    public func getValidMoves(game: CheckersGame, row: Int, col: Int) -> [(row: Int, col: Int)] {
        guard let piece = game.board[row][col] else { return [] }
        
        // If there's a forced capture in progress, only that piece can move
        if let mustCapture = game.mustContinueCapture {
            if mustCapture.row != row || mustCapture.col != col {
                return []
            }
        }
        
        // First check if any captures are available for this player
        let allCaptures = getAllCaptureMoves(game: game, color: piece.color)
        
        // If captures are available, must capture
        if !allCaptures.isEmpty {
            return getCaptureMoves(game: game, row: row, col: col)
        }
        
        // Otherwise, return regular moves
        return getRegularMoves(game: game, row: row, col: col)
    }
    
    private func getRegularMoves(game: CheckersGame, row: Int, col: Int) -> [(row: Int, col: Int)] {
        guard let piece = game.board[row][col] else { return [] }
        var moves: [(row: Int, col: Int)] = []
        
        let directions: [(Int, Int)] = piece.isKing ?
            [(-1, -1), (-1, 1), (1, -1), (1, 1)] :  // Kings move all directions
            piece.color == .red ?
                [(1, -1), (1, 1)] :  // Red moves down
                [(-1, -1), (-1, 1)]  // Black moves up
        
        for (dRow, dCol) in directions {
            let newRow = row + dRow
            let newCol = col + dCol
            
            if isValidPosition(row: newRow, col: newCol) && game.board[newRow][newCol] == nil {
                moves.append((newRow, newCol))
            }
        }
        
        return moves
    }
    
    private func getCaptureMoves(game: CheckersGame, row: Int, col: Int) -> [(row: Int, col: Int)] {
        guard let piece = game.board[row][col] else { return [] }
        var captures: [(row: Int, col: Int)] = []
        
        let directions: [(Int, Int)] = piece.isKing ?
            [(-1, -1), (-1, 1), (1, -1), (1, 1)] :
            piece.color == .red ?
                [(1, -1), (1, 1)] :
                [(-1, -1), (-1, 1)]
        
        for (dRow, dCol) in directions {
            let jumpRow = row + dRow
            let jumpCol = col + dCol
            let landRow = row + dRow * 2
            let landCol = col + dCol * 2
            
            if isValidPosition(row: landRow, col: landCol),
               isValidPosition(row: jumpRow, col: jumpCol),
               let jumpedPiece = game.board[jumpRow][jumpCol],
               jumpedPiece.color != piece.color,
               game.board[landRow][landCol] == nil {
                captures.append((landRow, landCol))
            }
        }
        
        return captures
    }
    
    private func getAllCaptureMoves(game: CheckersGame, color: CheckersGame.PieceColor) -> [(row: Int, col: Int)] {
        var allCaptures: [(row: Int, col: Int)] = []
        
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = game.board[row][col], piece.color == color {
                    let captures = getCaptureMoves(game: game, row: row, col: col)
                    allCaptures.append(contentsOf: captures)
                }
            }
        }
        
        return allCaptures
    }
    
    public func checkGameOver(game: CheckersGame) -> (isOver: Bool, winner: CheckersGame.PieceColor?) {
        var redCount = 0
        var blackCount = 0
        var currentPlayerHasMoves = false
        
        // Count pieces and check for moves
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = game.board[row][col] {
                    if piece.color == .red {
                        redCount += 1
                    } else {
                        blackCount += 1
                    }
                    
                    if piece.color == game.currentTurn {
                        let moves = getValidMoves(game: game, row: row, col: col)
                        if !moves.isEmpty {
                            currentPlayerHasMoves = true
                        }
                    }
                }
            }
        }
        
        // Win by elimination
        if redCount == 0 {
            return (true, .black)
        }
        if blackCount == 0 {
            return (true, .red)
        }
        
        // Win by no legal moves
        if !currentPlayerHasMoves {
            return (true, game.currentTurn == .red ? .black : .red)
        }
        
        return (false, nil)
    }
    
    private func isValidPosition(row: Int, col: Int) -> Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
}

public enum CheckersError: Error, LocalizedError {
    case noPieceAtPosition
    case notYourTurn
    case invalidMove
    case mustContinueCapture
    
    public var errorDescription: String? {
        switch self {
        case .noPieceAtPosition:
            return "No piece at that position"
        case .notYourTurn:
            return "It's not your turn"
        case .invalidMove:
            return "Invalid move"
        case .mustContinueCapture:
            return "You must continue capturing"
        }
    }
}
