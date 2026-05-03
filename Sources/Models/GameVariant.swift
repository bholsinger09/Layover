import Foundation

/// Regional variants for chess and other games
public struct GameVariant: LayoverModel {
    public let id: UUID
    public let gameType: GameType
    public let name: String
    public let region: String
    public let description: String
    public let rules: [String: String] // Key-value pairs of rule modifications
    public let iconName: String?
    
    public init(
        id: UUID = UUID(),
        gameType: GameType,
        name: String,
        region: String,
        description: String,
        rules: [String: String],
        iconName: String? = nil
    ) {
        self.id = id
        self.gameType = gameType
        self.name = name
        self.region = region
        self.description = description
        self.rules = rules
        self.iconName = iconName
    }
    
    public enum GameType: String, Codable, Sendable {
        case chess
        case checkers
        case connectFour
    }
}

/// Regional chess and game variants
public struct GameVariants {
    
    // MARK: - Chess Variants
    
    public static let standardChess = GameVariant(
        gameType: .chess,
        name: "Standard Chess",
        region: "International",
        description: "Classic FIDE rules chess",
        rules: [
            "boardSize": "8x8",
            "startingPosition": "standard",
            "castling": "enabled",
            "enPassant": "enabled"
        ]
    )
    
    public static let xiangqi = GameVariant(
        gameType: .chess,
        name: "Xiangqi (象棋)",
        region: "China",
        description: "Chinese Chess - pieces move on intersection points",
        rules: [
            "boardSize": "9x10",
            "startingPosition": "xiangqi",
            "river": "enabled", // Central river affects piece movement
            "palace": "enabled", // Restricted area for generals
            "cannon": "enabled" // Unique jumping capture piece
        ],
        iconName: "xiangqi.symbol"
    )
    
    public static let shogi = GameVariant(
        gameType: .chess,
        name: "Shogi (将棋)",
        region: "Japan",
        description: "Japanese Chess - captured pieces can be dropped back",
        rules: [
            "boardSize": "9x9",
            "startingPosition": "shogi",
            "drops": "enabled", // Can place captured pieces
            "promotion": "zone-based" // Pieces promote in enemy territory
        ],
        iconName: "shogi.symbol"
    )
    
    public static let chess960 = GameVariant(
        gameType: .chess,
        name: "Chess960 (Fischer Random)",
        region: "International",
        description: "Randomized starting positions",
        rules: [
            "boardSize": "8x8",
            "startingPosition": "random",
            "castling": "modified", // Special castling rules
            "positions": "960" // Number of possible starting positions
        ]
    )
    
    // MARK: - Checkers Variants
    
    public static let americanCheckers = GameVariant(
        gameType: .checkers,
        name: "American Checkers",
        region: "USA",
        description: "Standard 8x8 checkers",
        rules: [
            "boardSize": "8x8",
            "forcedCapture": "true",
            "kingBackward": "true",
            "flyingKings": "false"
        ]
    )
    
    public static let internationalDraughts = GameVariant(
        gameType: .checkers,
        name: "International Draughts",
        region: "Europe",
        description: "10x10 board with flying kings",
        rules: [
            "boardSize": "10x10",
            "forcedCapture": "true",
            "kingBackward": "true",
            "flyingKings": "true", // Kings can move multiple squares
            "maximalCapture": "true" // Must capture maximum pieces
        ]
    )
    
    public static let brazilianCheckers = GameVariant(
        gameType: .checkers,
        name: "Brazilian Checkers",
        region: "Brazil",
        description: "Similar to International with different starting position",
        rules: [
            "boardSize": "8x8",
            "forcedCapture": "true",
            "kingBackward": "true",
            "flyingKings": "true"
        ]
    )
    
    public static let russianCheckers = GameVariant(
        gameType: .checkers,
        name: "Russian Checkers (Shashki)",
        region: "Russia",
        description: "Can capture backward, kings fly",
        rules: [
            "boardSize": "8x8",
            "forcedCapture": "true",
            "backwardCapture": "true", // Can capture backward as regular piece
            "kingBackward": "true",
            "flyingKings": "true"
        ]
    )
    
    // MARK: - Connect Four Variants
    
    public static let standardConnectFour = GameVariant(
        gameType: .connectFour,
        name: "Standard Connect Four",
        region: "International",
        description: "Classic 7x6 grid",
        rules: [
            "boardSize": "7x6",
            "toWin": "4",
            "dimensions": "2D"
        ]
    )
    
    public static let popOut = GameVariant(
        gameType: .connectFour,
        name: "Pop Out",
        region: "International",
        description: "Players can remove their bottom pieces",
        rules: [
            "boardSize": "7x6",
            "toWin": "4",
            "popOut": "enabled", // Can remove own pieces from bottom
            "dimensions": "2D"
        ]
    )
    
    public static let powerUp = GameVariant(
        gameType: .connectFour,
        name: "Power Up",
        region: "International",
        description: "Special pieces with unique abilities",
        rules: [
            "boardSize": "7x6",
            "toWin": "4",
            "powerPieces": "enabled", // Pieces with special abilities
            "anvil": "enabled", // Pushes pieces down
            "wall": "enabled", // Blocks columns
            "dimensions": "2D"
        ]
    )
    
    // MARK: - Collections
    
    public static let allChessVariants: [GameVariant] = [
        standardChess,
        xiangqi,
        shogi,
        chess960
    ]
    
    public static let allCheckersVariants: [GameVariant] = [
        americanCheckers,
        internationalDraughts,
        brazilianCheckers,
        russianCheckers
    ]
    
    public static let allConnectFourVariants: [GameVariant] = [
        standardConnectFour,
        popOut,
        powerUp
    ]
    
    public static let allVariants: [GameVariant] = 
        allChessVariants + allCheckersVariants + allConnectFourVariants
    
    /// Get variants for a specific game type
    public static func variants(for gameType: GameVariant.GameType) -> [GameVariant] {
        switch gameType {
        case .chess:
            return allChessVariants
        case .checkers:
            return allCheckersVariants
        case .connectFour:
            return allConnectFourVariants
        }
    }
    
    /// Get variants popular in a region
    public static func variants(forRegion region: String) -> [GameVariant] {
        allVariants.filter { $0.region.lowercased().contains(region.lowercased()) }
    }
}
