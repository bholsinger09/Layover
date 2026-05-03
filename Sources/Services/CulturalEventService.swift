import Foundation
import Observation

/// Service for managing cultural events and recommendations
@Observable
public final class CulturalEventService {
    
    // MARK: - Properties
    
    private var events: [CulturalEvent] = []
    private var subscribedEvents: Set<UUID> = []
    
    public var featuredEvents: [CulturalEvent] {
        events.filter { event in
            event.isLive || event.isUpcoming
        }.sorted { $0.startDate < $1.startDate }
    }
    
    public var liveEvents: [CulturalEvent] {
        events.filter { $0.isLive }
    }
    
    public var upcomingEvents: [CulturalEvent] {
        events.filter { $0.isUpcoming }
    }
    
    // MARK: - Initialization
    
    public init() {
        loadEvents()
    }
    
    // MARK: - Public Methods
    
    /// Load cultural events
    public func loadEvents() {
        // In a real app, fetch from API
        events = FeaturedEvents.getSampleEvents()
    }
    
    /// Get events for specific interests
    public func events(for interests: [CulturalInterest]) -> [CulturalEvent] {
        events.filter { event in
            !Set(event.interests).isDisjoint(with: Set(interests))
        }
    }
    
    /// Get events for specific regions
    public func events(forRegions regions: [String]) -> [CulturalEvent] {
        events.filter { event in
            !Set(event.regions).isDisjoint(with: Set(regions))
        }
    }
    
    /// Get events for specific languages
    public func events(forLanguages languages: [String]) -> [CulturalEvent] {
        events.filter { event in
            !Set(event.primaryLanguages).isDisjoint(with: Set(languages))
        }
    }
    
    /// Get personalized event recommendations
    public func recommendations(
        interests: [CulturalInterest],
        languages: [String],
        region: String,
        timezone: TimeZone
    ) -> [CulturalEvent] {
        var scoredEvents: [(event: CulturalEvent, score: Int)] = []
        
        for event in events {
            var score = 0
            
            // Score based on interests
            let matchingInterests = Set(event.interests).intersection(Set(interests))
            score += matchingInterests.count * 3
            
            // Score based on languages
            let matchingLanguages = Set(event.primaryLanguages).intersection(Set(languages))
            score += matchingLanguages.count * 2
            
            // Score based on region
            if event.regions.contains(region) {
                score += 2
            }
            
            // Bonus for upcoming events
            if event.isUpcoming {
                score += 1
            }
            
            // Bonus for live events
            if event.isLive {
                score += 5
            }
            
            if score > 0 {
                scoredEvents.append((event, score))
            }
        }
        
        return scoredEvents
            .sorted { $0.score > $1.score }
            .map { $0.event }
    }
    
    /// Subscribe to event notifications
    public func subscribe(to eventId: UUID) {
        subscribedEvents.insert(eventId)
    }
    
    /// Unsubscribe from event notifications
    public func unsubscribe(from eventId: UUID) {
        subscribedEvents.remove(eventId)
    }
    
    /// Check if subscribed to event
    public func isSubscribed(to eventId: UUID) -> Bool {
        subscribedEvents.contains(eventId)
    }
    
    /// Create room for cultural event
    public func createEventRoom(for event: CulturalEvent) -> UUID {
        // TODO: Integrate with RoomService to create a room
        // Return placeholder room ID
        return UUID()
    }
    
    /// Get event by ID
    public func event(withId id: UUID) -> CulturalEvent? {
        events.first { $0.id == id }
    }
    
    /// Filter events by time range
    public func events(from startDate: Date, to endDate: Date) -> [CulturalEvent] {
        events.filter { event in
            event.startDate >= startDate && event.startDate <= endDate
        }
    }
    
    /// Get events happening this week
    public func eventsThisWeek() -> [CulturalEvent] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: now) else {
            return []
        }
        return events(from: now, to: weekEnd)
    }
    
    /// Get events by type
    public func events(ofType type: CulturalEvent.EventType) -> [CulturalEvent] {
        events.filter { $0.eventType == type }
    }
    
    /// Add custom event (for user-created events)
    public func addEvent(_ event: CulturalEvent) {
        events.append(event)
    }
    
    /// Remove event
    public func removeEvent(_ eventId: UUID) {
        events.removeAll { $0.id == eventId }
        subscribedEvents.remove(eventId)
    }
}
