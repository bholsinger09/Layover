import Testing
import Foundation
@testable import LayoverKit

/// Tests for LanguageExchangeSession model
@Suite("Language Exchange Session Tests")
struct LanguageExchangeSessionTests {
    
    @Test("Session initialization")
    func testSessionInitialization() {
        let roomID = UUID()
        let participants = [
            LanguageExchangeParticipant(
                userID: UUID(),
                username: "Alice",
                nativeLanguage: "en",
                learningLanguages: ["es"]
            )
        ]
        
        let session = LanguageExchangeSession(
            roomID: roomID,
            participants: participants,
            mode: .balanced
        )
        
        #expect(session.roomID == roomID)
        #expect(session.participants.count == 1)
        #expect(session.mode == .balanced)
        #expect(session.isActive == true)
        #expect(session.vocabulary.isEmpty)
        #expect(session.culturalNotes.isEmpty)
    }
    
    @Test("Session is active when no end time")
    func testSessionIsActive() {
        let session = LanguageExchangeSession(
            roomID: UUID(),
            participants: [],
            mode: .balanced
        )
        
        #expect(session.isActive == true)
    }
    
    @Test("Session is not active when ended")
    func testSessionIsNotActiveWhenEnded() {
        let session = LanguageExchangeSession(
            roomID: UUID(),
            participants: [],
            mode: .balanced,
            endTime: Date()
        )
        
        #expect(session.isActive == false)
    }
    
    @Test("Session duration calculation")
    func testSessionDuration() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour later
        
        let session = LanguageExchangeSession(
            roomID: UUID(),
            participants: [],
            mode: .balanced,
            startTime: start,
            endTime: end
        )
        
        #expect(session.duration == 3600)
    }
    
    @Test("Exchange mode balanced")
    func testExchangeModeBalanced() {
        let mode = ExchangeMode.balanced
        #expect(mode.displayName == "Balanced Exchange")
    }
    
    @Test("Exchange mode focus")
    func testExchangeModeFocus() {
        let mode = ExchangeMode.focusOn("es")
        #expect(mode.displayName.contains("Focus"))
    }
    
    @Test("Exchange mode free")
    func testExchangeModeFree() {
        let mode = ExchangeMode.free
        #expect(mode.displayName == "Free Practice")
    }
    
    @Test("Session conforms to LayoverModel")
    func testSessionConformsToLayoverModel() {
        let session = LanguageExchangeSession(
            roomID: UUID(),
            participants: [],
            mode: .balanced
        )
        
        #expect(session.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
}

/// Tests for LanguageExchangeParticipant
@Suite("Language Exchange Participant Tests")
struct LanguageExchangeParticipantTests {
    
    @Test("Participant initialization")
    func testParticipantInitialization() {
        let userID = UUID()
        
        let participant = LanguageExchangeParticipant(
            userID: userID,
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es", "fr"]
        )
        
        #expect(participant.userID == userID)
        #expect(participant.username == "Alice")
        #expect(participant.nativeLanguage == "en")
        #expect(participant.learningLanguages.count == 2)
    }
    
    @Test("Participant proficiency level")
    func testParticipantProficiencyLevel() {
        let participant = LanguageExchangeParticipant(
            userID: UUID(),
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es"],
            proficiencyLevels: ["es": .intermediate]
        )
        
        #expect(participant.proficiency(for: "es") == .intermediate)
    }
    
    @Test("Participant default proficiency is beginner")
    func testParticipantDefaultProficiency() {
        let participant = LanguageExchangeParticipant(
            userID: UUID(),
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es"]
        )
        
        #expect(participant.proficiency(for: "es") == .beginner)
    }
}

/// Tests for VocabularyCard
@Suite("Vocabulary Card Tests")
struct VocabularyCardTests {
    
    @Test("VocabularyCard initialization")
    func testVocabularyCardInitialization() {
        let card = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "From chat with Maria"
        )
        
        #expect(card.word == "hola")
        #expect(card.translation == "hello")
        #expect(card.language == "es")
        #expect(card.targetLanguage == "en")
        #expect(card.masteryLevel == 0.0)
    }
    
    @Test("VocabularyCard needs review when never reviewed")
    func testVocabularyCardNeedsReviewWhenNeverReviewed() {
        let card = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test"
        )
        
        #expect(card.needsReview == true)
    }
    
    @Test("VocabularyCard needs review based on mastery level")
    func testVocabularyCardNeedsReviewBasedOnMastery() {
        // Low mastery - should need review sooner
        let lowMasteryCard = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test",
            lastReviewedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60), // 2 days ago
            masteryLevel: 0.2
        )
        
        #expect(lowMasteryCard.needsReview == true)
        
        // High mastery - can wait longer
        let highMasteryCard = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test",
            lastReviewedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60), // 2 days ago
            masteryLevel: 0.9
        )
        
        #expect(highMasteryCard.needsReview == false)
    }
    
    @Test("Vocabulary category display names")
    func testVocabularyCategoryDisplayNames() {
        #expect(VocabularyCategory.general.displayName == "General")
        #expect(VocabularyCategory.entertainment.displayName == "Entertainment")
        #expect(VocabularyCategory.slang.displayName == "Slang")
    }
    
    @Test("Difficulty level colors")
    func testDifficultyLevelColors() {
        #expect(DifficultyLevel.beginner.color == "green")
        #expect(DifficultyLevel.intermediate.color == "yellow")
        #expect(DifficultyLevel.advanced.color == "red")
    }
}

/// Tests for CulturalNote
@Suite("Cultural Note Tests")
struct CulturalNoteTests {
    
    @Test("CulturalNote initialization")
    func testCulturalNoteInitialization() {
        let note = CulturalNote(
            title: "Greeting customs",
            content: "In Japan, bowing is a common greeting",
            language: "ja",
            relatedWords: ["こんにちは", "おじぎ"],
            category: .etiquette
        )
        
        #expect(note.title == "Greeting customs")
        #expect(note.language == "ja")
        #expect(note.relatedWords.count == 2)
        #expect(note.category == .etiquette)
    }
    
    @Test("Cultural note category emojis")
    func testCulturalNoteCategoryEmojis() {
        #expect(CulturalNoteCategory.idiom.emoji == "💬")
        #expect(CulturalNoteCategory.food.emoji == "🍜")
        #expect(CulturalNoteCategory.holiday.emoji == "🎉")
    }
}

/// Tests for ProficiencyLevel
@Suite("Proficiency Level Tests")
struct ProficiencyLevelTests {
    
    @Test("Proficiency level display names")
    func testProficiencyLevelDisplayNames() {
        #expect(ProficiencyLevel.beginner.displayName == "A1-A2")
        #expect(ProficiencyLevel.intermediate.displayName == "B1-B2")
        #expect(ProficiencyLevel.advanced.displayName == "C1-C2")
        #expect(ProficiencyLevel.native.displayName == "Native")
    }
    
    @Test("Proficiency level descriptions")
    func testProficiencyLevelDescriptions() {
        #expect(!ProficiencyLevel.beginner.description.isEmpty)
        #expect(!ProficiencyLevel.intermediate.description.isEmpty)
        #expect(!ProficiencyLevel.advanced.description.isEmpty)
        #expect(!ProficiencyLevel.native.description.isEmpty)
    }
    
    @Test("Proficiency level numeric values")
    func testProficiencyLevelNumericValues() {
        #expect(ProficiencyLevel.beginner.numericValue == 1.0)
        #expect(ProficiencyLevel.intermediate.numericValue == 2.0)
        #expect(ProficiencyLevel.advanced.numericValue == 3.0)
        #expect(ProficiencyLevel.native.numericValue == 4.0)
    }
}

/// Tests for SessionStatistics
@Suite("Session Statistics Tests")
struct SessionStatisticsTests {
    
    @Test("SessionStatistics initialization")
    func testSessionStatisticsInitialization() {
        let stats = SessionStatistics()
        
        #expect(stats.messagesExchanged == 0)
        #expect(stats.vocabularyLearned == 0)
        #expect(stats.practiceMinutes == 0)
        #expect(stats.languagesUsed.isEmpty)
    }
    
    @Test("SessionStatistics with values")
    func testSessionStatisticsWithValues() {
        let stats = SessionStatistics(
            messagesExchanged: 50,
            vocabularyLearned: 10,
            practiceMinutes: 30,
            languagesUsed: ["en", "es"]
        )
        
        #expect(stats.messagesExchanged == 50)
        #expect(stats.vocabularyLearned == 10)
        #expect(stats.practiceMinutes == 30)
        #expect(stats.languagesUsed.count == 2)
    }
}
