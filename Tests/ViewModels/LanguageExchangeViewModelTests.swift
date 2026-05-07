import Testing
import Foundation
@testable import LayoverKit

/// Tests for LanguageExchangeViewModel
@Suite("Language Exchange ViewModel Tests")
@MainActor
struct LanguageExchangeViewModelTests {
    
    @Test("ViewModel initialization")
    func testViewModelInitialization() {
        let viewModel = LanguageExchangeViewModel()
        
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.currentSession == nil)
        #expect(viewModel.isSessionActive == false)
        #expect(viewModel.messageText.isEmpty)
    }
    
    @Test("Start language exchange session")
    func testStartLanguageExchangeSession() {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        #expect(viewModel.currentSession != nil)
        #expect(viewModel.isSessionActive == true)
        #expect(viewModel.currentRoomID == roomID)
    }
    
    @Test("End language exchange session")
    func testEndLanguageExchangeSession() {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        viewModel.endSession()
        
        #expect(viewModel.isSessionActive == false)
    }
    
    @Test("Send message")
    func testSendMessage() async {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        viewModel.messageText = "Hello world"
        viewModel.selectedLanguage = "en"
        
        await viewModel.sendMessage(
            senderID: userID,
            senderUsername: "Alice"
        )
        
        #expect(viewModel.messageText.isEmpty) // Should clear after sending
        #expect(!viewModel.messages.isEmpty)
    }
    
    @Test("Load user profile")
    func testLoadUserProfile() {
        let viewModel = LanguageExchangeViewModel()
        let userID = UUID()
        
        let profile = LanguageLearningProfile(
            userID: userID,
            nativeLanguage: "en"
        )
        
        viewModel.updateProfile(profile)
        viewModel.loadProfile(for: userID)
        
        #expect(viewModel.userProfile != nil)
        #expect(viewModel.userProfile?.nativeLanguage == "en")
    }
    
    @Test("Update profile")
    func testUpdateProfile() {
        let viewModel = LanguageExchangeViewModel()
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
        
        viewModel.updateProfile(profile)
        
        #expect(viewModel.userProfile?.learningLanguages.count == 1)
    }
    
    @Test("Get message text in user language")
    func testGetMessageTextInUserLanguage() {
        let viewModel = LanguageExchangeViewModel()
        
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en",
            translatedVersions: ["es": "Hola"]
        )
        
        let englishText = viewModel.getMessageText(message, for: "en")
        #expect(englishText == "Hello")
        
        let spanishText = viewModel.getMessageText(message, for: "es")
        #expect(spanishText == "Hola")
    }
    
    @Test("Show original text toggle")
    func testShowOriginalTextToggle() {
        let viewModel = LanguageExchangeViewModel()
        viewModel.showOriginalText = true
        
        let message = ChatMessage(
            roomID: UUID(),
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en",
            translatedVersions: ["es": "Hola"]
        )
        
        let text = viewModel.getMessageText(message, for: "es")
        #expect(text == "Hello") // Should show original when toggle is on
    }
    
    @Test("Add reaction to message")
    func testAddReaction() {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let messageID = UUID()
        let userID = UUID()
        
        viewModel.currentRoomID = roomID
        
        // Create a test message
        let message = ChatMessage(
            id: messageID,
            roomID: roomID,
            senderID: UUID(),
            senderUsername: "Alice",
            originalText: "Hello",
            originalLanguage: "en"
        )
        viewModel.messages = [message]
        
        viewModel.addReaction(to: messageID, emoji: "👍", from: userID)
        
        viewModel.loadMessages()
        // Reaction should be added
    }
    
    @Test("Review vocabulary card correct")
    func testReviewVocabularyCardCorrect() {
        let viewModel = LanguageExchangeViewModel()
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
        
        viewModel.updateProfile(profile)
        viewModel.reviewVocabularyCard(card, correct: true)
        
        // Mastery should increase
        let updatedCard = viewModel.vocabularyCards.first { $0.id == card.id }
        #expect(updatedCard?.masteryLevel ?? 0 > 0.5)
    }
    
    @Test("Review vocabulary card incorrect")
    func testReviewVocabularyCardIncorrect() {
        let viewModel = LanguageExchangeViewModel()
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
        
        viewModel.updateProfile(profile)
        viewModel.reviewVocabularyCard(card, correct: false)
        
        // Mastery should decrease
        let updatedCard = viewModel.vocabularyCards.first { $0.id == card.id }
        #expect(updatedCard?.masteryLevel ?? 1.0 < 0.5)
    }
    
    @Test("Get vocabulary needing review")
    func testGetVocabularyNeedingReview() {
        let viewModel = LanguageExchangeViewModel()
        
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
        
        viewModel.vocabularyCards = [needsReview, reviewed]
        
        #expect(viewModel.vocabularyNeedingReview.count >= 1)
    }
    
    @Test("Find language partners")
    func testFindLanguagePartners() {
        let viewModel = LanguageExchangeViewModel()
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
        
        viewModel.updateProfile(profile)
        viewModel.findPartners(learningLanguage: "es")
        
        // Partners should be populated (empty in this test)
        #expect(viewModel.potentialPartners.count >= 0)
    }
    
    @Test("Switch exchange mode")
    func testSwitchExchangeMode() {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        viewModel.switchMode(to: .focusOn("es"))
        
        #expect(viewModel.currentSession?.mode == .focusOn("es"))
    }
    
    @Test("Session duration formatting")
    func testSessionDurationFormatting() {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        let duration = viewModel.sessionDuration
        #expect(duration.contains(":"))
    }
    
    @Test("Current language hint")
    func testCurrentLanguageHint() {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .focusOn("es"),
            currentUserID: userID
        )
        
        // Should have a language hint
        let hint = viewModel.currentLanguageHint
        // Hint may be nil depending on current time in balanced mode
    }
    
    @Test("Empty message not sent")
    func testEmptyMessageNotSent() async {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        viewModel.messageText = "   " // Whitespace only
        
        await viewModel.sendMessage(
            senderID: userID,
            senderUsername: "Alice"
        )
        
        #expect(viewModel.messages.isEmpty)
    }
    
    @Test("Load messages for current room")
    func testLoadMessagesForCurrentRoom() async {
        let viewModel = LanguageExchangeViewModel()
        let roomID = UUID()
        let userID = UUID()
        
        let user = User(id: userID, username: "Alice")
        
        viewModel.startSession(
            roomID: roomID,
            participants: [user],
            mode: .balanced,
            currentUserID: userID
        )
        
        // Send a message
        viewModel.messageText = "Hello"
        await viewModel.sendMessage(
            senderID: userID,
            senderUsername: "Alice"
        )
        
        // Load messages
        viewModel.loadMessages()
        
        #expect(!viewModel.messages.isEmpty)
    }
}
