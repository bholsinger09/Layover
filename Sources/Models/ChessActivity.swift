import Foundation
import GroupActivities

/// SharePlay activity specifically for Chess game
public struct ChessActivity: GroupActivity {
    // IMPORTANT: This identifier must match exactly across all devices and builds
    // Format: <bundle-id>.<activity-name>
    public static let activityIdentifier = "com.bholsinger.LayoverLounge.chess"
    
    public let roomID: UUID
    public let gameID: UUID
    public let roomName: String?
    
    public var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        
        if let name = roomName {
            meta.title = name
            meta.subtitle = "Chess"
        } else {
            meta.title = "Chess"
            meta.subtitle = "LayoverLounge Chess"
        }
        
        meta.type = .generic
        
        return meta
    }
}

/// Messages that can be sent between participants in a Chess game
public enum ChessMessage: Codable {
    case gameStarted(roomID: UUID, gameID: UUID, playerIDs: [UUID])
    case gameStateUpdate(ChessGameState)
    case playerMove(Move)
    case playerResign(playerID: UUID)
    case gameEnded(winnerID: UUID?, reason: String)
    case testPing(from: String, message: String, senderID: UUID)
    case testPong(from: String, message: String, senderID: UUID)
    
    public struct Move: Codable {
        public let playerID: UUID
        public let fromRow: Int
        public let fromCol: Int
        public let toRow: Int
        public let toCol: Int
        public let timestamp: Date
        
        public init(playerID: UUID, fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, timestamp: Date = Date()) {
            self.playerID = playerID
            self.fromRow = fromRow
            self.fromCol = fromCol
            self.toRow = toRow
            self.toCol = toCol
            self.timestamp = timestamp
        }
    }
}

/// Simplified game state for SharePlay synchronization
public struct ChessGameState: Codable {
    public let gameID: UUID
    public let board: [[ChessPieceData?]]
    public let currentTurn: String
    public let gameState: String
    public let winnerID: UUID?
    public let capturedPieces: [ChessPieceData]
    public let moveHistory: [MoveData]
    public let hostPlayerColor: String? // Color that the host is playing
    
    public init(
        gameID: UUID,
        board: [[ChessPieceData?]],
        currentTurn: String,
        gameState: String,
        winnerID: UUID?,
        capturedPieces: [ChessPieceData],
        moveHistory: [MoveData],
        hostPlayerColor: String? = nil
    ) {
        self.gameID = gameID
        self.board = board
        self.currentTurn = currentTurn
        self.gameState = gameState
        self.winnerID = winnerID
        self.capturedPieces = capturedPieces
        self.moveHistory = moveHistory
        self.hostPlayerColor = hostPlayerColor
    }
    
    public struct MoveData: Codable {
        public let fromRow: Int
        public let fromCol: Int
        public let toRow: Int
        public let toCol: Int
        public let pieceType: String
        public let pieceColor: String
        public let isCheck: Bool
        public let isCheckmate: Bool
        
        public init(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, pieceType: String, pieceColor: String, isCheck: Bool, isCheckmate: Bool) {
            self.fromRow = fromRow
            self.fromCol = fromCol
            self.toRow = toRow
            self.toCol = toCol
            self.pieceType = pieceType
            self.pieceColor = pieceColor
            self.isCheck = isCheck
            self.isCheckmate = isCheckmate
        }
    }
}

/// Simplified chess piece for Codable conformance
public struct ChessPieceData: Codable {
    public let type: String
    public let color: String
    public let hasMoved: Bool
    
    public init(type: String, color: String, hasMoved: Bool = false) {
        self.type = type
        self.color = color
        self.hasMoved = hasMoved
    }
}
