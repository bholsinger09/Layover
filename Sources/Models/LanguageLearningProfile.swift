import Foundation

/// User's language learning profile and preferences
public struct LanguageLearningProfile: LayoverModel {
    public let id: UUID
    public let userID: UUID
    public var nativeLanguage: String
    public var learningLanguages: [LanguningLanguageGoal]
    public var preferences: LearningPreferences
    public var achievements: [LearningAchievement]
    public var statistics: LearningStatistics
    public var savedVocabulary: [VocabularyCard]
    public var culturalInterests: [CulturalInterest]
    
    public init(
        id: UUID = UUID(),
        userID: UUID,
        nativeLanguage: String,
        learningLanguages: [LanguningLanguageGoal] = [],
        preferences: LearningPreferences = LearningPreferences(),
        achievements: [LearningAchievement] = [],
        statistics: LearningStatistics = LearningStatistics(),
        savedVocabulary: [VocabularyCard] = [],
        culturalInterests: [CulturalInterest] = []
    ) {
        self.id = id
        self.userID = userID
        self.nativeLanguage = nativeLanguage
        self.learningLanguages = learningLanguages
        self.preferences = preferences
        self.achievements = achievements
        self.statistics = statistics
        self.savedVocabulary = savedVocabulary
        self.culturalInterests = culturalInterests
    }
    
    /// Get learning goal for a specific language
    public func goal(for languageCode: String) -> LanguningLanguageGoal? {
        learningLanguages.first { $0.languageCode == languageCode }
    }
    
    /// Get vocabulary cards that need review
    public var vocabularyNeedingReview: [VocabularyCard] {
        savedVocabulary.filter { $0.needsReview }
    }
}

/// Language learning goal
public struct LanguningLanguageGoal: LayoverModel {
    public let id: UUID
    public let languageCode: String
    public var targetProficiency: ProficiencyLevel
    public var currentProficiency: ProficiencyLevel
    public var dailyGoalMinutes: Int
    public var startDate: Date
    public var targetDate: Date?
    public var motivations: [LearningMotivation]
    
    public init(
        id: UUID = UUID(),
        languageCode: String,
        targetProficiency: ProficiencyLevel,
        currentProficiency: ProficiencyLevel = .beginner,
        dailyGoalMinutes: Int = 30,
        startDate: Date = Date(),
        targetDate: Date? = nil,
        motivations: [LearningMotivation] = []
    ) {
        self.id = id
        self.languageCode = languageCode
        self.targetProficiency = targetProficiency
        self.currentProficiency = currentProficiency
        self.dailyGoalMinutes = dailyGoalMinutes
        self.startDate = startDate
        self.targetDate = targetDate
        self.motivations = motivations
    }
    
    /// Progress percentage (0.0 to 1.0)
    public var progress: Double {
        let current = currentProficiency.numericValue
        let target = targetProficiency.numericValue
        return min(current / target, 1.0)
    }
}

extension ProficiencyLevel {
    var numericValue: Double {
        switch self {
        case .beginner: return 1.0
        case .intermediate: return 2.0
        case .advanced: return 3.0
        case .native: return 4.0
        }
    }
}

/// Learning motivations
public enum LearningMotivation: String, Codable, Sendable, CaseIterable {
    case travel
    case career
    case family
    case entertainment
    case friends
    case culture
    case education
    case personal
    
    public var emoji: String {
        switch self {
        case .travel: return "✈️"
        case .career: return "💼"
        case .family: return "👨‍👩‍👧‍👦"
        case .entertainment: return "🎬"
        case .friends: return "👥"
        case .culture: return "🌏"
        case .education: return "🎓"
        case .personal: return "⭐"
        }
    }
}

/// Learning preferences
public struct LearningPreferences: Codable, Sendable, Hashable, Equatable {
    public var autoTranslate: Bool
    public var showOriginalWithTranslation: Bool
    public var autoSaveVocabulary: Bool
    public var showPronunciation: Bool
    public var showCulturalNotes: Bool
    public var preferredLearningMethod: LearningMethod
    public var vocabularyReminders: Bool
    public var dailyReminderTime: Date?
    
    public init(
        autoTranslate: Bool = true,
        showOriginalWithTranslation: Bool = true,
        autoSaveVocabulary: Bool = true,
        showPronunciation: Bool = true,
        showCulturalNotes: Bool = true,
        preferredLearningMethod: LearningMethod = .balanced,
        vocabularyReminders: Bool = true,
        dailyReminderTime: Date? = nil
    ) {
        self.autoTranslate = autoTranslate
        self.showOriginalWithTranslation = showOriginalWithTranslation
        self.autoSaveVocabulary = autoSaveVocabulary
        self.showPronunciation = showPronunciation
        self.showCulturalNotes = showCulturalNotes
        self.preferredLearningMethod = preferredLearningMethod
        self.vocabularyReminders = vocabularyReminders
        self.dailyReminderTime = dailyReminderTime
    }
}

/// Learning methods
public enum LearningMethod: String, Codable, Sendable, CaseIterable {
    case immersion // Full target language
    case balanced // Mix of both languages
    case comfortable // Mostly native with some target
    
    public var displayName: String {
        switch self {
        case .immersion: return "Full Immersion"
        case .balanced: return "Balanced Practice"
        case .comfortable: return "Comfort Zone"
        }
    }
    
    public var description: String {
        switch self {
        case .immersion:
            return "Speak only in your learning language for maximum exposure"
        case .balanced:
            return "Alternate between languages for structured practice"
        case .comfortable:
            return "Mostly your native language with gentle practice"
        }
    }
}

/// Learning achievements
public struct LearningAchievement: LayoverModel {
    public let id: UUID
    public let type: AchievementType
    public let title: String
    public let description: String
    public let earnedDate: Date
    public let languageCode: String?
    public let iconName: String
    
    public init(
        id: UUID = UUID(),
        type: AchievementType,
        title: String,
        description: String,
        earnedDate: Date = Date(),
        languageCode: String? = nil,
        iconName: String
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.earnedDate = earnedDate
        self.languageCode = languageCode
        self.iconName = iconName
    }
}

/// Achievement types
public enum AchievementType: String, Codable, Sendable {
    case firstSession
    case vocabularyMilestone
    case streakMilestone
    case proficiencyLevel
    case culturalExpert
    case socialButterfly
    
    public var emoji: String {
        switch self {
        case .firstSession: return "🌟"
        case .vocabularyMilestone: return "📚"
        case .streakMilestone: return "🔥"
        case .proficiencyLevel: return "🎓"
        case .culturalExpert: return "🌏"
        case .socialButterfly: return "🦋"
        }
    }
}

/// Learning statistics
public struct LearningStatistics: Codable, Sendable, Hashable, Equatable {
    public var totalPracticeMinutes: Int
    public var totalSessions: Int
    public var vocabularyLearned: Int
    public var languagesExchanged: Set<String>
    public var currentStreak: Int
    public var longestStreak: Int
    public var lastPracticeDate: Date?
    public var partnerCount: Int
    
    public init(
        totalPracticeMinutes: Int = 0,
        totalSessions: Int = 0,
        vocabularyLearned: Int = 0,
        languagesExchanged: Set<String> = [],
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastPracticeDate: Date? = nil,
        partnerCount: Int = 0
    ) {
        self.totalPracticeMinutes = totalPracticeMinutes
        self.totalSessions = totalSessions
        self.vocabularyLearned = vocabularyLearned
        self.languagesExchanged = languagesExchanged
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastPracticeDate = lastPracticeDate
        self.partnerCount = partnerCount
    }
    
    /// Update streak based on last practice date
    public mutating func updateStreak() {
        guard let lastDate = lastPracticeDate else {
            currentStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        if daysDifference == 0 {
            // Same day, maintain streak
            return
        } else if daysDifference == 1 {
            // Consecutive day, increment streak
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            // Streak broken
            currentStreak = 1
        }
        
        lastPracticeDate = Date()
    }
}
