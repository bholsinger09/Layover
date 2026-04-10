import Foundation

/// Checkers game state
public struct CheckersGame: LayoverModel {
    public let id: UUID
    public var roomID: UUID
    public var players: [CheckersPlayer]
    public var board: [[CheckersPiece?]]
    public var currentTurn: PieceColor
    public var moveHistory: [CheckersMove]
    public var gameState: GameState
    public var winnerID: UUID?
    public var mustContinueCapture: (row: Int, col: Int)?  // For forced multi-jumps
    
    public enum GameState: String, Codable, Sendable {
        case active
        case won
        case draw
        case resigned
    }
    
    public enum PieceColor: String, Codable, Sendable {
        case red
        case black
    }
    
    public init(
        id: UUID = UUID(),
        roomID: UUID,
        players: [CheckersPlayer] = [],
        board: [[CheckersPiece?]] = CheckersGame.createInitialBoard(),
        currentTurn: PieceColor = .red,
        moveHistory: [CheckersMove] = [],
        gameState: GameState = .active,
        winnerID: UUID? = nil,
        mustContinueCapture: (row: Int, col: Int)? = nil
    ) {
        self.id = id
        self.roomID = roomID
        self.players = players
        self.board = board
        self.currentTurn = currentTurn
        self.moveHistory = moveHistory
        self.gameState = gameState
        self.winnerID = winnerID
        self.mustContinueCapture = mustContinueCapture
    }
    
    public static func createInitialBoard() -> [[CheckersPiece?]] {
        var board = Array(repeating: Array(repeating: nil as CheckersPiece?, count: 8), count: 8)
        
        // Place red pieces (top 3 rows, dark squares only)
        for row in 0..<3 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {  // Dark squares
                    board[row][col] = CheckersPiece(color: .red, isKing: false)
                }
            }
        }
        
        // Place black pieces (bottom 3 rows, dark squares only)
        for row in 5..<8 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {  // Dark squares
                    board[row][col] = CheckersPiece(color: .black, isKing: false)
                }
            }
        }
        
        return board
    }
}

/// Player in a checkers game
public struct CheckersPlayer: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var userID: UUID
    public var color: CheckersGame.PieceColor
    public var hasResigned: Bool
    
    public init(
        id: UUID = UUID(),
        userID: UUID,
        color: CheckersGame.PieceColor,
        hasResigned: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.color = color
        self.hasResigned = hasResigned
    }
}

/// Checkers piece model
public struct CheckersPiece: Codable, Hashable, Sendable {
    public let id: UUID
    public let color: CheckersGame.PieceColor
    public var isKing: Bool
    
    public init(
        id: UUID = UUID(),
        color: CheckersGame.PieceColor,
        isKing: Bool = false
    ) {
        self.id = id
        self.color = color
        self.isKing = isKing
    }
    
    public var symbol: String {
        switch (color, isKing) {
        case (.red, false): return "●"
        case (.red, true): return "◉"
        case (.black, false): return "●"
        case (.black, true): return "◉"
        }
    }
}

/// Checkers move record
public struct CheckersMove: Codable, Hashable, Sendable {
    public let id: UUID
    public let fromRow: Int
    public let fromCol: Int
    public let toRow: Int
    public let toCol: Int
    public let capturedPiece: CheckersPiece?
    public let capturedPosition: (row: Int, col: Int)?
    public let becameKing: Bool
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        fromRow: Int,
        fromCol: Int,
        toRow: Int,
        toCol: Int,
        capturedPiece: CheckersPiece? = nil,
        capturedPosition: (row: Int, col: Int)? = nil,
        becameKing: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.fromRow = fromRow
        self.fromCol = fromCol
        self.toRow = toRow
        self.toCol = toCol
        self.capturedPiece = capturedPiece
        self.capturedPosition = capturedPosition
        self.becameKing = becameKing
        self.timestamp = timestamp
    }
    
    public var notation: String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let ranks = ["1", "2", "3", "4", "5", "6", "7", "8"]
        let separator = capturedPiece != nil ? "×" : "-"
        return "\(files[fromCol])\(ranks[fromRow])\(separator)\(files[toCol])\(ranks[toRow])"
    }
}
