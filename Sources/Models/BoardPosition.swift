import Foundation

/// Board position struct used by board games
public struct BoardPosition: Codable, Hashable, Sendable {
    public let row: Int
    public let col: Int
    
    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}
