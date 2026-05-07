import Foundation
import Observation

/// Service for handling chat messages with translation
@Observable
public class ChatService {
    private var messages: [UUID: [ChatMessage]] = [:] // roomID -> messages
    private let translationService: TranslationService
    
    public init(translationService: TranslationService = TranslationService()) {
        self.translationService = translationService
    }
    
    // MARK: - Message Management
    
    /// Send a message to a room
    public func sendMessage(
        roomID: UUID,
        senderID: UUID,
        senderUsername: String,
        text: String,
        language: String,
        targetLanguages: [String] = [],
        replyTo: UUID? = nil,
        context: MessageContext? = nil
    ) async throws -> ChatMessage {
        // Create message
        var message = ChatMessage(
            roomID: roomID,
            senderID: senderID,
            senderUsername: senderUsername,
            originalText: text,
            originalLanguage: language,
            replyToMessageID: replyTo,
            contextType: context
        )
        
        // Translate if target languages specified
        if !targetLanguages.isEmpty && !text.isEmpty {
            let translations = try await translationService.translate(
                text: text,
                from: language,
                to: targetLanguages
            )
            
            message = ChatMessage(
                id: message.id,
                roomID: message.roomID,
                senderID: message.senderID,
                senderUsername: message.senderUsername,
                originalText: message.originalText,
                originalLanguage: message.originalLanguage,
                timestamp: message.timestamp,
                translatedVersions: translations.translations,
                replyToMessageID: message.replyToMessageID,
                reactions: message.reactions,
                isSystemMessage: message.isSystemMessage,
                contextType: message.contextType
            )
        }
        
        // Store message
        if messages[roomID] == nil {
            messages[roomID] = []
        }
        messages[roomID]?.append(message)
        
        return message
    }
    
    /// Get messages for a room
    public func getMessages(for roomID: UUID, limit: Int? = nil) -> [ChatMessage] {
        guard let roomMessages = messages[roomID] else { return [] }
        
        if let limit = limit {
            return Array(roomMessages.suffix(limit))
        }
        return roomMessages
    }
    
    /// Translate an existing message to a new language
    public func translateMessage(_ message: ChatMessage, to languageCode: String) async throws -> ChatMessage {
        // Check if translation already exists
        if message.hasTranslation(for: languageCode) {
            return message
        }
        
        // Translate
        let result = try await translationService.translate(
            text: message.originalText,
            from: message.originalLanguage,
            to: [languageCode]
        )
        
        // Update message
        var updatedTranslations = message.translatedVersions
        updatedTranslations.merge(result.translations) { _, new in new }
        
        let updatedMessage = ChatMessage(
            id: message.id,
            roomID: message.roomID,
            senderID: message.senderID,
            senderUsername: message.senderUsername,
            originalText: message.originalText,
            originalLanguage: message.originalLanguage,
            timestamp: message.timestamp,
            translatedVersions: updatedTranslations,
            replyToMessageID: message.replyToMessageID,
            reactions: message.reactions,
            isSystemMessage: message.isSystemMessage,
            contextType: message.contextType
        )
        
        // Update stored message
        if var roomMessages = messages[message.roomID],
           let index = roomMessages.firstIndex(where: { $0.id == message.id }) {
            roomMessages[index] = updatedMessage
            messages[message.roomID] = roomMessages
        }
        
        return updatedMessage
    }
    
    /// Add reaction to a message
    public func addReaction(to messageID: UUID, roomID: UUID, emoji: String, from userID: UUID) {
        guard var roomMessages = messages[roomID],
              let index = roomMessages.firstIndex(where: { $0.id == messageID }) else {
            return
        }
        
        roomMessages[index].addReaction(emoji: emoji, from: userID)
        messages[roomID] = roomMessages
    }
    
    /// Extract vocabulary from messages
    public func extractVocabulary(
        from message: ChatMessage,
        targetLanguage: String,
        difficulty: DifficultyLevel = .intermediate
    ) async throws -> [VocabularyCard] {
        // In a real implementation, this would use NLP to extract key words
        // For now, we'll create a simple implementation
        
        let words = message.originalText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 3 } // Simple filtering
        
        var cards: [VocabularyCard] = []
        
        for word in words.prefix(5) { // Limit to 5 words per message
            let translation = try await translationService.translate(
                text: word,
                from: message.originalLanguage,
                to: [targetLanguage]
            )
            
            if let translatedWord = translation.translations[targetLanguage] {
                let card = VocabularyCard(
                    word: word,
                    translation: translatedWord,
                    language: message.originalLanguage,
                    targetLanguage: targetLanguage,
                    context: "From \(message.senderUsername)",
                    exampleSentence: message.originalText,
                    category: categoryFromContext(message.contextType),
                    difficulty: difficulty
                )
                cards.append(card)
            }
        }
        
        return cards
    }
    
    /// Send system message
    public func sendSystemMessage(roomID: UUID, text: String) {
        let message = ChatMessage(
            roomID: roomID,
            senderID: UUID(), // System UUID
            senderUsername: "System",
            originalText: text,
            originalLanguage: "en",
            isSystemMessage: true
        )
        
        if messages[roomID] == nil {
            messages[roomID] = []
        }
        messages[roomID]?.append(message)
    }
    
    // MARK: - Helper Methods
    
    private func categoryFromContext(_ context: MessageContext?) -> VocabularyCategory {
        guard let context = context else { return .general }
        
        switch context {
        case .watching:
            return .entertainment
        case .gaming:
            return .general
        case .listening:
            return .entertainment
        case .general:
            return .general
        }
    }
}
