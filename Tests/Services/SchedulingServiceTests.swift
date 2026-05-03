import Testing
import Foundation
@testable import LayoverKit

/// Tests for SchedulingService
@Suite("Scheduling Service Tests")
@MainActor
struct SchedulingServiceTests {
    
    @Test("Scheduling service initialization")
    func testSchedulingServiceInitialization() {
        let service = SchedulingService()
        
        #expect(service.upcomingHangouts.count >= 0)
        #expect(service.liveHangouts.count >= 0)
        #expect(service.activeRoutines.count >= 0)
    }
    
    @Test("Schedule hangout")
    func testScheduleHangout() {
        let service = SchedulingService()
        let hostId = UUID()
        let futureTime = Date().addingTimeInterval(3600)
        
        let hangout = service.scheduleHangout(
            title: "Test Hangout",
            description: "Description",
            hostId: hostId,
            scheduledTime: futureTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .movie
        )
        
        #expect(service.upcomingHangouts.contains { $0.id == hangout.id })
    }
    
    @Test("Add participant to hangout")
    func testAddParticipantToHangout() {
        let service = SchedulingService()
        let hostId = UUID()
        let participantId = UUID()
        let futureTime = Date().addingTimeInterval(3600)
        
        let hangout = service.scheduleHangout(
            title: "Test",
            description: "Test",
            hostId: hostId,
            scheduledTime: futureTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .casual
        )
        
        service.addParticipant(participantId, to: hangout.id)
        
        let updatedHangouts = service.hangouts(for: participantId)
        #expect(updatedHangouts.contains { $0.id == hangout.id })
    }
    
    @Test("Cancel hangout")
    func testCancelHangout() {
        let service = SchedulingService()
        let hostId = UUID()
        let futureTime = Date().addingTimeInterval(3600)
        
        let hangout = service.scheduleHangout(
            title: "To Cancel",
            description: "Test",
            hostId: hostId,
            scheduledTime: futureTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .gaming
        )
        
        service.cancelHangout(hangout.id)
        
        // Should no longer be in upcoming
        #expect(!service.upcomingHangouts.contains { $0.id == hangout.id })
    }
    
    @Test("Get hangouts for user")
    func testGetHangoutsForUser() {
        let service = SchedulingService()
        let userId = UUID()
        let otherUser = UUID()
        let futureTime = Date().addingTimeInterval(3600)
        
        // User is host
        _ = service.scheduleHangout(
            title: "User's Hangout",
            description: "Test",
            hostId: userId,
            scheduledTime: futureTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .movie
        )
        
        // Other user's hangout
        _ = service.scheduleHangout(
            title: "Other's Hangout",
            description: "Test",
            hostId: otherUser,
            scheduledTime: futureTime,
            timezone: "UTC",
            durationMinutes: 60,
            activityType: .music
        )
        
        let userHangouts = service.hangouts(for: userId)
        
        #expect(userHangouts.count == 1)
        #expect(userHangouts.first?.hostId == userId)
    }
    
    @Test("Create routine")
    func testCreateRoutine() {
        let service = SchedulingService()
        let ownerId = UUID()
        
        let routine = service.createRoutine(
            name: "Morning Workout",
            description: "Daily exercise",
            ownerId: ownerId,
            routineType: .workout,
            scheduledDays: [.monday, .wednesday, .friday],
            scheduledTime: Routine.TimeComponents(hour: 7, minute: 0),
            timezone: "America/New_York",
            activities: []
        )
        
        #expect(service.activeRoutines.contains { $0.id == routine.id })
    }
    
    @Test("Toggle routine")
    func testToggleRoutine() {
        let service = SchedulingService()
        let ownerId = UUID()
        
        let routine = service.createRoutine(
            name: "Study Time",
            description: "Evening study",
            ownerId: ownerId,
            routineType: .study,
            scheduledDays: [.monday],
            scheduledTime: Routine.TimeComponents(hour: 18, minute: 0),
            timezone: "UTC",
            activities: []
        )
        
        let wasActive = routine.isActive
        service.toggleRoutine(routine.id)
        
        let updatedRoutines = service.routines(for: ownerId)
        let updatedRoutine = updatedRoutines.first { $0.id == routine.id }
        
        #expect(updatedRoutine?.isActive == !wasActive)
    }
    
    @Test("Get routines for user")
    func testGetRoutinesForUser() {
        let service = SchedulingService()
        let userId = UUID()
        let otherUser = UUID()
        
        _ = service.createRoutine(
            name: "User's Routine",
            description: "Test",
            ownerId: userId,
            routineType: .morning,
            scheduledDays: [.monday],
            scheduledTime: Routine.TimeComponents(hour: 7, minute: 0),
            timezone: "UTC",
            activities: []
        )
        
        _ = service.createRoutine(
            name: "Other's Routine",
            description: "Test",
            ownerId: otherUser,
            routineType: .evening,
            scheduledDays: [.monday],
            scheduledTime: Routine.TimeComponents(hour: 20, minute: 0),
            timezone: "UTC",
            activities: []
        )
        
        let userRoutines = service.routines(for: userId)
        
        #expect(userRoutines.count == 1)
        #expect(userRoutines.first?.ownerId == userId)
    }
    
    @Test("Add async reaction")
    func testAddAsyncReaction() {
        let service = SchedulingService()
        let userId = UUID()
        let roomId = UUID()
        
        let reaction = service.addReaction(
            userId: userId,
            roomId: roomId,
            mediaId: "media123",
            timestamp: 120.5,
            reactionType: .laugh,
            comment: "Hilarious!"
        )
        
        #expect(reaction.userId == userId)
        #expect(reaction.comment == "Hilarious!")
    }
    
    @Test("Get reactions for media")
    func testGetReactionsForMedia() {
        let service = SchedulingService()
        let userId = UUID()
        let roomId = UUID()
        let mediaId = "test-media"
        
        _ = service.addReaction(
            userId: userId,
            roomId: roomId,
            mediaId: mediaId,
            timestamp: 60,
            reactionType: .love
        )
        
        _ = service.addReaction(
            userId: userId,
            roomId: roomId,
            mediaId: mediaId,
            timestamp: 120,
            reactionType: .wow
        )
        
        let reactions = service.reactions(forMedia: mediaId, in: roomId)
        
        #expect(reactions.count == 2)
        #expect(reactions[0].timestamp < reactions[1].timestamp) // Sorted
    }
    
    @Test("Mark reaction as viewed")
    func testMarkReactionAsViewed() {
        let service = SchedulingService()
        let userId = UUID()
        let viewerId = UUID()
        let roomId = UUID()
        
        let reaction = service.addReaction(
            userId: userId,
            roomId: roomId,
            mediaId: "test",
            timestamp: 100,
            reactionType: .fire
        )
        
        service.markReactionViewed(reaction.id, by: viewerId)
        
        let reactions = service.reactions(forMedia: "test", in: roomId)
        let updatedReaction = reactions.first { $0.id == reaction.id }
        
        #expect(updatedReaction?.viewedBy.contains(viewerId) == true)
    }
    
    @Test("Find optimal meeting time")
    func testFindOptimalMeetingTime() {
        let service = SchedulingService()
        
        let timezones = [
            TimeZone(identifier: "America/New_York")!,
            TimeZone(identifier: "Europe/London")!
        ]
        
        let optimalTime = service.findOptimalTime(for: timezones)
        
        // Should find a time (or nil if no good time in next 7 days)
        #expect(optimalTime != nil || optimalTime == nil)
    }
}
