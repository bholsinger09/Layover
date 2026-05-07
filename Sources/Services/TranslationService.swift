import Foundation
import NaturalLanguage

/// Service for translating text between languages
public class TranslationService {
    
    /// Initialize translation service
    public init() {}
    
    // MARK: - Translation
    
    /// Translate text to multiple target languages
    public func translate(text: String, from sourceLanguage: String, to targetLanguages: [String]) async throws -> TranslationResult {
        var translations: [String: String] = [:]
        
        for targetLang in targetLanguages {
            if targetLang != sourceLanguage {
                translations[targetLang] = try await translateText(text, from: sourceLanguage, to: targetLang)
            }
        }
        
        return TranslationResult(
            originalText: text,
            translations: translations,
            detectedLanguage: sourceLanguage
        )
    }
    
    /// Translate text to a single target language
    private func translateText(_ text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        // Use comprehensive dictionary-based translation
        let translationKey = "\(sourceLanguage)-\(targetLanguage)"
        
        // Check if we have a direct translation
        if let dictionary = TranslationDictionaries.dictionary(from: sourceLanguage, to: targetLanguage),
           let translation = dictionary[text.lowercased()] {
            // Preserve original capitalization pattern
            return preserveCapitalization(original: text, translation: translation)
        }
        
        // Try word-by-word translation for unknown phrases
        let words = text.components(separatedBy: .whitespaces)
        var translatedWords: [String] = []
        
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if let dictionary = TranslationDictionaries.dictionary(from: sourceLanguage, to: targetLanguage),
               let translation = dictionary[cleanWord.lowercased()] {
                translatedWords.append(preserveCapitalization(original: cleanWord, translation: translation))
                // Add back punctuation if it existed
                if word != cleanWord {
                    let punct = word.filter { $0.isPunctuation }
                    if !punct.isEmpty, let last = translatedWords.last {
                        translatedWords[translatedWords.count - 1] = last + punct
                    }
                }
            } else {
                // Keep original word if no translation found
                translatedWords.append(word)
            }
        }
        
        let result = translatedWords.joined(separator: " ")
        
        // If we couldn't translate anything, note that it's untranslated
        return result == text ? "[\(Language.from(code: targetLanguage)?.name ?? targetLanguage)] \(text)" : result
    }
    
    /// Preserve capitalization pattern from original to translation
    private func preserveCapitalization(original: String, translation: String) -> String {
        guard !original.isEmpty else { return translation }
        
        if original.first?.isUppercase == true {
            return translation.prefix(1).uppercased() + translation.dropFirst()
        }
        return translation
    }
    
    /// Detect language of text
    public func detectLanguage(text: String) async throws -> String {
        // In production, use NLLanguageRecognizer or cloud API
        // For now, return default
        return "en"
    }
    
    // MARK: - Voice Translation
    
    /// Transcribe audio to text
    public func transcribeAudio(audioURL: URL) async throws -> (text: String, language: String) {
        // In production, use Speech framework or cloud API
        // Mock implementation
        return ("Transcribed text", "en")
    }
    
    /// Synthesize translated text to speech
    public func synthesizeSpeech(text: String, language: String) async throws -> URL? {
        // In production, use AVSpeechSynthesizer or cloud API
        // Mock implementation
        return nil
    }
    
    // MARK: - Context-Aware Translation
    
    /// Translate with cultural context
    public func translateWithContext(
        text: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        context: MessageContext
    ) async throws -> (translation: String, culturalNotes: [CulturalNote]) {
        let basicTranslation = try await translateText(text, from: sourceLanguage, to: targetLanguage)
        
        // Check for cultural notes
        let notes = detectCulturalNotes(
            originalText: text,
            translatedText: basicTranslation,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        
        return (basicTranslation, notes)
    }
    
    /// Check if text contains idioms or cultural references
    public func detectCulturalNotes(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) -> [CulturalNote] {
        var notes: [CulturalNote] = []
        
        // Example: Detect common idioms
        let idioms = knownIdioms[sourceLanguage] ?? []
        
        for idiom in idioms {
            if originalText.lowercased().contains(idiom.phrase.lowercased()) {
                notes.append(CulturalNote(
                    title: idiom.phrase,
                    content: idiom.explanation,
                    language: sourceLanguage,
                    category: .idiom
                ))
            }
        }
        
        return notes
    }
    
    // MARK: - Vocabulary Extraction
    
    /// Extract key vocabulary from text
    public func extractKeyVocabulary(
        text: String,
        language: String,
        targetLanguage: String,
        maxWords: Int = 10
    ) async throws -> [String] {
        // In production, use NLP to extract important words
        // For now, simple word extraction
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        return Array(words.prefix(maxWords))
    }
    
    // MARK: - Helper Methods
    
    private func mockTranslate(text: String, to language: String) async -> String {
        // Fallback for completely unknown text
        let languageName = Language.from(code: language)?.name ?? language
        return "[\(languageName)] \(text)"
    }
    
    
    // MARK: - Cultural Context Data
    
    private struct Idiom {
        let phrase: String
        let explanation: String
    }
    
    private let knownIdioms: [String: [Idiom]] = [
        "en": [
            Idiom(phrase: "break a leg", explanation: "This means 'good luck' in theater/performance contexts"),
            Idiom(phrase: "piece of cake", explanation: "Something very easy to do"),
            Idiom(phrase: "bite the bullet", explanation: "To do something difficult or unpleasant")
        ],
        "es": [
            Idiom(phrase: "estar en las nubes", explanation: "To be daydreaming (literally: to be in the clouds)"),
            Idiom(phrase: "no tener pelos en la lengua", explanation: "To speak frankly (literally: to have no hairs on the tongue)")
        ],
        "ja": [
            Idiom(phrase: "猫の手も借りたい", explanation: "So busy you'd accept help from anyone (literally: want to borrow even a cat's paw)"),
            Idiom(phrase: "目から鱗", explanation: "Eye-opening revelation (literally: scales falling from eyes)")
        ],
        "ko": [
            Idiom(phrase: "식은 죽 먹기", explanation: "Very easy (literally: eating cold porridge)"),
            Idiom(phrase: "눈코 뜰 새 없다", explanation: "Extremely busy (literally: no time to open eyes or nose)")
        ]
    ]
}

// MARK: - Translation Errors

public enum TranslationError: Error, LocalizedError {
    case networkError
    case unsupportedLanguage
    case translationFailed
    case audioProcessingFailed
    
    public var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error during translation"
        case .unsupportedLanguage:
            return "Language not supported for translation"
        case .translationFailed:
            return "Translation failed, please try again"
        case .audioProcessingFailed:
            return "Audio processing failed"
        }
    }
}
