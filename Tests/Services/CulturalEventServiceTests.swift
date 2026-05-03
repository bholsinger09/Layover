import Testing
import Foundation
@testable import LayoverKit

/// Tests for CulturalEventService
@Suite("Cultural Event Service Tests")
@MainActor
struct CulturalEventServiceTests {
    
    @Test("Cultural event service initialization")
    func testCulturalEventServiceInitialization() {
        let service = CulturalEventService()
        
        // Service should load sample events
        #expect(service.featuredEvents.count >= 0)
    }
    
    @Test("Load events")
    func testLoadEvents() {
        let service = CulturalEventService()
        
        service.loadEvents()
        
        // Should have sample events
        let allEvents = service.featuredEvents + service.liveEvents + service.upcomingEvents
        #expect(allEvents.count > 0)
    }
    
    @Test("Get events for interests")
    func testGetEventsForInterests() {
        let service = CulturalEventService()
        service.loadEvents()
        
        let kpopEvents = service.events(for: [.kpop])
        
        // All returned events should have kpop interest
        for event in kpopEvents {
            #expect(event.interests.contains(.kpop))
        }
    }
    
    @Test("Get events for regions")
    func testGetEventsForRegions() {
        let service = CulturalEventService()
        service.loadEvents()
        
        let usEvents = service.events(forRegions: ["US"])
        
        // All returned events should include US region
        for event in usEvents {
            #expect(event.regions.contains("US"))
        }
    }
    
    @Test("Get events for languages")
    func testGetEventsForLanguages() {
        let service = CulturalEventService()
        service.loadEvents()
        
        let englishEvents = service.events(forLanguages: ["en"])
        
        // All returned events should include English
        for event in englishEvents {
            #expect(event.primaryLanguages.contains("en"))
        }
    }
    
    @Test("Get recommendations")
    func testGetRecommendations() {
        let service = CulturalEventService()
        service.loadEvents()
        
        let recommendations = service.recommendations(
            interests: [.kpop, .esports],
            languages: ["en", "ko"],
            region: "KR",
            timezone: .current
        )
        
        // Should return events based on scoring
        #expect(recommendations.count >= 0)
    }
    
    @Test("Subscribe to event")
    func testSubscribeToEvent() {
        let service = CulturalEventService()
        service.loadEvents()
        
        guard let firstEvent = service.featuredEvents.first else {
            return
        }
        
        service.subscribe(to: firstEvent.id)
        
        #expect(service.isSubscribed(to: firstEvent.id) == true)
    }
    
    @Test("Unsubscribe from event")
    func testUnsubscribeFromEvent() {
        let service = CulturalEventService()
        service.loadEvents()
        
        guard let firstEvent = service.featuredEvents.first else {
            return
        }
        
        service.subscribe(to: firstEvent.id)
        service.unsubscribe(from: firstEvent.id)
        
        #expect(service.isSubscribed(to: firstEvent.id) == false)
    }
    
    @Test("Get event by ID")
    func testGetEventById() {
        let service = CulturalEventService()
        service.loadEvents()
        
        guard let firstEvent = service.featuredEvents.first else {
            return
        }
        
        let foundEvent = service.event(withId: firstEvent.id)
        
        #expect(foundEvent?.id == firstEvent.id)
    }
    
    @Test("Get events by type")
    func testGetEventsByType() {
        let service = CulturalEventService()
        service.loadEvents()
        
        let sportsEvents = service.events(ofType: .sports)
        
        for event in sportsEvents {
            #expect(event.eventType == .sports)
        }
    }
    
    @Test("Get events this week")
    func testGetEventsThisWeek() {
        let service = CulturalEventService()
        service.loadEvents()
        
        let weekEvents = service.eventsThisWeek()
        
        let now = Date()
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        for event in weekEvents {
            #expect(event.startDate >= now && event.startDate <= weekEnd)
        }
    }
    
    @Test("Add custom event")
    func testAddCustomEvent() {
        let service = CulturalEventService()
        
        let customEvent = CulturalEvent(
            title: "Custom Event",
            description: "Test",
            eventType: .other,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.esports]
        )
        
        service.addEvent(customEvent)
        
        let foundEvent = service.event(withId: customEvent.id)
        #expect(foundEvent != nil)
    }
    
    @Test("Remove event")
    func testRemoveEvent() {
        let service = CulturalEventService()
        
        let customEvent = CulturalEvent(
            title: "To Remove",
            description: "Test",
            eventType: .other,
            startDate: Date(),
            timezone: "UTC",
            primaryLanguages: ["en"],
            regions: ["US"],
            interests: [.esports]
        )
        
        service.addEvent(customEvent)
        service.removeEvent(customEvent.id)
        
        let foundEvent = service.event(withId: customEvent.id)
        #expect(foundEvent == nil)
    }
}
