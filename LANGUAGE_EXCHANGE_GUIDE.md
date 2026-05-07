# Language Exchange Mode - Implementation Guide

## Overview
The Language Exchange Mode is a comprehensive feature that enables users to learn and practice languages together while watching content, listening to music, or playing games. This guide covers integration, usage, and customization.

## 🎯 Features

### Core Capabilities
- **Real-time Translation**: Chat messages automatically translate to each participant's preferred language
- **Language Exchange Sessions**: Structured practice sessions with customizable modes
- **Vocabulary Learning**: Auto-extraction and spaced repetition flashcards
- **Cultural Notes**: Context-aware cultural explanations for idioms and customs
- **Progress Tracking**: Statistics, achievements, and learning streaks
- **Smart Matching**: Find language partners based on interests and proficiency

### Exchange Modes
1. **Balanced Mode**: Alternates between languages every 15 minutes
2. **Focus Mode**: Practice one specific language exclusively
3. **Free Practice**: Speak whatever language you prefer

## 📦 Components

### Models (Sources/Models/)
- `ChatMessage.swift` - Chat messages with translation support
- `LanguageExchangeSession.swift` - Exchange sessions and vocabulary cards
- `LanguageLearningProfile.swift` - User learning profiles and goals
- `User.swift` - Updated with language profile reference
- `Room.swift` - Updated with language exchange support

### Services (Sources/Services/)
- `ChatService.swift` - Message handling and translation
- `TranslationService.swift` - Translation API integration
- `LanguageExchangeService.swift` - Session and profile management

### ViewModels (Sources/ViewModels/)
- `LanguageExchangeViewModel.swift` - Main view model for the feature

### Views (Sources/Views/)
- `LanguageExchangeView.swift` - Main chat and exchange interface
- `VocabularyFlashcardsView.swift` - Vocabulary review
- `LanguageLearningProfileView.swift` - Profile setup and editing
- `LanguageExchangeSettingsView.swift` - Session settings

## 🚀 Integration

### Step 1: Add to Room View
Add a button to enable Language Exchange mode in your room view:

```swift
import SwiftUI

struct YourRoomView: View {
    let room: Room
    let currentUser: User
    @State private var showLanguageExchange = false
    
    var body: some View {
        // Your existing room UI
        
        // Add Language Exchange button
        Button {
            showLanguageExchange = true
        } label: {
            Label("Language Exchange", systemImage: "globe")
        }
        .sheet(isPresented: $showLanguageExchange) {
            LanguageExchangeView(room: room, currentUser: currentUser)
        }
    }
}
```

### Step 2: Add to ContentView Navigation
Add Language Exchange to your main navigation:

```swift
// In ContentView or main navigation
NavigationLink {
    // Show language exchange enabled rooms
    RoomListView(filter: { $0.languageExchangeEnabled })
} label: {
    Label("Language Exchange", systemImage: "globe")
}
```

### Step 3: Update Room Creation
Allow users to enable language exchange when creating rooms:

```swift
// In CreateRoomView
@State private var enableLanguageExchange = false

// Add toggle
Toggle("Enable Language Exchange", isOn: $enableLanguageExchange)

// When creating room:
let room = Room(
    name: roomName,
    hostID: currentUser.id,
    activityType: selectedActivity,
    primaryLanguage: selectedLanguage,
    supportedLanguages: additionalLanguages,
    languageExchangeEnabled: enableLanguageExchange
)
```

### Step 4: Initialize Services on App Launch
In your main app file:

```swift
// LayoverApp.swift or LayoverMacApp.swift
import SwiftUI

@main
struct LayoverApp: App {
    @State private var languageExchangeService = LanguageExchangeService()
    @State private var chatService = ChatService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(languageExchangeService)
                .environment(chatService)
        }
    }
}
```

## 📱 Platform-Specific Considerations

### iOS
- All views are optimized for iPhone and iPad
- Uses native iOS controls (sheets, navigation)
- Supports both portrait and landscape orientations

### macOS
- Views adapt to larger screen sizes
- Uses macOS-appropriate navigation
- Keyboard shortcuts available for common actions

### tvOS
- Simplified UI for TV remote navigation
- Focus management for directional controls
- Voice input support for chat messages

## 🔧 Customization

### Translation API Integration
Update `TranslationService.swift` to use your preferred translation API:

```swift
// In TranslationService.swift
public func translate(text: String, from sourceLanguage: String, to targetLanguages: [String]) async throws -> TranslationResult {
    // Option 1: Apple Translation (iOS 15+)
    // Use NLLanguageRecognizer and local translation
    
    // Option 2: Cloud Service (Google, DeepL, Azure)
    // Implement your API calls here
    
    // Option 3: Custom ML Model
    // Use Core ML for offline translation
}
```

### Vocabulary Extraction
Enhance vocabulary extraction with NLP:

```swift
// In ChatService.swift
public func extractVocabulary(...) async throws -> [VocabularyCard] {
    // Use Natural Language framework
    let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
    tagger.string = message.originalText
    
    // Extract nouns, verbs, adjectives
    // Filter by frequency and importance
    // Create vocabulary cards
}
```

### Cultural Notes Database
Add cultural context data:

```swift
// In TranslationService.swift
// Expand knownIdioms dictionary with more languages and expressions
private let knownIdioms: [String: [Idiom]] = [
    "en": [...],
    "es": [...],
    "ja": [...],
    // Add more languages
]
```

## 💡 Usage Examples

### Example 1: K-Drama Watch Party with Language Exchange
```swift
// Create a room for K-Drama watching
let room = Room(
    name: "Crash Landing on You - Learn Korean 🇰🇷",
    hostID: currentUser.id,
    activityType: .appleTVPlus,
    primaryLanguage: "ko",
    supportedLanguages: ["en", "ja"],
    languageExchangeEnabled: true,
    tags: ["kdrama", "korean", "language-learning"]
)

// Start language exchange session
let viewModel = LanguageExchangeViewModel()
viewModel.startSession(
    roomID: room.id,
    participants: room.participants,
    mode: .focusOn("ko"), // Focus on Korean
    currentUserID: currentUser.id
)
```

### Example 2: Anime Watch Party (Japanese Learning)
```swift
let room = Room(
    name: "Demon Slayer - Japanese Practice 🇯🇵",
    hostID: currentUser.id,
    activityType: .appleTVPlus,
    primaryLanguage: "ja",
    supportedLanguages: ["en"],
    languageExchangeEnabled: true,
    tags: ["anime", "japanese", "language-exchange"]
)
```

### Example 3: Multilingual Gaming Session
```swift
let room = Room(
    name: "Chess - Polyglot Practice 🌍",
    hostID: currentUser.id,
    activityType: .chess,
    primaryLanguage: "en",
    supportedLanguages: ["es", "fr", "de", "pt"],
    languageExchangeEnabled: true,
    tags: ["multilingual", "chess", "practice"]
)
```

## 🎨 UI Customization

### Theme Colors
Customize colors in each view:

```swift
// In LanguageExchangeView.swift
// Change accent colors
.foregroundStyle(.blue) // Change to your app's accent color

// In MessageBubbleView
.background(isCurrentUser ? Color.blue : Color(.systemGray5))
// Customize message bubble colors
```

### Fonts and Typography
```swift
// In VocabularyFlashcardsView
.font(.system(size: 36, weight: .bold)) // Customize flashcard font
```

## 📊 Analytics & Tracking

Track language exchange usage:

```swift
// Add analytics events
func trackLanguageExchangeStart(session: LanguageExchangeSession) {
    // Your analytics service
    Analytics.track("language_exchange_started", properties: [
        "mode": session.mode.displayName,
        "participants": session.participants.count,
        "languages": session.statistics.languagesUsed
    ])
}

func trackVocabularyLearned(card: VocabularyCard) {
    Analytics.track("vocabulary_learned", properties: [
        "word": card.word,
        "language": card.language,
        "difficulty": card.difficulty.rawValue
    ])
}
```

## 🔐 Privacy & Security

### Data Handling
- All chat messages are stored locally by default
- Translation happens client-side when possible
- User language profiles are private by default
- Vocabulary cards are user-specific

### Permissions
Required permissions:
- **Speech Recognition** (optional): For voice translation
- **Microphone** (optional): For voice messages

## 🧪 Testing

### Unit Tests
```swift
// Test translation service
func testTranslation() async throws {
    let service = TranslationService()
    let result = try await service.translate(
        text: "Hello",
        from: "en",
        to: ["es", "fr"]
    )
    XCTAssertEqual(result.translations.count, 2)
}

// Test vocabulary extraction
func testVocabularyExtraction() async throws {
    let chatService = ChatService()
    let message = ChatMessage(
        roomID: UUID(),
        senderID: UUID(),
        senderUsername: "Test",
        originalText: "Hello world",
        originalLanguage: "en"
    )
    
    let cards = try await chatService.extractVocabulary(
        from: message,
        targetLanguage: "es"
    )
    XCTAssertFalse(cards.isEmpty)
}
```

### UI Tests
```swift
func testLanguageExchangeFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to language exchange
    app.buttons["Language Exchange"].tap()
    
    // Start session
    app.buttons["Start Session"].tap()
    
    // Send message
    app.textFields["Type a message"].tap()
    app.textFields["Type a message"].typeText("Hello")
    app.buttons["Send"].tap()
    
    // Verify message appears
    XCTAssertTrue(app.staticTexts["Hello"].exists)
}
```

## 🚀 Future Enhancements

Potential additions:
1. **Voice Chat Translation**: Real-time voice translation during calls
2. **AI Language Tutor**: GPT-powered conversation practice
3. **Pronunciation Scoring**: Speech recognition for accent improvement
4. **Group Challenges**: Collaborative learning goals
5. **Language Exchange Marketplace**: Find partners by scheduling
6. **Content-Synced Subtitles**: Interactive subtitles with word lookup
7. **Grammar Explanations**: Context-aware grammar tips
8. **Native Speaker Verification**: Badge for native speakers

## 📞 Support

For questions or issues:
- Check existing language and cultural event models
- Review the GLOBAL_FEATURES_GUIDE.md for related features
- Test with the preview providers in each view file

## 🎉 Best Practices

1. **Onboarding**: Guide new users to set up their learning profile first
2. **Notifications**: Remind users about vocabulary review
3. **Gamification**: Use achievements to encourage regular practice
4. **Social Features**: Highlight successful language exchange stories
5. **Content Recommendations**: Suggest content matching user's learning level

## 📝 Localization

The feature supports 10 languages out of the box:
- English, Spanish, Mandarin Chinese, Hindi
- Arabic, Portuguese, French, German
- Japanese, Korean

Add more languages by updating:
- `Language.swift` - Add language definitions
- `TranslationService.swift` - Add idioms and cultural notes
- Localizable.strings files for UI text

---

**Happy Language Learning! 🌍📚**
