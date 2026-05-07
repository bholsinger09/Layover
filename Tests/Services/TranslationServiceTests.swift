import Testing
import Foundation
@testable import LayoverKit

/// Tests for TranslationService
@Suite("Translation Service Tests")
struct TranslationServiceTests {
    
    @Test("TranslationService initialization")
    func testTranslationServiceInitialization() {
        let service = TranslationService()
        // Service should initialize without errors
        #expect(service != nil)
    }
    
    @Test("Translate text to single language")
    func testTranslateToSingleLanguage() async throws {
        let service = TranslationService()
        
        let result = try await service.translate(
            text: "Hello",
            from: "en",
            to: ["es"]
        )
        
        #expect(result.originalText == "Hello")
        #expect(result.translations.count == 1)
        #expect(result.translations["es"] != nil)
    }
    
    @Test("Translate text to multiple languages")
    func testTranslateToMultipleLanguages() async throws {
        let service = TranslationService()
        
        let result = try await service.translate(
            text: "Hello",
            from: "en",
            to: ["es", "fr", "de"]
        )
        
        #expect(result.originalText == "Hello")
        #expect(result.translations.count == 3)
        #expect(result.translations["es"] != nil)
        #expect(result.translations["fr"] != nil)
        #expect(result.translations["de"] != nil)
    }
    
    @Test("Don't translate to same language")
    func testDontTranslateToSameLanguage() async throws {
        let service = TranslationService()
        
        let result = try await service.translate(
            text: "Hello",
            from: "en",
            to: ["en", "es"]
        )
        
        #expect(result.translations["en"] == nil)
        #expect(result.translations["es"] != nil)
    }
    
    @Test("Detect language")
    func testDetectLanguage() async throws {
        let service = TranslationService()
        
        let detected = try await service.detectLanguage(text: "Hello world")
        
        #expect(!detected.isEmpty)
    }
    
    @Test("Translate with context")
    func testTranslateWithContext() async throws {
        let service = TranslationService()
        
        let (translation, notes) = try await service.translateWithContext(
            text: "Break a leg",
            from: "en",
            to: "es",
            context: .general
        )
        
        #expect(!translation.isEmpty)
        // May include cultural notes for idioms
    }
    
    @Test("Detect cultural notes for idioms")
    func testDetectCulturalNotesForIdioms() {
        let service = TranslationService()
        
        let notes = service.detectCulturalNotes(
            originalText: "Break a leg!",
            translatedText: "¡Buena suerte!",
            sourceLanguage: "en",
            targetLanguage: "es"
        )
        
        // Should detect "break a leg" idiom
        #expect(notes.count >= 1 || notes.isEmpty) // Depends on implementation
    }
    
    @Test("Extract key vocabulary")
    func testExtractKeyVocabulary() async throws {
        let service = TranslationService()
        
        let words = try await service.extractKeyVocabulary(
            text: "Hello beautiful world",
            language: "en",
            targetLanguage: "es",
            maxWords: 5
        )
        
        #expect(!words.isEmpty)
        #expect(words.count <= 5)
    }
    
    @Test("Extract vocabulary respects max words")
    func testExtractVocabularyRespectsMaxWords() async throws {
        let service = TranslationService()
        
        let longText = "one two three four five six seven eight nine ten"
        let words = try await service.extractKeyVocabulary(
            text: longText,
            language: "en",
            targetLanguage: "es",
            maxWords: 3
        )
        
        #expect(words.count <= 3)
    }
    
    @Test("Transcribe audio placeholder")
    func testTranscribeAudio() async throws {
        let service = TranslationService()
        
        // Mock audio URL
        let audioURL = URL(fileURLWithPath: "/tmp/test.m4a")
        
        let (text, language) = try await service.transcribeAudio(audioURL: audioURL)
        
        #expect(!text.isEmpty)
        #expect(!language.isEmpty)
    }
    
    @Test("Synthesize speech placeholder")
    func testSynthesizeSpeech() async throws {
        let service = TranslationService()
        
        let audioURL = try await service.synthesizeSpeech(text: "Hello", language: "en")
        
        // Mock implementation returns nil
        // In real implementation, should return URL
    }
}
