import Foundation

/// Represents a language exchange session between users
public struct LanguageExchangeSession: LayoverModel {
    public let id: UUID
    public let roomID: UUID
    public let participants: [LanguageExchangeParticipant]
    public let mode: ExchangeMode
    public let startTime: Date
    public let endTime: Date?
    public let vocabulary: [VocabularyCard]
    public let culturalNotes: [CulturalNote]
    public let statistics: SessionStatistics
    
    public init(
        id: UUID = UUID(),
        roomID: UUID,
        participants: [LanguageExchangeParticipant],
        mode: ExchangeMode = .balanced,
        startTime: Date = Date(),
        endTime: Date? = nil,
        vocabulary: [VocabularyCard] = [],
        culturalNotes: [CulturalNote] = [],
        statistics: SessionStatistics = SessionStatistics()
    ) {
        self.id = id
        self.roomID = roomID
        self.participants = participants
        self.mode = mode
        self.startTime = startTime
        self.endTime = endTime
        self.vocabulary = vocabulary
        self.culturalNotes = culturalNotes
        self.statistics = statistics
    }
    
    /// Get current active language based on mode and time
    public var currentActiveLanguage: String? {
        switch mode {
        case .balanced:
            // Alternate every 15 minutes
            let elapsed = Date().timeIntervalSince(startTime)
            let interval = 15 * 60.0 // 15 minutes
            let index = Int(elapsed / interval) % participants.count
            return participants[safe: index]?.nativeLanguage
        case .focusOn(let languageCode):
            return languageCode
        case .free:
            return nil
        }
    }
    
    /// Check if session is active
    public var isActive: Bool {
        endTime == nil
    }
    
    /// Duration of session
    public var duration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
}

/// Exchange mode determines how languages are practiced
public enum ExchangeMode: Codable, Sendable, Equatable, Hashable {
    case balanced // Alternate between languages
    case focusOn(String) // Focus on one language (code)
    case free // No restrictions
    
    public var displayName: String {
        switch self {
        case .balanced:
            return "Balanced Exchange"
        case .focusOn(let code):
            return "Focus on \(Language.from(code: code)?.name ?? code)"
        case .free:
            return "Free Practice"
        }
    }
}

/// Participant in a language exchange session
public struct LanguageExchangeParticipant: LayoverModel {
    public let id: UUID
    public let userID: UUID
    public let username: String
    public let nativeLanguage: String
    public let learningLanguages: [String]
    public let proficiencyLevels: [String: ProficiencyLevel]
    public let interests: [CulturalInterest]
    
    public init(
        id: UUID = UUID(),
        userID: UUID,
        username: String,
        nativeLanguage: String,
        learningLanguages: [String],
        proficiencyLevels: [String: ProficiencyLevel] = [:],
        interests: [CulturalInterest] = []
    ) {
        self.id = id
        self.userID = userID
        self.username = username
        self.nativeLanguage = nativeLanguage
        self.learningLanguages = learningLanguages
        self.proficiencyLevels = proficiencyLevels
        self.interests = interests
    }
    
    /// Get proficiency level for a language
    public func proficiency(for languageCode: String) -> ProficiencyLevel {
        proficiencyLevels[languageCode] ?? .beginner
    }
}

/// Language proficiency levels
public enum ProficiencyLevel: String, Codable, Sendable, CaseIterable {
    case beginner = "A1-A2"
    case intermediate = "B1-B2"
    case advanced = "C1-C2"
    case native = "Native"
    
    public var displayName: String {
        rawValue
    }
    
    public var description: String {
        switch self {
        case .beginner:
            return "Basic phrases and simple conversations"
        case .intermediate:
            return "Can discuss familiar topics comfortably"
        case .advanced:
            return "Fluent in most situations"
        case .native:
            return "Native or near-native fluency"
        }
    }
}

/// Vocabulary card from content
public struct VocabularyCard: LayoverModel {
    public let id: UUID
    public let word: String
    public let translation: String
    public let language: String
    public let targetLanguage: String
    public let context: String // Where it appeared
    public let exampleSentence: String?
    public let pronunciation: String?
    public let audioURL: URL?
    public let imageURL: URL?
    public let category: VocabularyCategory
    public let difficulty: DifficultyLevel
    public let createdAt: Date
    public let lastReviewedAt: Date?
    public let masteryLevel: Double // 0.0 to 1.0
    
    public init(
        id: UUID = UUID(),
        word: String,
        translation: String,
        language: String,
        targetLanguage: String,
        context: String,
        exampleSentence: String? = nil,
        pronunciation: String? = nil,
        audioURL: URL? = nil,
        imageURL: URL? = nil,
        category: VocabularyCategory = .general,
        difficulty: DifficultyLevel = .intermediate,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        masteryLevel: Double = 0.0
    ) {
        self.id = id
        self.word = word
        self.translation = translation
        self.language = language
        self.targetLanguage = targetLanguage
        self.context = context
        self.exampleSentence = exampleSentence
        self.pronunciation = pronunciation
        self.audioURL = audioURL
        self.imageURL = imageURL
        self.category = category
        self.difficulty = difficulty
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.masteryLevel = masteryLevel
    }
    
    /// Check if card needs review (spaced repetition)
    public var needsReview: Bool {
        guard let lastReview = lastReviewedAt else { return true }
        let daysSinceReview = Date().timeIntervalSince(lastReview) / (24 * 60 * 60)
        
        // Spaced repetition intervals based on mastery
        let reviewInterval: Double = {
            if masteryLevel < 0.3 { return 1 } // Review daily
            if masteryLevel < 0.6 { return 3 } // Review every 3 days
            if masteryLevel < 0.8 { return 7 } // Review weekly
            return 14 // Review bi-weekly
        }()
        
        return daysSinceReview >= reviewInterval
    }
}

/// Vocabulary categories
public enum VocabularyCategory: String, Codable, Sendable, CaseIterable {
    case general
    case entertainment
    case emotions
    case slang
    case idioms
    case sports
    case food
    case travel
    case technology
    case business
    
    public var displayName: String {
        rawValue.capitalized
    }
}

/// Difficulty levels for vocabulary
public enum DifficultyLevel: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    
    public var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "yellow"
        case .advanced: return "red"
        }
    }
}

/// Cultural note attached to content
public struct CulturalNote: LayoverModel {
    public let id: UUID
    public let title: String
    public let content: String
    public let language: String
    public let relatedWords: [String]
    public let timestamp: TimeInterval? // When in video/content this appears
    public let category: CulturalNoteCategory
    
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        language: String,
        relatedWords: [String] = [],
        timestamp: TimeInterval? = nil,
        category: CulturalNoteCategory = .general
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.language = language
        self.relatedWords = relatedWords
        self.timestamp = timestamp
        self.category = category
    }
}

/// Categories for cultural notes
public enum CulturalNoteCategory: String, Codable, Sendable, CaseIterable {
    case general
    case idiom
    case gesture
    case etiquette
    case history
    case food
    case holiday
    case tradition
    
    public var emoji: String {
        switch self {
        case .general: return "ℹ️"
        case .idiom: return "💬"
        case .gesture: return "👋"
        case .etiquette: return "🎩"
        case .history: return "📚"
        case .food: return "🍜"
        case .holiday: return "🎉"
        case .tradition: return "🏮"
        }
    }
}

/// Session statistics
public struct SessionStatistics: Codable, Sendable, Hashable, Equatable {
    public var messagesExchanged: Int
    public var vocabularyLearned: Int
    public var practiceMinutes: Int
    public var languagesUsed: Set<String>
    
    public init(
        messagesExchanged: Int = 0,
        vocabularyLearned: Int = 0,
        practiceMinutes: Int = 0,
        languagesUsed: Set<String> = []
    ) {
        self.messagesExchanged = messagesExchanged
        self.vocabularyLearned = vocabularyLearned
        self.practiceMinutes = practiceMinutes
        self.languagesUsed = languagesUsed
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
