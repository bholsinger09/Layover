import Foundation

/// Board position struct
public struct BoardPosition: Codable, Hashable, Sendable {
    public let row: Int
    public let col: Int
    
    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// Connect Four game state
public struct ConnectFourGame: LayoverModel {
    public let id: UUID
    public var roomID: UUID
    public var players: [ConnectFourPlayer]
    public var board: [[ConnectFourPiece?]]  // 6 rows x 7 columns
    public var currentTurn: PieceColor
    public var moveHistory: [ConnectFourMove]
    public var gameState: GameState
    public var winnerID: UUID?
    public var winningLine: [BoardPosition]?  // Highlight winning connection
    
    public enum GameState: String, Codable, Sendable {
        case active
        case won
        case draw
        case resigned
    }
    
    public enum PieceColor: String, Codable, Sendable {
        case yellow
        case red
    }
    
    public init(
        id: UUID = UUID(),
        roomID: UUID,
        players: [ConnectFourPlayer] = [],
        board: [[ConnectFourPiece?]] = ConnectFourGame.createEmptyBoard(),
        currentTurn: PieceColor = .yellow,
        moveHistory: [ConnectFourMove] = [],
        gameState: GameState = .active,
        winnerID: UUID? = nil,
        winningLine: [BoardPosition]? = nil
    ) {
        self.id = id
        self.roomID = roomID
        self.players = players
        self.board = board
        self.currentTurn = currentTurn
        self.moveHistory = moveHistory
        self.gameState = gameState
        self.winnerID = winnerID
        self.winningLine = winningLine
    }
    
    public static func createEmptyBoard() -> [[ConnectFourPiece?]] {
        return Array(repeating: Array(repeating: nil as ConnectFourPiece?, count: 7), count: 6)
    }
}

/// Player in a Connect Four game
public struct ConnectFourPlayer: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var userID: UUID
    public var color: ConnectFourGame.PieceColor
    public var hasResigned: Bool
    
    public init(
        id: UUID = UUID(),
        userID: UUID,
        color: ConnectFourGame.PieceColor,
        hasResigned: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.color = color
        self.hasResigned = hasResigned
    }
}

/// Connect Four piece model
public struct ConnectFourPiece: Codable, Hashable, Sendable {
    public let id: UUID
    public let color: ConnectFourGame.PieceColor
    
    public init(
        id: UUID = UUID(),
        color: ConnectFourGame.PieceColor
    ) {
        self.id = id
        self.color = color
    }
}

/// Connect Four move record
public struct ConnectFourMove: Codable, Hashable, Sendable {
    public let id: UUID
    public let column: Int
    public let row: Int  // Row where piece landed
    public let color: ConnectFourGame.PieceColor
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        column: Int,
        row: Int,
        color: ConnectFourGame.PieceColor,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.column = column
        self.row = row
        self.color = color
        self.timestamp = timestamp
    }
    
    public var notation: String {
        return "Col \(column + 1)"
    }
}
