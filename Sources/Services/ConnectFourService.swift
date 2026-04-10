import Foundation

public protocol ConnectFourServiceProtocol: LayoverService {
    func createGame(roomID: UUID, players: [ConnectFourPlayer]) async throws -> ConnectFourGame
    func dropPiece(game: ConnectFourGame, column: Int) async throws -> ConnectFourGame
    func getValidColumns(game: ConnectFourGame) -> [Int]
}

public final class ConnectFourService: ConnectFourServiceProtocol {
    public init() {}
    
    public func createGame(roomID: UUID, players: [ConnectFourPlayer]) async throws -> ConnectFourGame {
        return ConnectFourGame (
            roomID: roomID,
            players: players,
            board: ConnectFourGame.createEmptyBoard()
        )
    }
    
    public func dropPiece(game: ConnectFourGame, column: Int) async throws -> ConnectFourGame {
        var updatedGame = game
        
        guard column >= 0 && column < 7 else {
            throw ConnectFourError.invalidColumn
        }
        
        guard game.gameState == .active else {
            throw ConnectFourError.gameOver
        }
        
        // Find the lowest available row in the column
        var targetRow = -1
        for row in (0..<6).reversed() {
            if updatedGame.board[row][column] == nil {
                targetRow = row
                break
            }
        }
        
        guard targetRow >= 0 else {
            throw ConnectFourError.columnFull
        }
        
        // Place the piece
        let piece = ConnectFourPiece(color: updatedGame.currentTurn)
        updatedGame.board[targetRow][column] = piece
        
        // Record the move
        let move = ConnectFourMove(
            column: column,
            row: targetRow,
            color: updatedGame.currentTurn
        )
        updatedGame.moveHistory.append(move)
        
        // Check for win
        if let winningLine = checkForWin(board: updatedGame.board, lastRow: targetRow, lastCol: column, color: updatedGame.currentTurn) {
            updatedGame.gameState = .won
            updatedGame.winningLine = winningLine
            let winner = updatedGame.players.first { $0.color == updatedGame.currentTurn }
            updatedGame.winnerID = winner?.userID
            return updatedGame
        }
        
        // Check for draw (board full)
        if isBoardFull(board: updatedGame.board) {
            updatedGame.gameState = .draw
            return updatedGame
        }
        
        // Switch turns
        updatedGame.currentTurn = updatedGame.currentTurn == .yellow ? .red : .yellow
        
        return updatedGame
    }
    
    public func getValidColumns(game: ConnectFourGame) -> [Int] {
        var validColumns: [Int] = []
        
        for col in 0..<7 {
            // Check if top row is empty
            if game.board[0][col] == nil {
                validColumns.append(col)
            }
        }
        
        return validColumns
    }
    
    /// Check if there are 4 in a row from the last placed piece
    private func checkForWin(board: [[ConnectFourPiece?]], lastRow: Int, lastCol: Int, color: ConnectFourGame.PieceColor) -> [(row: Int, col: Int)]? {
        // Check horizontal
        if let line = checkDirection(board: board, row: lastRow, col: lastCol, color: color, dRow: 0, dCol: 1) {
            return line
        }
        
        // Check vertical
        if let line = checkDirection(board: board, row: lastRow, col: lastCol, color: color, dRow: 1, dCol: 0) {
            return line
        }
        
        // Check diagonal (bottom-left to top-right)
        if let line = checkDirection(board: board, row: lastRow, col: lastCol, color: color, dRow: -1, dCol: 1) {
            return line
        }
        
        // Check diagonal (top-left to bottom-right)
        if let line = checkDirection(board: board, row: lastRow, col: lastCol, color: color, dRow: 1, dCol: 1) {
            return line
        }
        
        return nil
    }
    
    private func checkDirection(board: [[ConnectFourPiece?]], row: Int, col: Int, color: ConnectFourGame.PieceColor, dRow: Int, dCol: Int) -> [(row: Int, col: Int)]? {
        var positions: [(row: Int, col: Int)] = [(row, col)]
        
        // Check in positive direction
        var r = row + dRow
        var c = col + dCol
        while r >= 0 && r < 6 && c >= 0 && c < 7,
              let piece = board[r][c],
              piece.color == color {
            positions.append((r, c))
            r += dRow
            c += dCol
        }
        
        // Check in negative direction
        r = row - dRow
        c = col - dCol
        while r >= 0 && r < 6 && c >= 0 && c < 7,
              let piece = board[r][c],
              piece.color == color {
            positions.insert((r, c), at: 0)
            r -= dRow
            c -= dCol
        }
        
        if positions.count >= 4 {
            return positions
        }
        
        return nil
    }
    
    private func isBoardFull(board: [[ConnectFourPiece?]]) -> Bool {
        for col in 0..<7 {
            if board[0][col] == nil {
                return false
            }
        }
        return true
    }
}

public enum ConnectFourError: Error, LocalizedError {
    case invalidColumn
    case columnFull
    case gameOver
    
    public var errorDescription: String? {
        switch self {
        case .invalidColumn:
            return "Invalid column"
        case .columnFull:
            return "Column is full"
        case .gameOver:
            return "Game is over"
        }
    }
}
