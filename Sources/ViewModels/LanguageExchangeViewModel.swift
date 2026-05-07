import Foundation
import Observation

/// ViewModel for language exchange features
@Observable
public class LanguageExchangeViewModel {
    // Services
    private let exchangeService: LanguageExchangeService
    private let chatService: ChatService
    private let translationService: TranslationService
    
    // State
    public var currentSession: LanguageExchangeSession?
    public var messages: [ChatMessage] = []
    public var userProfile: LanguageLearningProfile?
    public var potentialPartners: [LanguageLearningProfile] = []
    public var isSessionActive: Bool = false
    public var currentRoomID: UUID?
    
    // UI State
    public var messageText: String = ""
    public var selectedLanguage: String = "en" // Language user is speaking/typing in
    public var targetLanguage: String = "es" // Language user wants to learn/translate to
    public var showOriginalText: Bool = false // Default to showing translations
    public var isTranslating: Bool = false
    public var errorMessage: String?
    
    // Vocabulary
    public var vocabularyCards: [VocabularyCard] = []
    public var showVocabularySheet: Bool = false
    public var currentVocabularyCard: VocabularyCard?
    
    public init(
        exchangeService: LanguageExchangeService = LanguageExchangeService(),
        chatService: ChatService = ChatService(),
        translationService: TranslationService = TranslationService()
    ) {
        self.exchangeService = exchangeService
        self.chatService = chatService
        self.translationService = translationService
    }
    
    // MARK: - Session Management
    
    /// Start a language exchange session
    public func startSession(
        roomID: UUID,
        participants: [User],
        mode: ExchangeMode,
        currentUserID: UUID
    ) {
        // Convert users to participants
        let exchangeParticipants = participants.compactMap { user -> LanguageExchangeParticipant? in
            guard let profile = exchangeService.getProfile(for: user.id) else {
                // Create basic participant from user
                return LanguageExchangeParticipant(
                    userID: user.id,
                    username: user.username,
                    nativeLanguage: "en",
                    learningLanguages: []
                )
            }
            
            return LanguageExchangeParticipant(
                userID: profile.userID,
                username: user.username,
                nativeLanguage: profile.nativeLanguage,
                learningLanguages: profile.learningLanguages.map { $0.languageCode },
                proficiencyLevels: Dictionary(
                    uniqueKeysWithValues: profile.learningLanguages.map {
                        ($0.languageCode, $0.currentProficiency)
                    }
                ),
                interests: profile.culturalInterests
            )
        }
        
        currentSession = exchangeService.startSession(
            roomID: roomID,
            participants: exchangeParticipants,
            mode: mode
        )
        
        currentRoomID = roomID
        isSessionActive = true
        loadMessages()
        
        // Send system message
        chatService.sendSystemMessage(
            roomID: roomID,
            text: "Language Exchange Mode activated! 🌍"
        )
    }
    
    /// End current session
    public func endSession() {
        guard let roomID = currentRoomID else { return }
        
        currentSession = exchangeService.endSession(roomID: roomID)
        isSessionActive = false
        
        if let session = currentSession {
            chatService.sendSystemMessage(
                roomID: roomID,
                text: "Session ended. You practiced for \(Int(session.duration / 60)) minutes and learned \(session.statistics.vocabularyLearned) new words! 🎉"
            )
        }
    }
    
    /// Switch exchange mode
    public func switchMode(to mode: ExchangeMode) {
        guard var session = currentSession else { return }
        
        session = LanguageExchangeSession(
            id: session.id,
            roomID: session.roomID,
            participants: session.participants,
            mode: mode,
            startTime: session.startTime,
            endTime: session.endTime,
            vocabulary: session.vocabulary,
            culturalNotes: session.culturalNotes,
            statistics: session.statistics
        )
        
        currentSession = session
    }
    
    // MARK: - Messaging
    
    /// Send a message with translation
    public func sendMessage(
        senderID: UUID,
        senderUsername: String,
        targetLanguages: [String] = []
    ) async {
        guard let roomID = currentRoomID, !messageText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        isTranslating = true
        errorMessage = nil
        
        do {
            let message = try await chatService.sendMessage(
                roomID: roomID,
                senderID: senderID,
                senderUsername: senderUsername,
                text: messageText,
                language: selectedLanguage,
                targetLanguages: targetLanguages.isEmpty ? [targetLanguage] : targetLanguages,
                context: .general
            )
            
            messages.append(message)
            messageText = ""
            
            // Update session statistics
            if isSessionActive {
                exchangeService.updateSessionStatistics(
                    roomID: roomID,
                    messages: 1
                )
            }
            
            // Auto-extract vocabulary if enabled
            if userProfile?.preferences.autoSaveVocabulary == true,
               let learningLang = userProfile?.learningLanguages.first?.languageCode {
                await extractVocabularyFromMessage(message, targetLanguage: learningLang)
            }
            
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
        
        isTranslating = false
    }
    
    /// Load messages for current room
    public func loadMessages() {
        guard let roomID = currentRoomID else { return }
        messages = chatService.getMessages(for: roomID)
    }
    
    /// Get message text in user's preferred language
    public func getMessageText(_ message: ChatMessage, for userLanguage: String) -> String {
        if showOriginalText {
            return message.originalText
        }
        return message.text(for: userLanguage)
    }
    
    /// Add reaction to message
    public func addReaction(to messageID: UUID, emoji: String, from userID: UUID) {
        guard let roomID = currentRoomID else { return }
        chatService.addReaction(to: messageID, roomID: roomID, emoji: emoji, from: userID)
        loadMessages()
    }
    
    // MARK: - Vocabulary
    
    /// Extract vocabulary from a message
    private func extractVocabularyFromMessage(_ message: ChatMessage, targetLanguage: String) async {
        guard let userID = userProfile?.userID else { return }
        
        do {
            let cards = try await chatService.extractVocabulary(
                from: message,
                targetLanguage: targetLanguage
            )
            
            for card in cards {
                exchangeService.saveVocabulary(card, for: userID)
                vocabularyCards.append(card)
            }
            
            if !cards.isEmpty && isSessionActive, let roomID = currentRoomID {
                exchangeService.updateSessionStatistics(
                    roomID: roomID,
                    vocabulary: cards.count
                )
            }
        } catch {
            // Silent fail for vocabulary extraction
        }
    }
    
    /// Review a vocabulary card
    public func reviewVocabularyCard(_ card: VocabularyCard, correct: Bool) {
        guard let userID = userProfile?.userID else { return }
        exchangeService.reviewVocabulary(cardID: card.id, for: userID, correct: correct)
        
        // Reload vocabulary
        if let profile = exchangeService.getProfile(for: userID) {
            vocabularyCards = profile.savedVocabulary
            userProfile = profile
        }
    }
    
    /// Get vocabulary cards needing review
    public var vocabularyNeedingReview: [VocabularyCard] {
        vocabularyCards.filter { $0.needsReview }
    }
    
    // MARK: - Profile Management
    
    /// Load user profile
    public func loadProfile(for userID: UUID) {
        if let profile = exchangeService.getProfile(for: userID) {
            userProfile = profile
            vocabularyCards = profile.savedVocabulary
            selectedLanguage = profile.nativeLanguage
        }
    }
    
    /// Create or update profile
    public func updateProfile(_ profile: LanguageLearningProfile) {
        exchangeService.updateProfile(profile)
        userProfile = profile
    }
    
    /// Find language exchange partners
    public func findPartners(learningLanguage: String) {
        guard let userID = userProfile?.userID else { return }
        
        potentialPartners = exchangeService.findPartners(
            for: userID,
            learningLanguage: learningLanguage,
            interests: userProfile?.culturalInterests ?? []
        )
    }
    
    // MARK: - Helper Methods
    
    /// Get target languages for translation based on room participants
    private func getTargetLanguages() -> [String] {
        var languages = Set<String>()
        
        // First, try to get languages from user's learning profile
        if let profile = userProfile {
            // Add all languages the user is learning
            for goal in profile.learningLanguages {
                languages.insert(goal.languageCode)
            }
            // Add user's native language if different from selected
            if profile.nativeLanguage != selectedLanguage {
                languages.insert(profile.nativeLanguage)
            }
        }
        
        // If we have a session, also include participant languages
        if let session = currentSession {
            for participant in session.participants {
                languages.insert(participant.nativeLanguage)
                languages.formUnion(participant.learningLanguages)
            }
        }
        
        // Remove the current language we're speaking in
        languages.remove(selectedLanguage)
        
        // If still empty, default to common languages for demo purposes
        if languages.isEmpty {
            languages = ["es", "fr", "de", "ja", "zh"] // Spanish, French, German, Japanese, Chinese
            languages.remove(selectedLanguage)
        }
        
        return Array(languages)
    }
    
    /// Get current active language hint
    public var currentLanguageHint: String? {
        guard isSessionActive else { return nil }
        
        // Priority 1: Use the selected target language (what user wants to learn)
        if let language = Language.from(code: targetLanguage) {
            return "Now practicing: \(language.name) \(language.flag)"
        }
        
        // Priority 2: Fall back to session's active language
        if let session = currentSession,
           let activeLanguage = session.currentActiveLanguage,
           let language = Language.from(code: activeLanguage) {
            return "Now practicing: \(language.name) \(language.flag)"
        }
        
        return nil
    }
    
    /// Get session duration formatted
    public var sessionDuration: String {
        guard let session = currentSession else { return "0:00" }
        
        let minutes = Int(session.duration / 60)
        let seconds = Int(session.duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
