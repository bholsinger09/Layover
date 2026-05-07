import Testing
import Foundation
@testable import LayoverKit

/// Tests for LanguageLearningProfile model
@Suite("Language Learning Profile Tests")
struct LanguageLearningProfileTests {
    
    @Test("Profile initialization")
    func testProfileInitialization() {
        let userID = UUID()
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        
        #expect(profile.userID == userID)
        #expect(profile.nativeLanguage == "en")
        #expect(profile.learningLanguages.isEmpty)
        #expect(profile.savedVocabulary.isEmpty)
    }
    
    @Test("Profile with learning languages")
    func testProfileWithLearningLanguages() {
        let goal = LanguningLanguageGoal(
            languageCode: "es",
            targetProficiency: .intermediate,
            currentProficiency: .beginner
        )
        
        let profile = LanguageLearningProfile(
            userID: UUID(),
            nativeLanguage: "en",
            learningLanguages: [goal]
        )
        
        #expect(profile.learningLanguages.count == 1)
        #expect(profile.goal(for: "es")?.languageCode == "es")
    }
    
    @Test("Profile vocabulary needing review")
    func testProfileVocabularyNeedingReview() {
        let needsReview = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test"
        )
        
        let reviewed = VocabularyCard(
            word: "adiós",
            translation: "goodbye",
            language: "es",
            targetLanguage: "en",
            context: "Test",
            lastReviewedAt: Date(),
            masteryLevel: 0.9
        )
        
        let profile = LanguageLearningProfile(
            userID: UUID(),
            nativeLanguage: "en",
            savedVocabulary: [needsReview, reviewed]
        )
        
        #expect(profile.vocabularyNeedingReview.count >= 1)
    }
    
    @Test("Profile conforms to LayoverModel")
    func testProfileConformsToLayoverModel() {
        let profile = LanguageLearningProfile(
            userID: UUID(),
            nativeLanguage: "en"
        )
        
        #expect(profile.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
}

/// Tests for LanguningLanguageGoal
@Suite("Language Goal Tests")
struct LanguageGoalTests {
    
    @Test("Language goal initialization")
    func testLanguageGoalInitialization() {
        let goal = LanguningLanguageGoal(
            languageCode: "es",
            targetProficiency: .advanced,
            currentProficiency: .beginner,
            dailyGoalMinutes: 30
        )
        
        #expect(goal.languageCode == "es")
        #expect(goal.targetProficiency == .advanced)
        #expect(goal.currentProficiency == .beginner)
        #expect(goal.dailyGoalMinutes == 30)
    }
    
    @Test("Language goal progress calculation")
    func testLanguageGoalProgress() {
        let goal = LanguningLanguageGoal(
            languageCode: "es",
            targetProficiency: .advanced,
            currentProficiency: .intermediate
        )
        
        // Intermediate (2.0) / Advanced (3.0) = 0.666...
        #expect(goal.progress > 0.6)
        #expect(goal.progress < 0.7)
    }
    
    @Test("Language goal progress caps at 1.0")
    func testLanguageGoalProgressCaps() {
        let goal = LanguningLanguageGoal(
            languageCode: "es",
            targetProficiency: .intermediate,
            currentProficiency: .native
        )
        
        #expect(goal.progress == 1.0)
    }
}

/// Tests for LearningPreferences
@Suite("Learning Preferences Tests")
struct LearningPreferencesTests {
    
    @Test("Default preferences")
    func testDefaultPreferences() {
        let prefs = LearningPreferences()
        
        #expect(prefs.autoTranslate == true)
        #expect(prefs.showOriginalWithTranslation == true)
        #expect(prefs.autoSaveVocabulary == true)
        #expect(prefs.showPronunciation == true)
        #expect(prefs.showCulturalNotes == true)
        #expect(prefs.preferredLearningMethod == .balanced)
    }
    
    @Test("Custom preferences")
    func testCustomPreferences() {
        let prefs = LearningPreferences(
            autoTranslate: false,
            preferredLearningMethod: .immersion
        )
        
        #expect(prefs.autoTranslate == false)
        #expect(prefs.preferredLearningMethod == .immersion)
    }
}

/// Tests for LearningMethod
@Suite("Learning Method Tests")
struct LearningMethodTests {
    
    @Test("Learning method display names")
    func testLearningMethodDisplayNames() {
        #expect(LearningMethod.immersion.displayName == "Full Immersion")
        #expect(LearningMethod.balanced.displayName == "Balanced Practice")
        #expect(LearningMethod.comfortable.displayName == "Comfort Zone")
    }
    
    @Test("Learning method descriptions")
    func testLearningMethodDescriptions() {
        #expect(!LearningMethod.immersion.description.isEmpty)
        #expect(!LearningMethod.balanced.description.isEmpty)
        #expect(!LearningMethod.comfortable.description.isEmpty)
    }
}

/// Tests for LearningAchievement
@Suite("Learning Achievement Tests")
struct LearningAchievementTests {
    
    @Test("Achievement initialization")
    func testAchievementInitialization() {
        let achievement = LearningAchievement(
            type: .firstSession,
            title: "First Steps",
            description: "Completed first session",
            iconName: "star.fill"
        )
        
        #expect(achievement.type == .firstSession)
        #expect(achievement.title == "First Steps")
        #expect(achievement.iconName == "star.fill")
    }
    
    @Test("Achievement type emojis")
    func testAchievementTypeEmojis() {
        #expect(AchievementType.firstSession.emoji == "🌟")
        #expect(AchievementType.vocabularyMilestone.emoji == "📚")
        #expect(AchievementType.streakMilestone.emoji == "🔥")
        #expect(AchievementType.proficiencyLevel.emoji == "🎓")
    }
}

/// Tests for LearningStatistics
@Suite("Learning Statistics Tests")
struct LearningStatisticsTests {
    
    @Test("Statistics initialization")
    func testStatisticsInitialization() {
        let stats = LearningStatistics()
        
        #expect(stats.totalPracticeMinutes == 0)
        #expect(stats.totalSessions == 0)
        #expect(stats.vocabularyLearned == 0)
        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 0)
    }
    
    @Test("Statistics streak update same day")
    func testStatisticsStreakUpdateSameDay() {
        var stats = LearningStatistics(
            currentStreak: 5,
            lastPracticeDate: Date()
        )
        
        stats.updateStreak()
        
        #expect(stats.currentStreak == 5) // Should maintain streak
    }
    
    @Test("Statistics streak update consecutive day")
    func testStatisticsStreakUpdateConsecutiveDay() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        var stats = LearningStatistics(
            currentStreak: 5,
            longestStreak: 5,
            lastPracticeDate: yesterday
        )
        
        stats.updateStreak()
        
        #expect(stats.currentStreak == 6)
        #expect(stats.longestStreak == 6)
    }
    
    @Test("Statistics streak broken")
    func testStatisticsStreakBroken() {
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        var stats = LearningStatistics(
            currentStreak: 10,
            longestStreak: 10,
            lastPracticeDate: twoDaysAgo
        )
        
        stats.updateStreak()
        
        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 10) // Longest streak preserved
    }
}

/// Tests for LearningMotivation
@Suite("Learning Motivation Tests")
struct LearningMotivationTests {
    
    @Test("Motivation emojis")
    func testMotivationEmojis() {
        #expect(LearningMotivation.travel.emoji == "✈️")
        #expect(LearningMotivation.career.emoji == "💼")
        #expect(LearningMotivation.entertainment.emoji == "🎬")
        #expect(LearningMotivation.culture.emoji == "🌏")
    }
    
    @Test("All motivations have emojis")
    func testAllMotivationsHaveEmojis() {
        for motivation in LearningMotivation.allCases {
            #expect(!motivation.emoji.isEmpty)
        }
    }
}
