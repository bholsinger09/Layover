import Foundation

/// Service for managing Chess games
@MainActor
public protocol ChessServiceProtocol: LayoverService {
    var currentGame: ChessGame? { get }
    
    func startGame(roomID: UUID, players: [UUID]) async throws -> ChessGame
    func loadGame(_ game: ChessGame)
    func makeMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) async throws -> ChessMove
    func isValidMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> Bool
    func resign(playerID: UUID) async throws
    func endGame() async
}

@MainActor
public final class ChessService: ChessServiceProtocol {
    public private(set) var currentGame: ChessGame?
    
    public nonisolated init() {}
    
    public func loadGame(_ game: ChessGame) {
        currentGame = game
    }
    
    public func startGame(roomID: UUID, players: [UUID]) async throws -> ChessGame {
        guard players.count == 2 else {
            throw ChessError.invalidPlayerCount
        }
        
        let chessPlayers = [
            ChessPlayer(userID: players[0], color: .white),
            ChessPlayer(userID: players[1], color: .black)
        ]
        
        let game = ChessGame(
            roomID: roomID,
            players: chessPlayers
        )
        
        currentGame = game
        return game
    }
    
    public func makeMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) async throws -> ChessMove {
        guard var game = currentGame else {
            throw ChessError.noActiveGame
        }
        
        // Validate move
        guard isValidMove(fromRow: fromRow, fromCol: fromCol, toRow: toRow, toCol: toCol) else {
            throw ChessError.invalidMove
        }
        
        // Get the piece being moved
        guard let piece = game.board[fromRow][fromCol] else {
            throw ChessError.noPieceAtPosition
        }
        
        // Check if it's the correct player's turn
        guard piece.color == game.currentTurn else {
            throw ChessError.notYourTurn
        }
        
        // Capture piece if present
        let capturedPiece = game.board[toRow][toCol]
        if let captured = capturedPiece {
            game.capturedPieces.append(captured)
        }
        
        // Move the piece
        var movedPiece = piece
        movedPiece.hasMoved = true
        game.board[toRow][toCol] = movedPiece
        game.board[fromRow][fromCol] = nil
        
        // Check for check/checkmate
        let isCheck = isKingInCheck(board: game.board, color: game.currentTurn == .white ? .black : .white)
        let isCheckmate = isCheck && isCheckmate(board: game.board, color: game.currentTurn == .white ? .black : .white)
        
        // Create move record
        let move = ChessMove(
            fromRow: fromRow,
            fromCol: fromCol,
            toRow: toRow,
            toCol: toCol,
            piece: piece,
            capturedPiece: capturedPiece,
            isCheck: isCheck,
            isCheckmate: isCheckmate
        )
        
        game.moveHistory.append(move)
        
        // Update game state
        if isCheckmate {
            game.gameState = .checkmate
            game.winnerID = game.players.first(where: { $0.color == game.currentTurn })?.userID
        } else if isCheck {
            game.gameState = .check
        } else {
            game.gameState = .active
        }
        
        // Switch turns
        game.currentTurn = game.currentTurn == .white ? .black : .white
        
        currentGame = game
        return move
    }
    
    public func isValidMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> Bool {
        guard let game = currentGame else { return false }
        
        // Check bounds
        guard fromRow >= 0, fromRow < 8, fromCol >= 0, fromCol < 8,
              toRow >= 0, toRow < 8, toCol >= 0, toCol < 8 else {
            return false
        }
        
        // Check if there's a piece at the starting position
        guard let piece = game.board[fromRow][fromCol] else {
            return false
        }
        
        // Can't capture your own piece
        if let targetPiece = game.board[toRow][toCol], targetPiece.color == piece.color {
            return false
        }
        
        // Check piece-specific movement rules
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
    
    private func isKingInCheck(board: [[ChessPiece?]], color: ChessGame.PieceColor) -> Bool {
        // Find the king
        var kingPosition: (Int, Int)?
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col], piece.type == .king && piece.color == color {
                    kingPosition = (row, col)
                    break
                }
            }
            if kingPosition != nil { break }
        }
        
        guard let (kingRow, kingCol) = kingPosition else { return false }
        
        // Check if any opponent piece can attack the king
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col], piece.color != color {
                    // Temporarily check if this piece could move to king's position
                    if wouldBeValidMove(from: (row, col), to: (kingRow, kingCol), piece: piece, board: board) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func wouldBeValidMove(from: (Int, Int), to: (Int, Int), piece: ChessPiece, board: [[ChessPiece?]]) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        let rowDiff = abs(toRow - fromRow)
        let colDiff = abs(toCol - fromCol)
        
        switch piece.type {
        case .pawn:
            let direction = piece.color == .white ? 1 : -1
            return abs(toCol - fromCol) == 1 && toRow == fromRow + direction
        case .knight:
            return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2)
        case .bishop:
            return rowDiff == colDiff && isPathClear(from: from, to: to, board: board)
        case .rook:
            return (fromRow == toRow || fromCol == toCol) && isPathClear(from: from, to: to, board: board)
        case .queen:
            return (rowDiff == colDiff || fromRow == toRow || fromCol == toCol) && isPathClear(from: from, to: to, board: board)
        case .king:
            return rowDiff <= 1 && colDiff <= 1
        }
    }
    
    private func isCheckmate(board: [[ChessPiece?]], color: ChessGame.PieceColor) -> Bool {
        // For simplicity, return false for now
        // Full checkmate detection would require checking all possible moves
        return false
    }
    
    public func resign(playerID: UUID) async throws {
        guard var game = currentGame else {
            throw ChessError.noActiveGame
        }
        
        guard let playerIndex = game.players.firstIndex(where: { $0.userID == playerID }) else {
            throw ChessError.playerNotFound
        }
        
        game.players[playerIndex].hasResigned = true
        game.gameState = .resigned
        
        // Set winner as the other player
        let otherPlayerIndex = playerIndex == 0 ? 1 : 0
        game.winnerID = game.players[otherPlayerIndex].userID
        
        currentGame = game
    }
    
    public func endGame() async {
        currentGame = nil
    }
}

public enum ChessError: LocalizedError {
    case noActiveGame
    case invalidPlayerCount
    case playerNotFound
    case invalidMove
    case noPieceAtPosition
    case notYourTurn
    
    public var errorDescription: String? {
        switch self {
        case .noActiveGame:
            return "No active game"
        case .invalidPlayerCount:
            return "Chess requires exactly 2 players"
        case .playerNotFound:
            return "Player not found in game"
        case .invalidMove:
            return "Invalid move"
        case .noPieceAtPosition:
            return "No piece at that position"
        case .notYourTurn:
            return "Not your turn"
        }
    }
}
