import Testing
import Foundation
@testable import LayoverKit

/// Tests for ChatService
@Suite("Chat Service Tests")
@MainActor
struct ChatServiceTests {
    
    @Test("ChatService initialization")
    func testChatServiceInitialization() {
        let service = ChatService()
        
        let messages = service.getMessages(for: UUID())
        #expect(messages.isEmpty)
    }
    
    @Test("Send message without translation")
    func testSendMessageWithoutTranslation() async throws {
        let service = ChatService()
        let roomID = UUID()
        let senderID = UUID()
        
        let message = try await service.sendMessage(
            roomID: roomID,
            senderID: senderID,
            senderUsername: "Alice",
            text: "Hello",
            language: "en"
        )
        
        #expect(message.originalText == "Hello")
        #expect(message.senderUsername == "Alice")
        #expect(message.translatedVersions.isEmpty)
    }
    
    @Test("Send message with translation")
    func testSendMessageWithTranslation() async throws {
        let service = ChatService()
        let roomID = UUID()
        
        let message = try await service.sendMessage(
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Alice",
            text: "Hello",
            language: "en",
            targetLanguages: ["es", "fr"]
        )
        
        #expect(message.originalText == "Hello")
        #expect(!message.translatedVersions.isEmpty)
    }
    
    @Test("Get messages for room")
    func testGetMessagesForRoom() async throws {
        let service = ChatService()
        let roomID = UUID()
        
        _ = try await service.sendMessage(
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Alice",
            text: "Hello",
            language: "en"
        )
        
        _ = try await service.sendMessage(
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Bob",
            text: "Hi",
            language: "en"
        )
        
        let messages = service.getMessages(for: roomID)
        #expect(messages.count == 2)
    }
    
    @Test("Get messages with limit")
    func testGetMessagesWithLimit() async throws {
        let service = ChatService()
        let roomID = UUID()
        
        for i in 1...10 {
            _ = try await service.sendMessage(
                roomID: roomID,
                senderID: UUID(),
                senderUsername: "User\(i)",
                text: "Message \(i)",
                language: "en"
            )
        }
        
        let messages = service.getMessages(for: roomID, limit: 5)
        #expect(messages.count == 5)
    }
    
    @Test("Translate existing message")
    func testTranslateExistingMessage() async throws {
        let service = ChatService()
        let roomID = UUID()
        
        let originalMessage = try await service.sendMessage(
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Alice",
            text: "Hello",
            language: "en"
        )
        
        let translatedMessage = try await service.translateMessage(originalMessage, to: "es")
        
        #expect(translatedMessage.hasTranslation(for: "es"))
    }
    
    @Test("Translation caching - don't retranslate")
    func testTranslationCaching() async throws {
        let service = ChatService()
        let roomID = UUID()
        
        let message = try await service.sendMessage(
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Alice",
            text: "Hello",
            language: "en",
            targetLanguages: ["es"]
        )
        
        // Translate again to same language
        let cachedMessage = try await service.translateMessage(message, to: "es")
        
        #expect(cachedMessage.id == message.id)
        #expect(cachedMessage.hasTranslation(for: "es"))
    }
    
    @Test("Add reaction to message")
    func testAddReaction() async throws {
        let service = ChatService()
        let roomID = UUID()
        let userID = UUID()
        
        let message = try await service.sendMessage(
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Alice",
            text: "Hello",
            language: "en"
        )
        
        service.addReaction(to: message.id, roomID: roomID, emoji: "👍", from: userID)
        
        let messages = service.getMessages(for: roomID)
        let updatedMessage = messages.first { $0.id == message.id }
        
        #expect(updatedMessage?.reactions["👍"]?.contains(userID) == true)
    }
    
    @Test("Send system message")
    func testSendSystemMessage() {
        let service = ChatService()
        let roomID = UUID()
        
        service.sendSystemMessage(roomID: roomID, text: "User joined")
        
        let messages = service.getMessages(for: roomID)
        #expect(messages.count == 1)
        #expect(messages.first?.isSystemMessage == true)
    }
    
    @Test("Extract vocabulary from message")
    func testExtractVocabulary() async throws {
        let service = ChatService()
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello wonderful world",
            originalLanguage: "en"
        )
        
        let cards = try await service.extractVocabulary(
            from: message,
            targetLanguage: "es"
        )
        
        #expect(!cards.isEmpty)
        #expect(cards.allSatisfy { $0.language == "en" })
        #expect(cards.allSatisfy { $0.targetLanguage == "es" })
    }
    
    @Test("Messages for different rooms don't mix")
    func testMessagesForDifferentRooms() async throws {
        let service = ChatService()
        let room1 = UUID()
        let room2 = UUID()
        
        _ = try await service.sendMessage(
            roomID: room1,
            senderID: UUID(),
            senderUsername: "Alice",
            text: "Room 1",
            language: "en"
        )
        
        _ = try await service.sendMessage(
            roomID: room2,
            senderID: UUID(),
            senderUsername: "Bob",
            text: "Room 2",
            language: "en"
        )
        
        let room1Messages = service.getMessages(for: room1)
        let room2Messages = service.getMessages(for: room2)
        
        #expect(room1Messages.count == 1)
        #expect(room2Messages.count == 1)
        #expect(room1Messages.first?.originalText == "Room 1")
        #expect(room2Messages.first?.originalText == "Room 2")
    }
}
