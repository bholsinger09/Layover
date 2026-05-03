import Foundation

/// Represents a cultural event that can be watched together
public struct CulturalEvent: LayoverModel {
    public let id: UUID
    public let title: String
    public let description: String
    public let eventType: EventType
    public let startDate: Date
    public let endDate: Date?
    public let timezone: String
    public let primaryLanguages: [String] // Language codes
    public let regions: [String] // Region codes where this is popular
    public let imageURL: URL?
    public let livestreamURL: URL?
    public let interests: [CulturalInterest]
    public let isRecurring: Bool
    public let recurrenceRule: RecurrenceRule?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        eventType: EventType,
        startDate: Date,
        endDate: Date? = nil,
        timezone: String,
        primaryLanguages: [String],
        regions: [String],
        imageURL: URL? = nil,
        livestreamURL: URL? = nil,
        interests: [CulturalInterest],
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.eventType = eventType
        self.startDate = startDate
        self.endDate = endDate
        self.timezone = timezone
        self.primaryLanguages = primaryLanguages
        self.regions = regions
        self.imageURL = imageURL
        self.livestreamURL = livestreamURL
        self.interests = interests
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
    }
    
    public enum EventType: String, Codable, Sendable {
        case sports
        case musicRelease
        case awardShow
        case festival
        case premiere
        case tournament
        case concert
        case other
    }
    
    public enum RecurrenceRule: String, Codable, Sendable {
        case daily
        case weekly
        case monthly
        case yearly
    }
    
    /// Check if event is happening now
    public var isLive: Bool {
        let now = Date()
        if let end = endDate {
            return now >= startDate && now <= end
        }
        return now >= startDate
    }
    
    /// Check if event is upcoming within next 24 hours
    public var isUpcoming: Bool {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        return startDate > now && startDate <= tomorrow
    }
    
    /// Get localized start time for user's timezone
    public func localizedStartTime(for timezone: TimeZone) -> Date {
        // Convert event start time to user's timezone
        let sourceTimezone = TimeZone(identifier: self.timezone) ?? .current
        let offset = timezone.secondsFromGMT() - sourceTimezone.secondsFromGMT()
        return startDate.addingTimeInterval(TimeInterval(offset))
    }
}

/// Featured cultural events curated by the platform
public struct FeaturedEvents {
    
    /// Get sample featured events
    public static func getSampleEvents() -> [CulturalEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // K-pop comeback
            CulturalEvent(
                title: "BTS Album Release Watch Party",
                description: "Join fans worldwide for the premiere of the latest BTS music video",
                eventType: .musicRelease,
                startDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                timezone: "Asia/Seoul",
                primaryLanguages: ["ko", "en"],
                regions: ["KR", "JP", "US", "BR"],
                interests: [.kpop],
                isRecurring: false
            ),
            
            // World Cup
            CulturalEvent(
                title: "FIFA World Cup Finals",
                description: "Watch the biggest football event with fans around the globe",
                eventType: .sports,
                startDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now,
                endDate: calendar.date(byAdding: .day, value: 5, to: now)?.addingTimeInterval(7200),
                timezone: "UTC",
                primaryLanguages: ["en", "es", "pt", "fr", "ar"],
                regions: ["BR", "AR", "ES", "FR", "EG", "SA"],
                interests: [.football, .worldCup],
                isRecurring: false
            ),
            
            // Bollywood premiere
            CulturalEvent(
                title: "Bollywood Blockbuster Premiere",
                description: "Experience the latest Bollywood hit together",
                eventType: .premiere,
                startDate: calendar.date(byAdding: .hour, value: 12, to: now) ?? now,
                timezone: "Asia/Kolkata",
                primaryLanguages: ["hi", "en"],
                regions: ["IN", "PK", "BD"],
                interests: [.bollywood],
                isRecurring: false
            ),
            
            // Grammy Awards
            CulturalEvent(
                title: "Grammy Awards",
                description: "Watch the biggest night in music with viewers worldwide",
                eventType: .awardShow,
                startDate: calendar.date(byAdding: .day, value: 10, to: now) ?? now,
                endDate: calendar.date(byAdding: .day, value: 10, to: now)?.addingTimeInterval(14400),
                timezone: "America/Los_Angeles",
                primaryLanguages: ["en"],
                regions: ["US", "CA", "GB", "AU"],
                interests: [.awards, .hollywood],
                isRecurring: true,
                recurrenceRule: .yearly
            ),
            
            // Esports tournament
            CulturalEvent(
                title: "League of Legends World Championship",
                description: "Join the global esports community for the ultimate showdown",
                eventType: .tournament,
                startDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
                endDate: calendar.date(byAdding: .day, value: 7, to: now)?.addingTimeInterval(10800),
                timezone: "Asia/Shanghai",
                primaryLanguages: ["zh", "en", "ko"],
                regions: ["CN", "KR", "US", "BR"],
                interests: [.esports],
                isRecurring: true,
                recurrenceRule: .yearly
            )
        ]
    }
}
