import Foundation

/// Represents a user in the Layover app
public struct User: LayoverModel {
    public let id: UUID
    public var appleUserID: String?
    public var username: String
    public var email: String?
    public var avatarURL: URL?
    public var isHost: Bool
    public var isSubHost: Bool

    public init(
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
