import Foundation
import Testing

@testable import LayoverKit

/// Tests for User model
@Suite("User Model Tests")
struct UserTests {

    @Test("User initialization with default values")
    func testUserInitialization() {
        let user = User(username: "TestUser")

        #expect(user.username == "TestUser")
        #expect(user.isHost == false)
        #expect(user.isSubHost == false)
        #expect(user.avatarURL == nil)
        #expect(user.appleUserID == nil)
        #expect(user.email == nil)
    }

    @Test("User initialization with custom values")
    func testUserInitializationWithCustomValues() {
        let url = URL(string: "https://example.com/avatar.png")
        let user = User(
            appleUserID: "test.apple.id",
            username: "HostUser",
            email: "host@example.com",
            avatarURL: url,
            isHost: true,
            isSubHost: false
        )

        #expect(user.username == "HostUser")
        #expect(user.email == "host@example.com")
        #expect(user.appleUserID == "test.apple.id")
        #expect(user.isHost == true)
        #expect(user.isSubHost == false)
        #expect(user.avatarURL == url)
    }

    @Test("User conforms to Codable")
    func testUserCodable() throws {
        let user = User(username: "TestUser", isHost: true)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(user)
        let decodedUser = try decoder.decode(User.self, from: data)

        #expect(decodedUser.username == user.username)
        #expect(decodedUser.isHost == user.isHost)
        #expect(decodedUser.id == user.id)
    }
}
