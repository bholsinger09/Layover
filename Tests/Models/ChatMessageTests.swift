import Testing
import Foundation
@testable import LayoverKit

/// Tests for ChatMessage model
@Suite("Chat Message Tests")
struct ChatMessageTests {
    
    @Test("ChatMessage initialization")
    func testChatMessageInitialization() {
        let roomID = UUID()
        let senderID = UUID()
        
        let message = ChatMessage(
            roomID: roomID,
            senderID: senderID,
            senderUsername: "Alice",
            originalText: "Hello world",
            originalLanguage: "en"
        )
        
        #expect(message.roomID == roomID)
        #expect(message.senderID == senderID)
        #expect(message.senderUsername == "Alice")
        #expect(message.originalText == "Hello world")
        #expect(message.originalLanguage == "en")
        #expect(message.translatedVersions.isEmpty)
        #expect(message.reactions.isEmpty)
        #expect(message.isSystemMessage == false)
    }
    
    @Test("Get text in original language")
    func testGetTextInOriginalLanguage() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en",
            translatedVersions: ["es": "Hola", "fr": "Bonjour"]
        )
        
        #expect(message.text(for: "en") == "Hello")
    }
    
    @Test("Get text in translated language")
    func testGetTextInTranslatedLanguage() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en",
            translatedVersions: ["es": "Hola", "fr": "Bonjour"]
        )
        
        #expect(message.text(for: "es") == "Hola")
        #expect(message.text(for: "fr") == "Bonjour")
    }
    
    @Test("Get text fallback to original if no translation")
    func testGetTextFallbackToOriginal() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en"
        )
        
        #expect(message.text(for: "es") == "Hello")
    }
    
    @Test("Has translation check")
    func testHasTranslation() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en",
            translatedVersions: ["es": "Hola"]
        )
        
        #expect(message.hasTranslation(for: "es") == true)
        #expect(message.hasTranslation(for: "fr") == false)
    }
    
    @Test("Add reaction to message")
    func testAddReaction() {
        var message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en"
        )
        
        let userID = UUID()
        message.addReaction(emoji: "👍", from: userID)
        
        #expect(message.reactions["👍"]?.contains(userID) == true)
    }
    
    @Test("Multiple reactions from different users")
    func testMultipleReactions() {
        var message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en"
        )
        
        let user1 = UUID()
        let user2 = UUID()
        
        message.addReaction(emoji: "👍", from: user1)
        message.addReaction(emoji: "👍", from: user2)
        message.addReaction(emoji: "❤️", from: user1)
        
        #expect(message.reactions["👍"]?.count == 2)
        #expect(message.reactions["❤️"]?.count == 1)
    }
    
    @Test("System message creation")
    func testSystemMessage() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "System",
            originalText: "User joined",
            originalLanguage: "en",
            isSystemMessage: true
        )
        
        #expect(message.isSystemMessage == true)
    }
    
    @Test("Message context type")
    func testMessageContext() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Great scene!",
            originalLanguage: "en",
            contextType: .watching
        )
        
        #expect(message.contextType == .watching)
    }
    
    @Test("Message conforms to LayoverModel")
    func testMessageConformsToLayoverModel() {
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en"
        )
        
        #expect(message.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
}

/// Tests for VoiceMessage model
@Suite("Voice Message Tests")
struct VoiceMessageTests {
    
    @Test("VoiceMessage initialization")
    func testVoiceMessageInitialization() {
        let chatMessageID = UUID()
        
        let voiceMessage = VoiceMessage(
            chatMessageID: chatMessageID,
            duration: 15.5,
            transcription: "Hello world",
            transcriptionLanguage: "en"
        )
        
        #expect(voiceMessage.chatMessageID == chatMessageID)
        #expect(voiceMessage.duration == 15.5)
        #expect(voiceMessage.transcription == "Hello world")
        #expect(voiceMessage.transcriptionLanguage == "en")
        #expect(voiceMessage.translations.isEmpty)
    }
    
    @Test("VoiceMessage with translations")
    func testVoiceMessageWithTranslations() {
        let translation = VoiceTranslation(
            text: "Hola mundo",
            languageCode: "es"
        )
        
        let voiceMessage = VoiceMessage(
            chatMessageID: UUID(),
            duration: 10.0,
            transcription: "Hello world",
            transcriptionLanguage: "en",
            translations: ["es": translation]
        )
        
        #expect(voiceMessage.translations.count == 1)
        #expect(voiceMessage.translations["es"]?.text == "Hola mundo")
    }
}

/// Tests for TranslationRequest and TranslationResult
@Suite("Translation Data Tests")
struct TranslationDataTests {
    
    @Test("TranslationRequest initialization")
    func testTranslationRequestInitialization() {
        let request = TranslationRequest(
            text: "Hello",
            sourceLanguage: "en",
            targetLanguages: ["es", "fr"]
        )
        
        #expect(request.text == "Hello")
        #expect(request.sourceLanguage == "en")
        #expect(request.targetLanguages.count == 2)
    }
    
    @Test("TranslationResult initialization")
    func testTranslationResultInitialization() {
        let result = TranslationResult(
            originalText: "Hello",
            translations: ["es": "Hola", "fr": "Bonjour"],
            detectedLanguage: "en"
        )
        
        #expect(result.originalText == "Hello")
        #expect(result.translations.count == 2)
        #expect(result.detectedLanguage == "en")
    }
}
