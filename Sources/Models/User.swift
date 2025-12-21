import Foundation

/// Represents a user in the Layover app
struct User: LayoverModel {
    let id: UUID
    var appleUserID: String?
    var username: String
    var email: String?
    var avatarURL: URL?
    var isHost: Bool
    var isSubHost: Bool
    
    init(
        id: UUID = UUID(),
        appleUserID: String? = nil,
        username: String,
        email: String? = nil,
        avatarURL: URL? = nil,
        isHost: Bool = false,
        isSubHost: Bool = false
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.username = username
        self.email = email
        self.avatarURL = avatarURL
        self.isHost = isHost
        self.isSubHost = isSubHost
    }
}
