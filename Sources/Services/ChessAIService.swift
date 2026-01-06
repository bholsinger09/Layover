import Foundation

public final class ChessAIService {
    public init() {}
    
    /// Make an AI move for the specified color
    public func makeAIMove(game: ChessGame, aiColor: ChessGame.PieceColor) async -> (fromRow: Int, fromCol: Int, toRow: Int, toCol: Int)? {
        // Simple AI: Find all valid moves and pick a random one
        var validMoves: [(Int, Int, Int, Int)] = []
        
        for fromRow in 0..<8 {
            for fromCol in 0..<8 {
                guard let piece = game.board[fromRow][fromCol], piece.color == aiColor else {
                    continue
                }
                
                // Try all possible destination squares
                for toRow in 0..<8 {
                    for toCol in 0..<8 {
                        if isValidMove(fromRow: fromRow, fromCol: fromCol, toRow: toRow, toCol: toCol, game: game) {
                            validMoves.append((fromRow, fromCol, toRow, toCol))
                        }
                    }
                }
            }
        }
        
        // Pick a random valid move
        if !validMoves.isEmpty {
            return validMoves.randomElement()
        }
        
        return nil
    }
    
    private func isValidMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, game: ChessGame) -> Bool {
        guard let piece = game.board[fromRow][fromCol] else { return false }
        
        // Can't capture your own piece
        if let targetPiece = game.board[toRow][toCol], targetPiece.color == piece.color {
            return false
        }
        
        let rowDiff = abs(toRow - fromRow)
        let colDiff = abs(toCol - fromCol)
        
        switch piece.type {
        case .pawn:
            return isValidPawnMove(from: (fromRow, fromCol), to: (toRow, toCol), piece: piece, board: game.board)
        case .knight:
            return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2)
        case .bishop:
            return rowDiff == colDiff && isPathClear(from: (fromRow, fromCol), to: (toRow, toCol), board: game.board)
        case .rook:
            return (fromRow == toRow || fromCol == toCol) && isPathClear(from: (fromRow, fromCol), to: (toRow, toCol), board: game.board)
        case .queen:
            return (rowDiff == colDiff || fromRow == toRow || fromCol == toCol) && isPathClear(from: (fromRow, fromCol), to: (toRow, toCol), board: game.board)
        case .king:
            return rowDiff <= 1 && colDiff <= 1
        }
    }
    
    private func isValidPawnMove(from: (Int, Int), to: (Int, Int), piece: ChessPiece, board: [[ChessPiece?]]) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        let direction = piece.color == .white ? 1 : -1
        
        // Move forward one square
        if toCol == fromCol && toRow == fromRow + direction && board[toRow][toCol] == nil {
            return true
        }
        
        // Move forward two squares from starting position
        if !piece.hasMoved && toCol == fromCol && toRow == fromRow + (direction * 2) &&
           board[toRow][toCol] == nil && board[fromRow + direction][fromCol] == nil {
            return true
        }
        
        // Capture diagonally
        if abs(toCol - fromCol) == 1 && toRow == fromRow + direction {
            if let targetPiece = board[toRow][toCol], targetPiece.color != piece.color {
                return true
            }
        }
        
        return false
    }
    
    private func isPathClear(from: (Int, Int), to: (Int, Int), board: [[ChessPiece?]]) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        let rowStep = (toRow - fromRow).signum()
        let colStep = (toCol - fromCol).signum()
        
        var currentRow = fromRow + rowStep
        var currentCol = fromCol + colStep
        
        while currentRow != toRow || currentCol != toCol {
            if board[currentRow][currentCol] != nil {
                return false
            }
            currentRow += rowStep
            currentCol += colStep
        }
        
        return true
    }
}
