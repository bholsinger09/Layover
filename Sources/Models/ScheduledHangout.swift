import Foundation

/// Scheduled hangout/event with timezone support
public struct ScheduledHangout: LayoverModel {
    public let id: UUID
    public let title: String
    public let description: String
    public let hostId: UUID
    public let roomId: UUID?
    public let scheduledTime: Date
    public let timezone: String // IANA timezone identifier
    public let durationMinutes: Int
    public let participants: [UUID] // User IDs
    public let activityType: ActivityType
    public let isRecurring: Bool
    public let recurrenceRule: RecurrenceRule?
    public let reminders: [ReminderOffset]
    public let culturalEventId: UUID? // Link to cultural event if applicable
    public let status: HangoutStatus
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        hostId: UUID,
        roomId: UUID? = nil,
        scheduledTime: Date,
        timezone: String,
        durationMinutes: Int,
        participants: [UUID] = [],
        activityType: ActivityType,
        isRecurring: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        reminders: [ReminderOffset] = [.fifteenMinutes],
        culturalEventId: UUID? = nil,
        status: HangoutStatus = .scheduled,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.hostId = hostId
        self.roomId = roomId
        self.scheduledTime = scheduledTime
        self.timezone = timezone
        self.durationMinutes = durationMinutes
        self.participants = participants
        self.activityType = activityType
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        self.reminders = reminders
        self.culturalEventId = culturalEventId
        self.status = status
        self.createdAt = createdAt
    }
    
    public enum ActivityType: String, Codable, Sendable {
        case movie
        case music
        case gaming
        case culturalEvent
        case routine
        case casual
    }
    
    public enum RecurrenceRule: String, Codable, Sendable {
        case daily
        case weekly
        case biweekly
        case monthly
        case custom
    }
    
    public enum ReminderOffset: Int, Codable, Sendable, CaseIterable {
        case fiveMinutes = 5
        case fifteenMinutes = 15
        case thirtyMinutes = 30
        case oneHour = 60
        case oneDay = 1440
        case oneWeek = 10080
        
        public var displayName: String {
            switch self {
            case .fiveMinutes: return "5 minutes before"
            case .fifteenMinutes: return "15 minutes before"
            case .thirtyMinutes: return "30 minutes before"
            case .oneHour: return "1 hour before"
            case .oneDay: return "1 day before"
            case .oneWeek: return "1 week before"
            }
        }
    }
    
    public enum HangoutStatus: String, Codable, Sendable {
        case scheduled
        case live
        case completed
        case cancelled
    }
    
    /// Get scheduledTime converted to user's timezone
    public func localTime(for userTimezone: TimeZone) -> Date {
        let eventTimezone = TimeZone(identifier: timezone) ?? .current
        let offset = userTimezone.secondsFromGMT() - eventTimezone.secondsFromGMT()
        return scheduledTime.addingTimeInterval(TimeInterval(offset))
    }
    
    /// Check if hangout is happening now
    public var isLive: Bool {
        let now = Date()
        let endTime = scheduledTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return now >= scheduledTime && now <= endTime
    }
    
    /// Time until hangout starts
    public var timeUntilStart: TimeInterval {
        scheduledTime.timeIntervalSinceNow
    }
}

/// Async reaction for watch parties
public struct AsyncReaction: LayoverModel {
    public let id: UUID
    public let userId: UUID
    public let roomId: UUID
    public let mediaId: String // ID of the media being watched
    public let timestamp: TimeInterval // Time in the media where reaction occurred
    public let reactionType: ReactionType
    public let comment: String?
    public let createdAt: Date
    public let viewedBy: Set<UUID> // Users who have seen this reaction
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        roomId: UUID,
        mediaId: String,
        timestamp: TimeInterval,
        reactionType: ReactionType,
        comment: String? = nil,
        createdAt: Date = Date(),
        viewedBy: Set<UUID> = []
    ) {
        self.id = id
        self.userId = userId
        self.roomId = roomId
        self.mediaId = mediaId
        self.timestamp = timestamp
        self.reactionType = reactionType
        self.comment = comment
        self.createdAt = createdAt
        self.viewedBy = viewedBy
    }
    
    public enum ReactionType: String, Codable, Sendable, CaseIterable {
        case laugh = "😂"
        case love = "❤️"
        case wow = "😮"
        case sad = "😢"
        case fire = "🔥"
        case clap = "👏"
        case thinking = "🤔"
        case mindBlown = "🤯"
        case crying = "😭"
        case skull = "💀"
        
        public var emoji: String {
            self.rawValue
        }
    }
    
    /// Format timestamp as MM:SS
    public var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Routine template for "wake up with friends" etc.
public struct Routine: LayoverModel {
    public let id: UUID
    public let name: String
    public let description: String
    public let ownerId: UUID
    public let routineType: RoutineType
    public let scheduledDays: [Weekday]
    public let scheduledTime: TimeComponents // Local time
    public let timezone: String
    public let activities: [RoutineActivity]
    public let participants: [UUID]
    public let isActive: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        ownerId: UUID,
        routineType: RoutineType,
        scheduledDays: [Weekday],
        scheduledTime: TimeComponents,
        timezone: String,
        activities: [RoutineActivity],
        participants: [UUID] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerId = ownerId
        self.routineType = routineType
        self.scheduledDays = scheduledDays
        self.scheduledTime = scheduledTime
        self.timezone = timezone
        self.activities = activities
        self.participants = participants
        self.isActive = isActive
    }
    
    public enum RoutineType: String, Codable, Sendable {
        case morning = "Morning Routine"
        case evening = "Evening Routine"
        case workout = "Workout Session"
        case study = "Study Time"
        case gaming = "Gaming Session"
        case custom = "Custom"
    }
    
    public enum Weekday: Int, Codable, Sendable, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
        
        public var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }
    }
    
    public struct TimeComponents: Codable, Hashable, Sendable {
        public let hour: Int // 0-23
        public let minute: Int // 0-59
        
        public init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }
        
        public var displayString: String {
            String(format: "%02d:%02d", hour, minute)
        }
        
        /// Convert to Date for today in specified timezone
        public func toDate(timezone: TimeZone) -> Date? {
            var calendar = Calendar.current
            calendar.timeZone = timezone
            
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute
            
            return calendar.date(from: components)
        }
    }
    
    public struct RoutineActivity: Codable, Hashable, Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let durationMinutes: Int
        public let activityType: ScheduledHangout.ActivityType
        
        public init(
            id: UUID = UUID(),
            name: String,
            durationMinutes: Int,
            activityType: ScheduledHangout.ActivityType
        ) {
            self.id = id
            self.name = name
            self.durationMinutes = durationMinutes
            self.activityType = activityType
        }
    }
    
    /// Get next occurrence of this routine
    public func nextOccurrence() -> Date? {
        let calendar = Calendar.current
        let tz = TimeZone(identifier: timezone) ?? .current
        var cal = calendar
        cal.timeZone = tz
        
        let now = Date()
        
        // Find next scheduled day
        for daysAhead in 0..<7 {
            let checkDate = cal.date(byAdding: .day, value: daysAhead, to: now)!
            let checkWeekday = cal.component(.weekday, from: checkDate)
            
            if scheduledDays.first(where: { $0.rawValue == checkWeekday }) != nil {
                var components = cal.dateComponents([.year, .month, .day], from: checkDate)
                components.hour = scheduledTime.hour
                components.minute = scheduledTime.minute
                
                if let nextDate = cal.date(from: components), nextDate > now {
                    return nextDate
                }
            }
        }
        
        return nil
    }
}
