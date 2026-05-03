import Testing
import Foundation
@testable import LayoverKit

/// Tests for Language model
@Suite("Language Model Tests")
struct LanguageTests {
    
    @Test("Language initialization")
    func testLanguageInitialization() {
        let language = Language(
            code: "en",
            name: "English",
            englishName: "English",
            isRTL: false,
            flag: "🇺🇸"
        )
        
        #expect(language.code == "en")
        #expect(language.name == "English")
        #expect(language.englishName == "English")
        #expect(language.isRTL == false)
        #expect(language.flag == "🇺🇸")
    }
    
    @Test("All supported languages are unique")
    func testUniqueSupportedLanguages() {
        let codes = Language.allSupported.map { $0.code }
        let uniqueCodes = Set(codes)
        
        #expect(codes.count == uniqueCodes.count)
    }
    
    @Test("Primary languages exists")
    func testPrimaryLanguagesExist() {
        #expect(Language.english.code == "en")
        #expect(Language.spanish.code == "es")
        #expect(Language.mandarin.code == "zh")
        #expect(Language.hindi.code == "hi")
        #expect(Language.arabic.code == "ar")
        #expect(Language.portuguese.code == "pt")
    }
    
    @Test("Arabic is RTL")
    func testArabicIsRTL() {
        #expect(Language.arabic.isRTL == true)
    }
    
    @Test("Non-RTL languages")
    func testNonRTLLanguages() {
        #expect(Language.english.isRTL == false)
        #expect(Language.spanish.isRTL == false)
        #expect(Language.mandarin.isRTL == false)
    }
    
    @Test("Language from code")
    func testLanguageFromCode() {
        let english = Language.from(code: "en")
        #expect(english?.code == "en")
        
        let invalid = Language.from(code: "invalid")
        #expect(invalid == nil)
    }
    
    @Test("All supported languages have valid codes")
    func testAllLanguagesHaveValidCodes() {
        for language in Language.allSupported {
            #expect(!language.code.isEmpty)
            #expect(language.code.count == 2) // ISO 639-1 codes are 2 characters
        }
    }
    
    @Test("All supported languages have names")
    func testAllLanguagesHaveNames() {
        for language in Language.allSupported {
            #expect(!language.name.isEmpty)
            #expect(!language.englishName.isEmpty)
        }
    }
    
    @Test("Language conforms to LayoverModel")
    func testLanguageConformsToLayoverModel() {
        let language = Language.english
        
        // Has ID
        #expect(language.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // Is Hashable
        let set: Set<Language> = [language]
        #expect(set.count == 1)
    }
    
    @Test("UserLanguagePreference initialization")
    func testUserLanguagePreferenceInitialization() {
        let userId = UUID()
        let preference = UserLanguagePreference(
            userId: userId,
            primaryLanguage: .english,
            secondaryLanguages: [.spanish, .french],
            autoTranslate: true,
            showOriginalWithTranslation: false
        )
        
        #expect(preference.userId == userId)
        #expect(preference.primaryLanguage.code == "en")
        #expect(preference.secondaryLanguages.count == 2)
        #expect(preference.autoTranslate == true)
    }
    
    @Test("RegionalPreference initialization")
    func testRegionalPreferenceInitialization() {
        let userId = UUID()
        let preference = RegionalPreference(
            userId: userId,
            region: "US",
            timezone: "America/New_York",
            culturalInterests: [.kpop, .esports]
        )
        
        #expect(preference.userId == userId)
        #expect(preference.region == "US")
        #expect(preference.timezone == "America/New_York")
        #expect(preference.culturalInterests.count == 2)
    }
    
    @Test("CulturalInterest cases exist")
    func testCulturalInterestCases() {
        #expect(CulturalInterest.allCases.count > 0)
        #expect(CulturalInterest.allCases.contains(.kpop))
        #expect(CulturalInterest.allCases.contains(.bollywood))
        #expect(CulturalInterest.allCases.contains(.worldCup))
    }
}
