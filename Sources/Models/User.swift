import Foundation

/// Represents a user in the Layover app
struct User: LayoverModel {
    let id: UUID
    var username: String
    var avatarURL: URL?
    var isHost: Bool
    var isSubHost: Bool
    
    init(
        id: UUID = UUID(),
        username: String,
        avatarURL: URL? = nil,
        isHost: Bool = false,
        isSubHost: Bool = false
    ) {
        self.id = id
        self.username = username
        self.avatarURL = avatarURL
        self.isHost = isHost
        self.isSubHost = isSubHost
    }
}
