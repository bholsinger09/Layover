import Foundation

public enum ChessAIDifficulty {
    case beginner
    case intermediate
    case experienced
}

public final class ChessAIService {
    private let difficulty: ChessAIDifficulty
    
    public init(difficulty: ChessAIDifficulty = .experienced) {
        self.difficulty = difficulty
    }
    
    /// Make an AI move for the specified color
    public func makeAIMove(game: ChessGame, aiColor: ChessGame.PieceColor) async -> (fromRow: Int, fromCol: Int, toRow: Int, toCol: Int)? {
        var validMoves: [(move: (Int, Int, Int, Int), score: Int)] = []
        
        for fromRow in 0..<8 {
            for fromCol in 0..<8 {
                guard let piece = game.board[fromRow][fromCol], piece.color == aiColor else {
                    continue
                }
                
                // Try all possible destination squares
                for toRow in 0..<8 {
                    for toCol in 0..<8 {
                        if isValidMove(fromRow: fromRow, fromCol: fromCol, toRow: toRow, toCol: toCol, game: game) {
                            let score = evaluateMove(fromRow: fromRow, fromCol: fromCol, toRow: toRow, toCol: toCol, game: game, aiColor: aiColor)
                            validMoves.append((move: (fromRow, fromCol, toRow, toCol), score: score))
                        }
                    }
                }
            }
        }
        
        if validMoves.isEmpty {
            return nil
        }
        
        switch difficulty {
        case .beginner:
            // Random move
            return validMoves.randomElement()?.move
        case .intermediate:
            // 70% best move, 30% random
            if Int.random(in: 0..<100) < 70 {
                return validMoves.max(by: { $0.score < $1.score })?.move
            } else {
                return validMoves.randomElement()?.move
            }
        case .experienced:
            // Always pick best move
            return validMoves.max(by: { $0.score < $1.score })?.move
        }
    }
    
    private func evaluateMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, game: ChessGame, aiColor: ChessGame.PieceColor) -> Int {
        var score = 0
        
        guard let piece = game.board[fromRow][fromCol] else { return score }
        
        // Capture value
        if let targetPiece = game.board[toRow][toCol] {
            score += pieceValue(targetPiece.type) * 10
        }
        
        // Center control (d4, d5, e4, e5)
        if (toRow == 3 || toRow == 4) && (toCol == 3 || toCol == 4) {
            score += 5
        }
        
        // Piece development (move pieces off back rank)
        if piece.type != .pawn && fromRow == (aiColor == .white ? 0 : 7) {
            score += 3
        }
        
        // Protect the king (castle-friendly positions)
        if piece.type == .king && !piece.hasMoved {
            if abs(toCol - fromCol) == 2 { // Castling
                score += 15
            }
        }
        
        // Pawn advancement
        if piece.type == .pawn {
            let advancement = aiColor == .white ? toRow - fromRow : fromRow - toRow
            score += advancement
            
            // Bonus for promotion proximity
            let promotionRow = aiColor == .white ? 7 : 0
            if abs(toRow - promotionRow) <= 2 {
                score += 8
            }
        }
        
        return score
    }
    
    private func pieceValue(_ type: ChessPiece.PieceType) -> Int {
        switch type {
        case .pawn: return 1
        case .knight: return 3
        case .bishop: return 3
        case .rook: return 5
        case .queen: return 9
        case .king: return 100
        }
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
