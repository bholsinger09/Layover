import Foundation
import Observation

/// Service for managing language exchange sessions and matching
@Observable
public class LanguageExchangeService {
    private var activeSessions: [UUID: LanguageExchangeSession] = [:]
    private var userProfiles: [UUID: LanguageLearningProfile] = [:]
    
    public init() {}
    
    // MARK: - Profile Management
    
    /// Create or update learning profile
    public func updateProfile(_ profile: LanguageLearningProfile) {
        userProfiles[profile.userID] = profile
    }
    
    /// Get user's learning profile
    public func getProfile(for userID: UUID) -> LanguageLearningProfile? {
        userProfiles[userID]
    }
    
    /// Add vocabulary to user's saved collection
    public func saveVocabulary(_ card: VocabularyCard, for userID: UUID) {
        guard var profile = userProfiles[userID] else { return }
        
        // Avoid duplicates
        if !profile.savedVocabulary.contains(where: { $0.word == card.word && $0.language == card.language }) {
            profile.savedVocabulary.append(card)
            userProfiles[userID] = profile
        }
    }
    
    /// Review vocabulary card (update mastery)
    public func reviewVocabulary(cardID: UUID, for userID: UUID, correct: Bool) {
        guard var profile = userProfiles[userID],
              let index = profile.savedVocabulary.firstIndex(where: { $0.id == cardID }) else {
            return
        }
        
        var card = profile.savedVocabulary[index]
        
        // Update mastery level
        let adjustment = correct ? 0.1 : -0.05
        let newMastery = max(0.0, min(1.0, card.masteryLevel + adjustment))
        
        card = VocabularyCard(
            id: card.id,
            word: card.word,
            translation: card.translation,
            language: card.language,
            targetLanguage: card.targetLanguage,
            context: card.context,
            exampleSentence: card.exampleSentence,
            pronunciation: card.pronunciation,
            audioURL: card.audioURL,
            imageURL: card.imageURL,
            category: card.category,
            difficulty: card.difficulty,
            createdAt: card.createdAt,
            lastReviewedAt: Date(),
            masteryLevel: newMastery
        )
        
        profile.savedVocabulary[index] = card
        userProfiles[userID] = profile
    }
    
    // MARK: - Session Management
    
    /// Start a language exchange session in a room
    public func startSession(
        roomID: UUID,
        participants: [LanguageExchangeParticipant],
        mode: ExchangeMode
    ) -> LanguageExchangeSession {
        let session = LanguageExchangeSession(
            roomID: roomID,
            participants: participants,
            mode: mode
        )
        
        activeSessions[roomID] = session
        
        // Update statistics for all participants
        for participant in participants {
            updateSessionStatistics(for: participant.userID)
        }
        
        return session
    }
    
    /// End a session
    public func endSession(roomID: UUID) -> LanguageExchangeSession? {
        guard var session = activeSessions[roomID] else { return nil }
        
        session = LanguageExchangeSession(
            id: session.id,
            roomID: session.roomID,
            participants: session.participants,
            mode: session.mode,
            startTime: session.startTime,
            endTime: Date(),
            vocabulary: session.vocabulary,
            culturalNotes: session.culturalNotes,
            statistics: session.statistics
        )
        
        // Update participant statistics
        for participant in session.participants {
            updateLearningStatistics(
                for: participant.userID,
                session: session
            )
        }
        
        activeSessions[roomID] = nil
        return session
    }
    
    /// Get active session for a room
    public func getSession(for roomID: UUID) -> LanguageExchangeSession? {
        activeSessions[roomID]
    }
    
    /// Update session statistics
    public func updateSessionStatistics(roomID: UUID, messages: Int = 0, vocabulary: Int = 0) {
        guard var session = activeSessions[roomID] else { return }
        
        var stats = session.statistics
        stats.messagesExchanged += messages
        stats.vocabularyLearned += vocabulary
        
        let minutes = Int(session.duration / 60)
        stats.practiceMinutes = minutes
        
        session = LanguageExchangeSession(
            id: session.id,
            roomID: session.roomID,
            participants: session.participants,
            mode: session.mode,
            startTime: session.startTime,
            endTime: session.endTime,
            vocabulary: session.vocabulary,
            culturalNotes: session.culturalNotes,
            statistics: stats
        )
        
        activeSessions[roomID] = session
    }
    
    // MARK: - Matching
    
    /// Find potential language exchange partners
    public func findPartners(
        for userID: UUID,
        learningLanguage: String,
        targetProficiency: ProficiencyLevel? = nil,
        interests: [CulturalInterest] = []
    ) -> [LanguageLearningProfile] {
        guard let userProfile = userProfiles[userID] else { return [] }
        
        return userProfiles.values.filter { profile in
            // Don't match with self
            guard profile.userID != userID else { return false }
            
            // Partner should be learning user's native language
            let isLearningUsersNative = profile.learningLanguages.contains {
                $0.languageCode == userProfile.nativeLanguage
            }
            
            // Partner should speak the language user wants to learn
            let speaksTargetLanguage = profile.nativeLanguage == learningLanguage
            
            // Check proficiency match if specified
            var proficiencyMatch = true
            if let targetProf = targetProficiency,
               let partnerGoal = profile.learningLanguages.first(where: { $0.languageCode == userProfile.nativeLanguage }) {
                proficiencyMatch = partnerGoal.currentProficiency == targetProf
            }
            
            // Check shared interests
            let hasSharedInterests = interests.isEmpty || !Set(interests).intersection(Set(profile.culturalInterests)).isEmpty
            
            return isLearningUsersNative && speaksTargetLanguage && proficiencyMatch && hasSharedInterests
        }
        .sorted { p1, p2 in
            // Sort by shared interests count
            let shared1 = Set(p1.culturalInterests).intersection(Set(interests)).count
            let shared2 = Set(p2.culturalInterests).intersection(Set(interests)).count
            return shared1 > shared2
        }
    }
    
    /// Get recommended rooms for language practice
    public func recommendRooms(
        for userID: UUID,
        learningLanguage: String
    ) -> [RoomRecommendation] {
        // In production, this would query actual rooms
        // Mock implementation
        return []
    }
    
    // MARK: - Statistics
    
    private func updateSessionStatistics(for userID: UUID) {
        guard var profile = userProfiles[userID] else { return }
        
        var stats = profile.statistics
        stats.totalSessions += 1
        stats.updateStreak()
        
        profile = LanguageLearningProfile(
            id: profile.id,
            userID: profile.userID,
            nativeLanguage: profile.nativeLanguage,
            learningLanguages: profile.learningLanguages,
            preferences: profile.preferences,
            achievements: profile.achievements,
            statistics: stats,
            savedVocabulary: profile.savedVocabulary,
            culturalInterests: profile.culturalInterests
        )
        
        userProfiles[userID] = profile
    }
    
    private func updateLearningStatistics(for userID: UUID, session: LanguageExchangeSession) {
        guard var profile = userProfiles[userID] else { return }
        
        var stats = profile.statistics
        stats.totalPracticeMinutes += Int(session.duration / 60)
        stats.vocabularyLearned += session.statistics.vocabularyLearned
        stats.languagesExchanged.formUnion(session.statistics.languagesUsed)
        stats.partnerCount = Set(session.participants.map { $0.userID }).count - 1
        
        profile = LanguageLearningProfile(
            id: profile.id,
            userID: profile.userID,
            nativeLanguage: profile.nativeLanguage,
            learningLanguages: profile.learningLanguages,
            preferences: profile.preferences,
            achievements: checkAchievements(for: profile, stats: stats),
            statistics: stats,
            savedVocabulary: profile.savedVocabulary,
            culturalInterests: profile.culturalInterests
        )
        
        userProfiles[userID] = profile
    }
    
    private func checkAchievements(for profile: LanguageLearningProfile, stats: LearningStatistics) -> [LearningAchievement] {
        var achievements = profile.achievements
        
        // First session achievement
        if stats.totalSessions == 1 && !achievements.contains(where: { $0.type == .firstSession }) {
            achievements.append(LearningAchievement(
                type: .firstSession,
                title: "First Exchange",
                description: "Completed your first language exchange session",
                iconName: "star.fill"
            ))
        }
        
        // Vocabulary milestones
        let vocabMilestones = [10, 50, 100, 500, 1000]
        for milestone in vocabMilestones {
            if stats.vocabularyLearned >= milestone && !achievements.contains(where: {
                $0.type == .vocabularyMilestone && $0.description.contains("\(milestone)")
            }) {
                achievements.append(LearningAchievement(
                    type: .vocabularyMilestone,
                    title: "Word Master",
                    description: "Learned \(milestone) vocabulary words",
                    iconName: "book.fill"
                ))
            }
        }
        
        // Streak milestones
        let streakMilestones = [7, 30, 100, 365]
        for milestone in streakMilestones {
            if stats.currentStreak >= milestone && !achievements.contains(where: {
                $0.type == .streakMilestone && $0.description.contains("\(milestone)")
            }) {
                achievements.append(LearningAchievement(
                    type: .streakMilestone,
                    title: "Consistency King",
                    description: "\(milestone)-day practice streak",
                    iconName: "flame.fill"
                ))
            }
        }
        
        return achievements
    }
}

/// Room recommendation for language practice
public struct RoomRecommendation {
    public let roomID: UUID
    public let roomName: String
    public let language: String
    public let participantCount: Int
    public let matchScore: Double // 0.0 to 1.0
    
    public init(roomID: UUID, roomName: String, language: String, participantCount: Int, matchScore: Double) {
        self.roomID = roomID
        self.roomName = roomName
        self.language = language
        self.participantCount = participantCount
        self.matchScore = matchScore
    }
}
