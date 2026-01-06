import Foundation

/// Chess game state
public struct ChessGame: LayoverModel {
    public let id: UUID
    public var roomID: UUID
    public var players: [ChessPlayer]
    public var board: [[ChessPiece?]]
    public var currentTurn: PieceColor
    public var moveHistory: [ChessMove]
    public var gameState: GameState
    public var winnerID: UUID?
    public var capturedPieces: [ChessPiece]
    
    public enum GameState: String, Codable, Sendable {
        case active
        case check
        case checkmate
        case stalemate
        case draw
        case resigned
    }
    
    public enum PieceColor: String, Codable, Sendable {
        case white
        case black
    }
    
    public init(
        id: UUID = UUID(),
        roomID: UUID,
        players: [ChessPlayer] = [],
        board: [[ChessPiece?]] = ChessGame.createInitialBoard(),
        currentTurn: PieceColor = .white,
        moveHistory: [ChessMove] = [],
        gameState: GameState = .active,
        winnerID: UUID? = nil,
        capturedPieces: [ChessPiece] = []
    ) {
        self.id = id
        self.roomID = roomID
        self.players = players
        self.board = board
        self.currentTurn = currentTurn
        self.moveHistory = moveHistory
        self.gameState = gameState
        self.winnerID = winnerID
        self.capturedPieces = capturedPieces
    }
    
    public static func createInitialBoard() -> [[ChessPiece?]] {
        var board = Array(repeating: Array(repeating: nil as ChessPiece?, count: 8), count: 8)
        
        // Place white pieces
        board[0] = [
            ChessPiece(type: .rook, color: .white),
            ChessPiece(type: .knight, color: .white),
            ChessPiece(type: .bishop, color: .white),
            ChessPiece(type: .queen, color: .white),
            ChessPiece(type: .king, color: .white),
            ChessPiece(type: .bishop, color: .white),
            ChessPiece(type: .knight, color: .white),
            ChessPiece(type: .rook, color: .white)
        ]
        board[1] = Array(repeating: ChessPiece(type: .pawn, color: .white), count: 8)
        
        // Place black pieces
        board[6] = Array(repeating: ChessPiece(type: .pawn, color: .black), count: 8)
        board[7] = [
            ChessPiece(type: .rook, color: .black),
            ChessPiece(type: .knight, color: .black),
            ChessPiece(type: .bishop, color: .black),
            ChessPiece(type: .queen, color: .black),
            ChessPiece(type: .king, color: .black),
            ChessPiece(type: .bishop, color: .black),
            ChessPiece(type: .knight, color: .black),
            ChessPiece(type: .rook, color: .black)
        ]
        
        return board
    }
}

/// Player in a chess game
public struct ChessPlayer: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var userID: UUID
    public var color: ChessGame.PieceColor
    public var hasResigned: Bool
    
    public init(
        id: UUID = UUID(),
        userID: UUID,
        color: ChessGame.PieceColor,
        hasResigned: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.color = color
        self.hasResigned = hasResigned
    }
}

/// Chess piece model
public struct ChessPiece: Codable, Hashable, Sendable {
    public let id: UUID
    public let type: PieceType
    public let color: ChessGame.PieceColor
    public var hasMoved: Bool
    
    public enum PieceType: String, Codable, Sendable {
        case pawn = "♟"
        case knight = "♞"
        case bishop = "♝"
        case rook = "♜"
        case queen = "♛"
        case king = "♚"
    }
    
    public init(
        id: UUID = UUID(),
        type: PieceType,
        color: ChessGame.PieceColor,
        hasMoved: Bool = false
    ) {
        self.id = id
        self.type = type
        self.color = color
        self.hasMoved = hasMoved
    }
    
    public var symbol: String {
        switch (type, color) {
        case (.pawn, .white): return "♙"
        case (.pawn, .black): return "♟"
        case (.knight, .white): return "♘"
        case (.knight, .black): return "♞"
        case (.bishop, .white): return "♗"
        case (.bishop, .black): return "♝"
        case (.rook, .white): return "♖"
        case (.rook, .black): return "♜"
        case (.queen, .white): return "♕"
        case (.queen, .black): return "♛"
        case (.king, .white): return "♔"
        case (.king, .black): return "♚"
        }
    }
}

/// Chess move record
public struct ChessMove: Codable, Hashable, Sendable {
    public let id: UUID
    public let fromRow: Int
    public let fromCol: Int
    public let toRow: Int
    public let toCol: Int
    public let piece: ChessPiece
    public let capturedPiece: ChessPiece?
    public let isCheck: Bool
    public let isCheckmate: Bool
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        fromRow: Int,
        fromCol: Int,
        toRow: Int,
        toCol: Int,
        piece: ChessPiece,
        capturedPiece: ChessPiece? = nil,
        isCheck: Bool = false,
        isCheckmate: Bool = false,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.fromRow = fromRow
        self.fromCol = fromCol
        self.toRow = toRow
        self.toCol = toCol
        self.piece = piece
        self.capturedPiece = capturedPiece
        self.isCheck = isCheck
        self.isCheckmate = isCheckmate
        self.timestamp = timestamp
    }
    
    public var notation: String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let ranks = ["1", "2", "3", "4", "5", "6", "7", "8"]
        return "\(files[fromCol])\(ranks[fromRow])-\(files[toCol])\(ranks[toRow])"
    }
}
