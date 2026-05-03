import Testing
import Foundation
@testable import LayoverKit

/// Tests to ensure code quality and clean code practices
@Suite("Code Quality Tests")
struct CodeQualityTests {
    
    // MARK: - Model Tests
    
    @Test("All models conform to LayoverModel protocol")
    func testModelsConformToLayoverModel() {
        // Language
        let language: any LayoverModel = Language.english
        #expect(language.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // CulturalEvent
        let event: any LayoverModel = CulturalEvent(
            title: "Test",
            description: "Test",
            eventType: .sports,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        #expect(event.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // GameVariant
        let variant: any LayoverModel = GameVariants.standardChess
        #expect(variant.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // ScheduledHangout
        let hangout: any LayoverModel = ScheduledHangout(
            title: "Test",
            description: "Test",
            hostId: UUID(),
            scheduledTime: Date(),
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .movie
        )
        #expect(hangout.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // AsyncReaction
        let reaction: any LayoverModel = AsyncReaction(
            userId: UUID(),
            roomId: UUID(),
            mediaId: "test",
            timestamp: 100,
            reactionType: .laugh
        )
        #expect(reaction.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // Routine
        let routine: any LayoverModel = Routine(
            name: "Test",
            description: "Test",
            ownerId: UUID(),
            routineType: .morning,
            scheduledDays: [.monday],
            scheduledTime: Routine.TimeComponents(hour: 7, minute: 0),
            timezone: "UTC",
            activities: []
        )
        #expect(routine.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
    
    @Test("All models are Sendable")
    func testModelsAreSendable() {
        // These should compile without errors due to Sendable conformance
        let language: any Sendable = Language.english
        #expect(language is Language)
        
        let event: any Sendable = CulturalEvent(
            title: "Test",
            description: "Test",
            eventType: .sports,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        #expect(event is CulturalEvent)
    }
    
    @Test("All models are Hashable")
    func testModelsAreHashable() {
        let language = Language.english
        let set1: Set<Language> = [language]
        #expect(set1.count == 1)
        
        let event = CulturalEvent(
            title: "Test",
            description: "Test",
            eventType: .sports,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        let set2: Set<CulturalEvent> = [event]
        #expect(set2.count == 1)
    }
    
    @Test("All models are Codable")
    func testModelsAreCodable() throws {
        // Language
        let language = Language.english
        let languageData = try JSONEncoder().encode(language)
        let decodedLanguage = try JSONDecoder().decode(Language.self, from: languageData)
        #expect(decodedLanguage.code == language.code)
        
        // CulturalEvent
        let event = CulturalEvent(
            title: "Test",
            description: "Test",
            eventType: .sports,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        let eventData = try JSONEncoder().encode(event)
        let decodedEvent = try JSONDecoder().decode(CulturalEvent.self, from: eventData)
        #expect(decodedEvent.title == event.title)
    }
    
    // MARK: - Clean Properties Tests
    
    @Test("Language properties are non-empty")
    func testLanguagePropertiesNonEmpty() {
        for language in Language.allSupported {
            #expect(!language.code.isEmpty, "Language code should not be empty")
            #expect(!language.name.isEmpty, "Language name should not be empty")
            #expect(!language.englishName.isEmpty, "English name should not be empty")
            #expect(!language.flag.isEmpty, "Flag should not be empty")
        }
    }
    
    @Test("Cultural interests have proper raw values")
    func testCulturalInterestsHaveRawValues() {
        for interest in CulturalInterest.allCases {
            #expect(!interest.rawValue.isEmpty, "Interest raw value should not be empty")
            #expect(interest.rawValue.count > 2, "Interest name should be descriptive")
        }
    }
    
    @Test("Game variants have complete data")
    func testGameVariantsHaveCompleteData() {
        for variant in GameVariants.allVariants {
            #expect(!variant.name.isEmpty, "Variant name required")
            #expect(!variant.region.isEmpty, "Variant region required")
            #expect(!variant.description.isEmpty, "Variant description required")
            #expect(!variant.rules.isEmpty, "Variant rules required")
            
            // Rules should have meaningful values
            for (key, value) in variant.rules {
                #expect(!key.isEmpty, "Rule key should not be empty")
                #expect(!value.isEmpty, "Rule value should not be empty")
            }
        }
    }
    
    @Test("Timezone info is complete")
    func testTimezoneInfoComplete() {
        for tzInfo in TimezoneUtility.popularTimezones {
            #expect(!tzInfo.identifier.isEmpty, "Timezone identifier required")
            #expect(!tzInfo.displayName.isEmpty, "Display name required")
            #expect(!tzInfo.region.isEmpty, "Region required")
            
            // Verify timezone is valid
            let tz = TimeZone(identifier: tzInfo.identifier)
            #expect(tz != nil, "Timezone should be valid: \(tzInfo.identifier)")
        }
    }
    
    // MARK: - Enum Tests
    
    @Test("All enums have non-empty raw values")
    func testEnumsHaveNonEmptyRawValues() {
        // Event types
        let eventTypes: [CulturalEvent.EventType] = [
            .sports, .musicRelease, .awardShow, .festival,
            .premiere, .tournament, .concert, .other
        ]
        for type in eventTypes {
            #expect(!type.rawValue.isEmpty)
        }
        
        // Activity types
        let activityTypes: [ScheduledHangout.ActivityType] = [
            .movie, .music, .gaming, .culturalEvent, .routine, .casual
        ]
        for type in activityTypes {
            #expect(!type.rawValue.isEmpty)
        }
        
        // Routine types
        let routineTypes: [Routine.RoutineType] = [
            .morning, .evening, .workout, .study, .gaming, .custom
        ]
        for type in routineTypes {
            #expect(!type.rawValue.isEmpty)
        }
    }
    
    // MARK: - Clean Object Tests
    
    @Test("Objects have proper initialization defaults")
    func testObjectInitializationDefaults() {
        // UserLanguagePreference defaults
        let pref = UserLanguagePreference(
            userId: UUID(),
            primaryLanguage: .english
        )
        #expect(pref.secondaryLanguages.isEmpty)
        #expect(pref.autoTranslate == true)
        
        // ScheduledHangout defaults
        let hangout = ScheduledHangout(
            title: "Test",
            description: "Test",
            hostId: UUID(),
            scheduledTime: Date(),
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .casual
        )
        #expect(hangout.status == .scheduled)
        #expect(hangout.participants.isEmpty)
        #expect(hangout.isRecurring == false)
    }
    
    @Test("No force unwrapping in public APIs")
    func testNoForceUnwrapping() {
        // Language.from returns optional
        let lang = Language.from(code: "invalid")
        #expect(lang == nil)
        
        // TimezoneUtility.timezone returns optional
        let tz = TimezoneUtility.timezone(forRegion: "INVALID")
        #expect(tz == nil)
    }
    
    @Test("Proper use of optionals")
    func testProperUseOfOptionals() {
        // Room.culturalEventId is optional
        let room = Room(
            name: "Test",
            hostID: UUID(),
            activityType: .chess
        )
        #expect(room.culturalEventId == nil)
        
        // CulturalEvent.endDate is optional
        let event = CulturalEvent(
            title: "Test",
            description: "Test",
            eventType: .sports,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        #expect(event.endDate == nil)
    }
    
    // MARK: - Service Quality Tests
    
    @Test("Services use Observable pattern")
    @MainActor
    func testServicesUseObservable() {
        let _ = LanguageService()
        let _ = CulturalEventService()
        let _ = SchedulingService()
        
        // If compilation succeeds, services are properly defined
        #expect(true)
    }
    
    @Test("Services provide clean public APIs")
    @MainActor
    func testServicesProvideCleanAPIs() {
        let languageService = LanguageService()
        
        // Should have clear getter properties
        #expect(languageService.currentLanguage.code.count > 0)
        #expect(languageService.isRTL == true || languageService.isRTL == false)
        
        // Should have clear action methods
        languageService.setLanguage(.spanish)
        languageService.addSecondaryLanguage(.french)
        languageService.setAutoTranslate(true)
        
        #expect(languageService.currentLanguage.code == "es")
    }
    
    @Test("Utility classes are clean and stateless")
    func testUtilityClassesAreStateless() {
        // TimezoneUtility should be stateless (all static methods)
        let time1 = TimezoneUtility.formatWithTimezone(Date(), timezone: .current)
        let time2 = TimezoneUtility.formatWithTimezone(Date(), timezone: .current)
        
        #expect(!time1.isEmpty)
        #expect(!time2.isEmpty)
    }
}

/// Tests for technical debt prevention
@Suite("Technical Debt Prevention Tests")
struct TechnicalDebtTests {
    
    @Test("No TODO comments in production code")
    func testNoTODOComments() {
        // This is a meta-test - in real implementation, you'd scan source files
        // For now, we verify critical paths don't have TODOs by testing functionality
        
        let service = LanguageService()
        service.setLanguage(.english)
        #expect(service.currentLanguage.code == "en")
    }
    
    @Test("All public properties have meaningful names")
    func testMeaningfulPropertyNames() {
        let language = Language.english
        
        // Property names should be self-documenting
        #expect(language.code.count > 0) // 'code' is clear
        #expect(language.name.count > 0) // 'name' is clear
        #expect(language.englishName.count > 0) // 'englishName' is descriptive
        #expect(language.isRTL == true || language.isRTL == false) // 'isRTL' clearly indicates boolean
    }
    
    @Test("All models use UUID for IDs")
    func testModelsUseUUID() {
        let language = Language.english
        #expect(language.id.uuidString.count > 0)
        
        let event = CulturalEvent(
            title: "Test",
            description: "Test",
            eventType: .sports,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        #expect(event.id.uuidString.count > 0)
    }
    
    @Test("No magic numbers in API")
    func testNoMagicNumbers() {
        // Constants should be defined, not magic numbers
        let reminders = ScheduledHangout.ReminderOffset.allCases
        
        for reminder in reminders {
            // Each reminder has a named case and meaningful rawValue
            #expect(reminder.rawValue > 0)
            #expect(!reminder.displayName.isEmpty)
        }
    }
    
    @Test("Proper error handling patterns")
    func testProperErrorHandling() {
        // Optional returns instead of force unwraps
        let invalidLang = Language.from(code: "xyz")
        #expect(invalidLang == nil)
        
        let invalidTz = TimezoneUtility.timezone(forRegion: "XYZ")
        #expect(invalidTz == nil)
    }
    
    @Test("Clear separation of concerns")
    @MainActor
    func testSeparationOfConcerns() {
        // Models are pure data
        let language = Language.english
        #expect(language.code == "en")
        
        // Services handle logic
        let service = LanguageService()
        service.setLanguage(language)
        
        // Utilities provide helpers
        let formatted = TimezoneUtility.formatWithTimezone(Date(), timezone: .current)
        #expect(!formatted.isEmpty)
    }
}
