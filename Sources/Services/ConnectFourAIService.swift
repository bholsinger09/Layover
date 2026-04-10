import Foundation

/// AI opponent for Connect Four with varying difficulty levels
public final class ConnectFourAIService {
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
    
    /// Get AI column choice for the current game state
    public func getMove(for game: ConnectFourGame) async -> Int? {
        // Add small delay for realism
        try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.3...0.8) * 1_000_000_000))
        
        let service = ConnectFourService()
        let validColumns = service.getValidColumns(game: game)
        
        guard !validColumns.isEmpty else { return nil }
        
        // Check for immediate winning move
        for col in validColumns {
            if canWinInColumn(game: game, column: col, color: game.currentTurn) {
                return col
            }
        }
        
        // Block opponent's winning move
        let opponentColor: ConnectFourGame.PieceColor = game.currentTurn == .yellow ? .red : .yellow
        for col in validColumns {
            if canWinInColumn(game: game, column: col, color: opponentColor) {
                return col
            }
        }
        
        // Evaluate all columns and pick best
        var columnScores: [(column: Int, score: Double)] = []
        
        for col in validColumns {
            let score = evaluateColumn(game: game, column: col)
            columnScores.append((col, score))
        }
        
        // Select move based on difficulty
        switch difficulty {
        case .easy:
            // 70% random, 30% best
            if Double.random(in: 0...1) < 0.7 {
                return validColumns.randomElement()
            }
        case .medium:
            // 30% random, 70% best
            if Double.random(in: 0...1) < 0.3 {
                return validColumns.randomElement()
            }
        case .hard:
            // Always best move
            break
        }
        
        // Pick best column
        let bestColumn = columnScores.max(by: { $0.score < $1.score })?.column
        return bestColumn
    }
    
    /// Check if placing in this column would create a winning position
    private func canWinInColumn(game: ConnectFourGame, column: Int, color: ConnectFourGame.PieceColor) -> Bool {
        // Find where piece would land
        var targetRow = -1
        for row in (0..<6).reversed() {
            if game.board[row][column] == nil {
                targetRow = row
                break
            }
        }
        
        guard targetRow >= 0 else { return false }
        
        // Check if this creates 4 in a row
        let directions = [
            (0, 1),   // Horizontal
            (1, 0),   // Vertical
            (1, 1),   // Diagonal \
            (-1, 1)   // Diagonal /
        ]
        
        for (dRow, dCol) in directions {
            var count = 1  // Count the piece we're placing
            
            // Check positive direction
            var r = targetRow + dRow
            var c = column + dCol
            while r >= 0 && r < 6 && c >= 0 && c < 7,
                  let piece = game.board[r][c],
                  piece.color == color {
                count += 1
                r += dRow
                c += dCol
            }
            
            // Check negative direction
            r = targetRow - dRow
            c = column - dCol
            while r >= 0 && r < 6 && c >= 0 && c < 7,
                  let piece = game.board[r][c],
                  piece.color == color {
                count += 1
                r -= dRow
                c -= dCol
            }
            
            if count >= 4 {
                return true
            }
        }
        
        return false
    }
    
    /// Evaluate column quality
    private func evaluateColumn(game: ConnectFourGame, column: Int) -> Double {
        var score = 0.0
        
        // Find where piece would land
        var targetRow = -1
        for row in (0..<6).reversed() {
            if game.board[row][column] == nil {
                targetRow = row
                break
            }
        }
        
        guard targetRow >= 0 else { return -1000 }
        
        // Prefer center columns
        let centerDistance = abs(column - 3)
        score += (3.0 - Double(centerDistance)) * 2.0
        
        // Evaluate potential connections
        let directions = [(0, 1), (1, 0), (1, 1), (-1, 1)]
        
        for (dRow, dCol) in directions {
            let aiCount = countInDirection(game: game, row: targetRow, col: column, dRow: dRow, dCol: dCol, color: game.currentTurn)
            let opponentColor: ConnectFourGame.PieceColor = game.currentTurn == .yellow ? .red : .yellow
            let oppCount = countInDirection(game: game, row: targetRow, col: column, dRow: dRow, dCol: dCol, color: opponentColor)
            
            // Reward building connections
            if aiCount >= 2 {
                score += Double(aiCount) * 5.0
            }
            
            // Block opponent connections
            if oppCount >= 2 {
                score += Double(oppCount) * 3.0
            }
        }
        
        // Add randomness for variety
        score += Double.random(in: 0...1)
        
        return score
    }
    
    /// Count connected pieces in a direction
    private func countInDirection(game: ConnectFourGame, row: Int, col: Int, dRow: Int, dCol: Int, color: ConnectFourGame.PieceColor) -> Int {
        var count = 1  // Count the position we're considering
        
        // Check positive direction
        var r = row + dRow
        var c = col + dCol
        while r >= 0 && r < 6 && c >= 0 && c < 7 {
            if let piece = game.board[r][c], piece.color == color {
                count += 1
                r += dRow
                c += dCol
            } else if game.board[r][c] == nil {
                // Empty space, continue checking
                r += dRow
                c += dCol
            } else {
                // Opponent piece, stop
                break
            }
        }
        
        // Check negative direction
        r = row - dRow
        c = col - dCol
        while r >= 0 && r < 6 && c >= 0 && c < 7 {
            if let piece = game.board[r][c], piece.color == color {
                count += 1
                r -= dRow
                c -= dCol
            } else if game.board[r][c] == nil {
                r -= dRow
                c -= dCol
            } else {
                break
            }
        }
        
        return count
    }
}
