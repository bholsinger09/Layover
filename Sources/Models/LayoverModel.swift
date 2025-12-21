import Foundation

/// Base protocol for all models in the app
protocol LayoverModel: Identifiable, Codable, Hashable, Sendable {
    var id: UUID { get }
}
