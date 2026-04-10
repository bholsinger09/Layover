import Foundation

/// AI opponent for Checkers with varying difficulty levels
public final class CheckersAIService {
    public enum Difficulty: String, CaseIterable {
        case easy
        case medium
        case hard
        
        var searchDepth: Int {
            switch self {
            case .easy: return 1
            case .medium: return 3
            case .hard: return 5
            }
        }
    }
    
    private let difficulty: Difficulty
    
    public init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
    }
    
    /// Get AI move for the current game state
    public func getMove(for game: CheckersGame) async -> (fromRow: Int, fromCol: Int, toRow: Int, toCol: Int)? {
        // Add small delay for realism
        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.3...0.8) * 1_000_000_000))
        
        // Find all possible moves for AI's color
        var allMoves: [(from: (row: Int, col: Int), to: (row: Int, col: Int), score: Double)] = []
        let service = CheckersService()
        
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = game.board[row][col], piece.color == game.currentTurn {
                    let validMoves = service.getValidMoves(game: game, row: row, col: col)
                    for move in validMoves {
                        let score = evaluateMove(game: game, fromRow: row, fromCol: col, toRow: move.row, toCol: move.col)
                        allMoves.append((from: (row, col), to: move, score: score))
                    }
                }
            }
        }
        
        guard !allMoves.isEmpty else { return nil }
        
        // Select move based on difficulty
        switch difficulty {
        case .easy:
            // 70% random, 30% best
            if Double.random(in: 0...1) < 0.7 {
                let randomMove = allMoves.randomElement()!
                return (randomMove.from.row, randomMove.from.col, randomMove.to.row, randomMove.to.col)
            }
        case .medium:
            // 30% random, 70% best
            if Double.random(in: 0...1) < 0.3 {
                let randomMove = allMoves.randomElement()!
                return (randomMove.from.row, randomMove.from.col, randomMove.to.row, randomMove.to.col)
            }
        case .hard:
            // Always best move
            break
        }
        
        // Pick best move
        let bestMove = allMoves.max(by: { $0.score < $1.score })!
        return (bestMove.from.row, bestMove.from.col, bestMove.to.row, bestMove.to.col)
    }
    
    /// Evaluate move quality
    private func evaluateMove(game: CheckersGame, fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> Double {
        guard let piece = game.board[fromRow][fromCol] else { return 0 }
        
        var score = 0.0
        
        // Check if it's a capture
        let rowDiff = abs(toRow - fromRow)
        if rowDiff == 2 {
            let capturedRow = (fromRow + toRow) / 2
            let capturedCol = (fromCol + toCol) / 2
            if let captured = game.board[capturedRow][capturedCol] {
                score += captured.isKing ? 20.0 : 10.0  // Capturing is valuable
            }
        }
        
        // Check if move creates a king
        if !piece.isKing {
            if (piece.color == .red && toRow == 7) || (piece.color == .black && toRow == 0) {
                score += 15.0  // Becoming a king is very valuable
            }
        }
        
        // Prefer center positions
        let centerDistance = abs(toRow - 3.5) + abs(toCol - 3.5)
        score += (7.0 - centerDistance) * 0.5
        
        // Kings are more valuable
        if piece.isKing {
            score += 5.0
        }
        
        // Prefer advancing pieces
        if piece.color == .red {
            score += Double(toRow - fromRow) * 0.3
        } else {
            score += Double(fromRow - toRow) * 0.3
        }
        
        // Add some randomness for variety
        score += Double.random(in: 0...2)
        
        return score
    }
}
