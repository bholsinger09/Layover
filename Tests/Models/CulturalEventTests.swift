import Testing
import Foundation
@testable import LayoverKit

/// Tests for CulturalEvent model
@Suite("Cultural Event Model Tests")
struct CulturalEventTests {
    
    @Test("CulturalEvent initialization")
    func testCulturalEventInitialization() {
        let startDate = Date()
        let event = CulturalEvent(
            title: "Test Event",
            description: "Test Description",
            eventType: .sports,
            startDate: startDate,
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        
        #expect(event.title == "Test Event")
        #expect(event.description == "Test Description")
        #expect(event.eventType == .sports)
        #expect(event.startDate == startDate)
        #expect(event.timezone == "UTC")
        #expect(event.primaryLanguages == ["en"])
        #expect(event.regions == ["US"])
    }
    
    @Test("Event is live when within time range")
    func testEventIsLive() {
        let now = Date()
        let event = CulturalEvent(
            title: "Live Event",
            description: "Currently happening",
            eventType: .concert,
            startDate: now.addingTimeInterval(-3600), // Started 1 hour ago
            endDate: now.addingTimeInterval(3600), // Ends in 1 hour
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.kpop]
        )
        
        #expect(event.isLive == true)
    }
    
    @Test("Event is not live when in future")
    func testEventNotLiveWhenFuture() {
        let future = Date().addingTimeInterval(86400) // Tomorrow
        let event = CulturalEvent(
            title: "Future Event",
            description: "Tomorrow",
            eventType: .musicRelease,
            startDate: future,
            timezone: "UTC",
            primaryLanguages: ["ko"],
            regions: ["KR"],
            interests: [.kpop]
        )
        
        #expect(event.isLive == false)
    }
    
    @Test("Event is not live when in past")
    func testEventNotLiveWhenPast() {
        let past = Date().addingTimeInterval(-86400) // Yesterday
        let event = CulturalEvent(
            title: "Past Event",
            description: "Yesterday",
            eventType: .awardShow,
            startDate: past,
            endDate: past.addingTimeInterval(7200),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.awards]
        )
        
        #expect(event.isLive == false)
    }
    
    @Test("Event is upcoming within 24 hours")
    func testEventIsUpcoming() {
        let soon = Date().addingTimeInterval(3600) // In 1 hour
        let event = CulturalEvent(
            title: "Upcoming Event",
            description: "Soon",
            eventType: .sports,
            startDate: soon,
            timezone: "UTC",
            primaryLanguages: ["es"],
            regions: ["ES", "AR"],
            interests: [.football]
        )
        
        #expect(event.isUpcoming == true)
    }
    
    @Test("Event not upcoming if beyond 24 hours")
    func testEventNotUpcomingIfFarAway() {
        let farFuture = Date().addingTimeInterval(172800) // 2 days from now
        let event = CulturalEvent(
            title: "Far Future Event",
            description: "In 2 days",
            eventType: .tournament,
            startDate: farFuture,
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.esports]
        )
        
        #expect(event.isUpcoming == false)
    }
    
    @Test("Localized start time conversion")
    func testLocalizedStartTime() {
        let utcDate = Date()
        let event = CulturalEvent(
            title: "UTC Event",
            description: "Test timezone conversion",
            eventType: .sports,
            startDate: utcDate,
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.football]
        )
        
        let estTimezone = TimeZone(identifier: "America/New_York")!
        let localTime = event.localizedStartTime(for: estTimezone)
        
        // The dates should be different due to timezone offset
        #expect(localTime != utcDate || estTimezone.secondsFromGMT() == 0)
    }
    
    @Test("Event type cases exist")
    func testEventTypeCases() {
        let types: [CulturalEvent.EventType] = [
            .sports, .musicRelease, .awardShow, .festival,
            .premiere, .tournament, .concert, .other
        ]
        
        for type in types {
            #expect(!type.rawValue.isEmpty)
        }
    }
    
    @Test("Recurrence rules exist")
    func testRecurrenceRules() {
        let rules: [CulturalEvent.RecurrenceRule] = [
            .daily, .weekly, .monthly, .yearly
        ]
        
        for rule in rules {
            #expect(!rule.rawValue.isEmpty)
        }
    }
    
    @Test("Featured events sample data")
    func testFeaturedEventsSample() {
        let events = FeaturedEvents.getSampleEvents()
        
        #expect(events.count > 0)
        
        // Verify each event has required data
        for event in events {
            #expect(!event.title.isEmpty)
            #expect(!event.description.isEmpty)
            #expect(!event.primaryLanguages.isEmpty)
            #expect(!event.regions.isEmpty)
            #expect(!event.interests.isEmpty)
        }
    }
    
    @Test("Event conforms to LayoverModel")
    func testEventConformsToLayoverModel() {
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
        
        #expect(event.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
}
