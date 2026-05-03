import Testing
import Foundation
@testable import LayoverKit

/// Tests for LanguageService
@Suite("Language Service Tests")
@MainActor
struct LanguageServiceTests {
    
    @Test("Language service initialization")
    func testLanguageServiceInitialization() {
        let service = LanguageService()
        
        #expect(service.currentLanguage.code.count > 0)
        #expect(service.autoTranslateEnabled == true)
    }
    
    @Test("Set primary language")
    func testSetPrimaryLanguage() {
        let service = LanguageService()
        
        service.setLanguage(.spanish)
        
        #expect(service.currentLanguage.code == "es")
    }
    
    @Test("Add secondary language")
    func testAddSecondaryLanguage() {
        let service = LanguageService()
        
        service.addSecondaryLanguage(.french)
        service.addSecondaryLanguage(.german)
        
        #expect(service.secondaryLanguages.count == 2)
        #expect(service.secondaryLanguages.contains { $0.code == "fr" })
        #expect(service.secondaryLanguages.contains { $0.code == "de" })
    }
    
    @Test("Remove secondary language")
    func testRemoveSecondaryLanguage() {
        let service = LanguageService()
        
        service.addSecondaryLanguage(.french)
        service.addSecondaryLanguage(.german)
        service.removeSecondaryLanguage(.french)
        
        #expect(service.secondaryLanguages.count == 1)
        #expect(!service.secondaryLanguages.contains { $0.code == "fr" })
    }
    
    @Test("Toggle auto-translate")
    func testToggleAutoTranslate() {
        let service = LanguageService()
        
        service.setAutoTranslate(false)
        #expect(service.autoTranslateEnabled == false)
        
        service.setAutoTranslate(true)
        #expect(service.autoTranslateEnabled == true)
    }
    
    @Test("Recommended content languages")
    func testRecommendedContentLanguages() {
        let service = LanguageService()
        
        service.setLanguage(.english)
        service.addSecondaryLanguage(.spanish)
        service.addSecondaryLanguage(.french)
        
        let languages = service.recommendedContentLanguages()
        
        #expect(languages.count == 3)
        #expect(languages.contains("en"))
        #expect(languages.contains("es"))
        #expect(languages.contains("fr"))
    }
    
    @Test("RTL detection")
    func testRTLDetection() {
        let service = LanguageService()
        
        service.setLanguage(.arabic)
        #expect(service.isRTL == true)
        
        service.setLanguage(.english)
        #expect(service.isRTL == false)
    }
    
    @Test("Cannot add duplicate secondary language")
    func testCannotAddDuplicateSecondaryLanguage() {
        let service = LanguageService()
        
        service.addSecondaryLanguage(.spanish)
        service.addSecondaryLanguage(.spanish)
        
        #expect(service.secondaryLanguages.count == 1)
    }
}
