import Testing
import Foundation
@testable import LayoverKit

/// Tests for ScheduledHangout model
@Suite("Scheduled Hangout Model Tests")
struct ScheduledHangoutTests {
    
    @Test("ScheduledHangout initialization")
    func testScheduledHangoutInitialization() {
        let hostId = UUID()
        let scheduledTime = Date()
        
        let hangout = ScheduledHangout(
            title: "Test Hangout",
            description: "Test Description",
            hostId: hostId,
            scheduledTime: scheduledTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .movie
        )
        
        #expect(hangout.title == "Test Hangout")
        #expect(hangout.description == "Test Description")
        #expect(hangout.hostId == hostId)
        #expect(hangout.scheduledTime == scheduledTime)
        #expect(hangout.timezone == "UTC")
        #expect(hangout.durationMinutes == 60)
        #expect(hangout.activityType == .movie)
    }
    
    @Test("Hangout is live when within time window")
    func testHangoutIsLive() {
        let now = Date()
        let hangout = ScheduledHangout(
            title: "Live Hangout",
            description: "Currently happening",
            hostId: UUID(),
            scheduledTime: now.addingTimeInterval(-1800), // Started 30 min ago
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .music
        )
        
        #expect(hangout.isLive == true)
    }
    
    @Test("Hangout not live when in future")
    func testHangoutNotLiveWhenFuture() {
        let future = Date().addingTimeInterval(3600)
        let hangout = ScheduledHangout(
            title: "Future Hangout",
            description: "Later",
            hostId: UUID(),
            scheduledTime: future,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .gaming
        )
        
        #expect(hangout.isLive == false)
    }
    
    @Test("Hangout not live when ended")
    func testHangoutNotLiveWhenEnded() {
        let past = Date().addingTimeInterval(-7200) // 2 hours ago
        let hangout = ScheduledHangout(
            title: "Past Hangout",
            description: "Ended",
            hostId: UUID(),
            scheduledTime: past,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .casual
        )
        
        #expect(hangout.isLive == false)
    }
    
    @Test("Local time conversion")
    func testLocalTimeConversion() {
        let utcTime = Date()
        let hangout = ScheduledHangout(
            title: "UTC Hangout",
            description: "Test",
            hostId: UUID(),
            scheduledTime: utcTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .movie
        )
        
        let estTimezone = TimeZone(identifier: "America/New_York")!
        let localTime = hangout.localTime(for: estTimezone)
        
        // Times should differ based on timezone offset
        let offset = estTimezone.secondsFromGMT() - TimeZone(identifier: "UTC")!.secondsFromGMT()
        #expect(abs(localTime.timeIntervalSince(utcTime) - Double(offset)) < 1)
    }
    
    @Test("Time until start calculation")
    func testTimeUntilStart() {
        let futureTime = Date().addingTimeInterval(3600) // 1 hour from now
        let hangout = ScheduledHangout(
            title: "Future Hangout",
            description: "Test",
            hostId: UUID(),
            scheduledTime: futureTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .music
        )
        
        let timeUntil = hangout.timeUntilStart
        #expect(timeUntil > 3500 && timeUntil < 3700) // ~1 hour with small margin
    }
    
    @Test("Activity types exist")
    func testActivityTypes() {
        let types: [ScheduledHangout.ActivityType] = [
            .movie, .music, .gaming, .culturalEvent, .routine, .casual
        ]
        
        for type in types {
            #expect(!type.rawValue.isEmpty)
        }
    }
    
    @Test("Reminder offsets have display names")
    func testReminderOffsets() {
        for offset in ScheduledHangout.ReminderOffset.allCases {
            #expect(!offset.displayName.isEmpty)
            #expect(offset.rawValue > 0)
        }
    }
    
    @Test("Hangout status cases exist")
    func testHangoutStatusCases() {
        let statuses: [ScheduledHangout.HangoutStatus] = [
            .scheduled, .live, .completed, .cancelled
        ]
        
        for status in statuses {
            #expect(!status.rawValue.isEmpty)
        }
    }
}

/// Tests for AsyncReaction model
@Suite("Async Reaction Model Tests")
struct AsyncReactionTests {
    
    @Test("AsyncReaction initialization")
    func testAsyncReactionInitialization() {
        let userId = UUID()
        let roomId = UUID()
        
        let reaction = AsyncReaction(
            userId: userId,
            roomId: roomId,
            mediaId: "media123",
            timestamp: 120.5,
            reactionType: .laugh
        )
        
        #expect(reaction.userId == userId)
        #expect(reaction.roomId == roomId)
        #expect(reaction.mediaId == "media123")
        #expect(reaction.timestamp == 120.5)
        #expect(reaction.reactionType == .laugh)
    }
    
    @Test("Reaction types have emojis")
    func testReactionTypesHaveEmojis() {
        for reactionType in AsyncReaction.ReactionType.allCases {
            #expect(!reactionType.emoji.isEmpty)
            #expect(reactionType.emoji == reactionType.rawValue)
        }
    }
    
    @Test("Formatted timestamp")
    func testFormattedTimestamp() {
        let reaction = AsyncReaction(
            userId: UUID(),
            roomId: UUID(),
            mediaId: "test",
            timestamp: 125.0, // 2:05
            reactionType: .love
        )
        
        #expect(reaction.formattedTimestamp == "2:05")
    }
    
    @Test("Formatted timestamp with leading zeros")
    func testFormattedTimestampLeadingZeros() {
        let reaction = AsyncReaction(
            userId: UUID(),
            roomId: UUID(),
            mediaId: "test",
            timestamp: 65.0, // 1:05
            reactionType: .wow
        )
        
        #expect(reaction.formattedTimestamp == "1:05")
    }
    
    @Test("Viewed by tracking")
    func testViewedByTracking() {
        let viewer1 = UUID()
        let viewer2 = UUID()
        
        let reaction = AsyncReaction(
            userId: UUID(),
            roomId: UUID(),
            mediaId: "test",
            timestamp: 100,
            reactionType: .fire,
            viewedBy: [viewer1, viewer2]
        )
        
        #expect(reaction.viewedBy.count == 2)
        #expect(reaction.viewedBy.contains(viewer1))
        #expect(reaction.viewedBy.contains(viewer2))
    }
}

/// Tests for Routine model
@Suite("Routine Model Tests")
struct RoutineTests {
    
    @Test("Routine initialization")
    func testRoutineInitialization() {
        let ownerId = UUID()
        let activities = [
            Routine.RoutineActivity(
                name: "Workout",
                durationMinutes: 30,
                activityType: .casual
            )
        ]
        
        let routine = Routine(
            name: "Morning Routine",
            description: "Daily morning activities",
            ownerId: ownerId,
            routineType: .morning,
            scheduledDays: [.monday, .wednesday, .friday],
            scheduledTime: Routine.TimeComponents(hour: 7, minute: 0),
            timezone: "America/New_York",
            activities: activities
        )
        
        #expect(routine.name == "Morning Routine")
        #expect(routine.ownerId == ownerId)
        #expect(routine.routineType == .morning)
        #expect(routine.scheduledDays.count == 3)
        #expect(routine.activities.count == 1)
    }
    
    @Test("Weekday short names")
    func testWeekdayShortNames() {
        #expect(Routine.Weekday.monday.shortName == "Mon")
        #expect(Routine.Weekday.tuesday.shortName == "Tue")
        #expect(Routine.Weekday.wednesday.shortName == "Wed")
        #expect(Routine.Weekday.thursday.shortName == "Thu")
        #expect(Routine.Weekday.friday.shortName == "Fri")
        #expect(Routine.Weekday.saturday.shortName == "Sat")
        #expect(Routine.Weekday.sunday.shortName == "Sun")
    }
    
    @Test("TimeComponents display string")
    func testTimeComponentsDisplayString() {
        let time1 = Routine.TimeComponents(hour: 9, minute: 30)
        #expect(time1.displayString == "09:30")
        
        let time2 = Routine.TimeComponents(hour: 14, minute: 5)
        #expect(time2.displayString == "14:05")
    }
    
    @Test("Routine type cases exist")
    func testRoutineTypes() {
        let types: [Routine.RoutineType] = [
            .morning, .evening, .workout, .study, .gaming, .custom
        ]
        
        for type in types {
            #expect(!type.rawValue.isEmpty)
        }
    }
    
    @Test("Routine activity has proper properties")
    func testRoutineActivity() {
        let activity = Routine.RoutineActivity(
            name: "Study Session",
            durationMinutes: 45,
            activityType: .casual
        )
        
        #expect(activity.name == "Study Session")
        #expect(activity.durationMinutes == 45)
        #expect(activity.activityType == .casual)
    }
    
    @Test("All weekdays are unique")
    func testAllWeekdaysUnique() {
        let weekdays = Routine.Weekday.allCases
        let rawValues = weekdays.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        
        #expect(rawValues.count == uniqueValues.count)
        #expect(weekdays.count == 7)
    }
}
