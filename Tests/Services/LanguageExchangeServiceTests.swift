import Testing
import Foundation
@testable import LayoverKit

/// Tests for LanguageExchangeService
@Suite("Language Exchange Service Tests")
@MainActor
struct LanguageExchangeServiceTests {
    
    @Test("LanguageExchangeService initialization")
    func testLanguageExchangeServiceInitialization() {
        let service = LanguageExchangeService()
        #expect(service != nil)
    }
    
    @Test("Create and get user profile")
    func testCreateAndGetUserProfile() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        
        service.updateProfile(profile)
        
        let retrieved = service.getProfile(for: userID)
        #expect(retrieved?.userID == userID)
        #expect(retrieved?.nativeLanguage == "en")
    }
    
    @Test("Update existing profile")
    func testUpdateExistingProfile() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let profile1 = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        service.updateProfile(profile1)
        
        let goal = LanguningLanguageGoal(
            languageCode: "es",
            targetProficiency: .intermediate
        )
        
        let profile2 = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en",
            learningLanguages: [goal]
        )
        service.updateProfile(profile2)
        
        let retrieved = service.getProfile(for: userID)
        #expect(retrieved?.learningLanguages.count == 1)
    }
    
    @Test("Save vocabulary to profile")
    func testSaveVocabularyToProfile() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        service.updateProfile(profile)
        
        let card = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test"
        )
        
        service.saveVocabulary(card, for: userID)
        
        let retrieved = service.getProfile(for: userID)
        #expect(retrieved?.savedVocabulary.count == 1)
    }
    
    @Test("Don't save duplicate vocabulary")
    func testDontSaveDuplicateVocabulary() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        service.updateProfile(profile)
        
        let card = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test"
        )
        
        service.saveVocabulary(card, for: userID)
        service.saveVocabulary(card, for: userID)
        
        let retrieved = service.getProfile(for: userID)
        #expect(retrieved?.savedVocabulary.count == 1)
    }
    
    @Test("Review vocabulary updates mastery")
    func testReviewVocabularyUpdatesMastery() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let card = VocabularyCard(
            word: "hola",
            translation: "hello",
            language: "es",
            targetLanguage: "en",
            context: "Test",
            masteryLevel: 0.5
        )
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en",
            savedVocabulary: [card]
        )
        service.updateProfile(profile)
        
        // Review correctly
        service.reviewVocabulary(cardID: card.id, for: userID, correct: true)
        
        let retrieved = service.getProfile(for: userID)
        let reviewedCard = retrieved?.savedVocabulary.first { $0.id == card.id }
        
        #expect(reviewedCard?.masteryLevel ?? 0 > 0.5)
        #expect(reviewedCard?.lastReviewedAt != nil)
    }
    
    @Test("Start language exchange session")
    func testStartLanguageExchangeSession() {
        let service = LanguageExchangeService()
        let roomID = UUID()
        
        let participant = LanguageExchangeParticipant(
            userID: UUID(),
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es"]
        )
        
        let session = service.startSession(
            roomID: roomID,
            participants: [participant],
            mode: .balanced
        )
        
        #expect(session.roomID == roomID)
        #expect(session.participants.count == 1)
        #expect(session.isActive == true)
    }
    
    @Test("End language exchange session")
    func testEndLanguageExchangeSession() {
        let service = LanguageExchangeService()
        let roomID = UUID()
        let userID = UUID()
        
        let participant = LanguageExchangeParticipant(
            userID: userID,
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es"]
        )
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        service.updateProfile(profile)
        
        _ = service.startSession(
            roomID: roomID,
            participants: [participant],
            mode: .balanced
        )
        
        let endedSession = service.endSession(roomID: roomID)
        
        #expect(endedSession?.isActive == false)
        #expect(endedSession?.endTime != nil)
    }
    
    @Test("Get active session")
    func testGetActiveSession() {
        let service = LanguageExchangeService()
        let roomID = UUID()
        
        let participant = LanguageExchangeParticipant(
            userID: UUID(),
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es"]
        )
        
        _ = service.startSession(
            roomID: roomID,
            participants: [participant],
            mode: .balanced
        )
        
        let session = service.getSession(for: roomID)
        #expect(session != nil)
        #expect(session?.isActive == true)
    }
    
    @Test("Update session statistics")
    func testUpdateSessionStatistics() {
        let service = LanguageExchangeService()
        let roomID = UUID()
        
        let participant = LanguageExchangeParticipant(
            userID: UUID(),
            username: "Alice",
            nativeLanguage: "en",
            learningLanguages: ["es"]
        )
        
        _ = service.startSession(
            roomID: roomID,
            participants: [participant],
            mode: .balanced
        )
        
        service.updateSessionStatistics(roomID: roomID, messages: 10, vocabulary: 5)
        
        let session = service.getSession(for: roomID)
        #expect(session?.statistics.messagesExchanged == 10)
        #expect(session?.statistics.vocabularyLearned == 5)
    }
    
    @Test("Find language exchange partners")
    func testFindLanguageExchangePartners() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        // User learning Spanish
        let userProfile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en",
            learningLanguages: [
                LanguningLanguageGoal(
                    languageCode: "es",
                    targetProficiency: .intermediate
                )
            ]
        )
        service.updateProfile(userProfile)
        
        // Potential partner: Spanish native learning English
        let partnerID = UUID()
        let partnerProfile = LanguageLearningProfile(
            userID: partnerID,
            nativeLanguage: "es",
            learningLanguages: [
                LanguningLanguageGoal(
                    languageCode: "en",
                    targetProficiency: .intermediate
                )
            ]
        )
        service.updateProfile(partnerProfile)
        
        let partners = service.findPartners(
            for: userID,
            learningLanguage: "es"
        )
        
        #expect(partners.count == 1)
        #expect(partners.first?.userID == partnerID)
    }
    
    @Test("Don't match with self")
    func testDontMatchWithSelf() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en",
            learningLanguages: [
                LanguningLanguageGoal(
                    languageCode: "es",
                    targetProficiency: .intermediate
                )
            ]
        )
        service.updateProfile(profile)
        
        let partners = service.findPartners(
            for: userID,
            learningLanguage: "es"
        )
        
        #expect(!partners.contains { $0.userID == userID })
    }
    
    @Test("Match partners with shared interests")
    func testMatchPartnersWithSharedInterests() {
        let service = LanguageExchangeService()
        let userID = UUID()
        
        let userProfile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en",
            learningLanguages: [
                LanguningLanguageGoal(languageCode: "ja", targetProficiency: .intermediate)
            ],
            culturalInterests: [.anime, .jDrama]
        )
        service.updateProfile(userProfile)
        
        // Partner with shared interest
        let partner1ID = UUID()
        let partner1 = LanguageLearningProfile(
            userID: partner1ID,
            nativeLanguage: "ja",
            learningLanguages: [
                LanguningLanguageGoal(languageCode: "en", targetProficiency: .intermediate)
            ],
            culturalInterests: [.anime] // Shared interest
        )
        service.updateProfile(partner1)
        
        // Partner without shared interest
        let partner2ID = UUID()
        let partner2 = LanguageLearningProfile(
            userID: partner2ID,
            nativeLanguage: "ja",
            learningLanguages: [
                LanguningLanguageGoal(languageCode: "en", targetProficiency: .intermediate)
            ],
            culturalInterests: [.football] // No shared interest
        )
        service.updateProfile(partner2)
        
        let partners = service.findPartners(
            for: userID,
            learningLanguage: "ja",
            interests: [.anime, .jDrama]
        )
        
        // Partner with shared interest should be first
        #expect(partners.first?.userID == partner1ID)
    }
}
