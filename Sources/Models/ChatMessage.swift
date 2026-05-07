import Foundation

/// Represents a chat message in a room
public struct ChatMessage: LayoverModel {
    public let id: UUID
    public let roomID: UUID
    public let senderID: UUID
    public let senderUsername: String
    public let originalText: String
    public let originalLanguage: String // ISO 639-1 code
    public let timestamp: Date
    public let translatedVersions: [String: String] // language code -> translated text
    public let replyToMessageID: UUID?
    public let reactions: [String: Set<UUID>] // emoji -> user IDs
    public let isSystemMessage: Bool
    public let contextType: MessageContext?
    
    public init(
        id: UUID = UUID(),
        roomID: UUID,
        senderID: UUID,
        senderUsername: String,
        originalText: String,
        originalLanguage: String,
        timestamp: Date = Date(),
        translatedVersions: [String: String] = [:],
        replyToMessageID: UUID? = nil,
        reactions: [String: Set<UUID>] = [:],
        isSystemMessage: Bool = false,
        contextType: MessageContext? = nil
    ) {
        self.id = id
        self.roomID = roomID
        self.senderID = senderID
        self.senderUsername = senderUsername
        self.originalText = originalText
        self.originalLanguage = originalLanguage
        self.timestamp = timestamp
        self.translatedVersions = translatedVersions
        self.replyToMessageID = replyToMessageID
        self.reactions = reactions
        self.isSystemMessage = isSystemMessage
        self.contextType = contextType
    }
    
    /// Get translated text for a specific language, fallback to original
    public func text(for languageCode: String) -> String {
        if languageCode == originalLanguage {
            return originalText
        }
        return translatedVersions[languageCode] ?? originalText
    }
    
    /// Check if translation exists for a language
    public func hasTranslation(for languageCode: String) -> Bool {
        translatedVersions[languageCode] != nil
    }
    
    /// Add a reaction from a user
    public mutating func addReaction(emoji: String, from userID: UUID) {
        var users = reactions[emoji] ?? Set<UUID>()
        users.insert(userID)
        var newReactions = reactions
        newReactions[emoji] = users
        self = ChatMessage(
            id: id,
            roomID: roomID,
            senderID: senderID,
            senderUsername: senderUsername,
            originalText: originalText,
            originalLanguage: originalLanguage,
            timestamp: timestamp,
            translatedVersions: translatedVersions,
            replyToMessageID: replyToMessageID,
            reactions: newReactions,
            isSystemMessage: isSystemMessage,
            contextType: contextType
        )
    }
}

/// Context type for messages - helps with vocabulary extraction
public enum MessageContext: String, Codable, Sendable {
    case watching = "watching" // During video watching
    case gaming = "gaming" // During game play
    case listening = "listening" // During music listening
    case general = "general" // General chat
}

/// Represents a voice message with translation
public struct VoiceMessage: LayoverModel {
    public let id: UUID
    public let chatMessageID: UUID
    public let audioURL: URL?
    public let duration: TimeInterval
    public let transcription: String
    public let transcriptionLanguage: String
    public let translations: [String: VoiceTranslation]
    
    public init(
        id: UUID = UUID(),
        chatMessageID: UUID,
        audioURL: URL? = nil,
        duration: TimeInterval,
        transcription: String,
        transcriptionLanguage: String,
        translations: [String: VoiceTranslation] = [:]
    ) {
        self.id = id
        self.chatMessageID = chatMessageID
        self.audioURL = audioURL
        self.duration = duration
        self.transcription = transcription
        self.transcriptionLanguage = transcriptionLanguage
        self.translations = translations
    }
}

/// Voice translation with synthesized audio
public struct VoiceTranslation: Codable, Sendable, Hashable, Equatable {
    public let text: String
    public let audioURL: URL?
    public let languageCode: String
    
    public init(text: String, audioURL: URL? = nil, languageCode: String) {
        self.text = text
        self.audioURL = audioURL
        self.languageCode = languageCode
    }
}

/// Message translation request
public struct TranslationRequest: Codable, Sendable {
    public let text: String
    public let sourceLanguage: String
    public let targetLanguages: [String]
    
    public init(text: String, sourceLanguage: String, targetLanguages: [String]) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguages = targetLanguages
    }
}

/// Translation result
public struct TranslationResult: Codable, Sendable {
    public let originalText: String
    public let translations: [String: String] // language code -> translated text
    public let detectedLanguage: String?
    
    public init(originalText: String, translations: [String: String], detectedLanguage: String? = nil) {
        self.originalText = originalText
        self.translations = translations
        self.detectedLanguage = detectedLanguage
    }
}
