import Foundation
import Observation

/// Service for managing scheduled hangouts and routines
@Observable
public final class SchedulingService {
    
    // MARK: - Properties
    
    private var scheduledHangouts: [ScheduledHangout] = []
    private var routines: [Routine] = []
    private var asyncReactions: [AsyncReaction] = []
    
    public var upcomingHangouts: [ScheduledHangout] {
        scheduledHangouts
            .filter { $0.status == .scheduled && $0.scheduledTime > Date() }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    public var liveHangouts: [ScheduledHangout] {
        scheduledHangouts.filter { $0.isLive }
    }
    
    public var activeRoutines: [Routine] {
        routines.filter { $0.isActive }
    }
    
    // MARK: - Initialization
    
    public init() {
        loadScheduledData()
    }
    
    // MARK: - Scheduled Hangouts
    
    /// Create a new scheduled hangout
    public func scheduleHangout(
        title: String,
        description: String,
        hostId: UUID,
        scheduledTime: Date,
        timezone: String,
        durationMinutes: Int,
        activityType: ScheduledHangout.ActivityType,
        participants: [UUID] = [],
        culturalEventId: UUID? = nil
    ) -> ScheduledHangout {
        let hangout = ScheduledHangout(
            title: title,
            description: description,
            hostId: hostId,
            scheduledTime: scheduledTime,
            timezone: timezone,
            durationMinutes: durationMinutes,
            participants: participants,
            activityType: activityType,
            culturalEventId: culturalEventId
        )
        
        scheduledHangouts.append(hangout)
        return hangout
    }
    
    /// Update scheduled hangout
    public func updateHangout(_ hangout: ScheduledHangout) {
        if let index = scheduledHangouts.firstIndex(where: { $0.id == hangout.id }) {
            scheduledHangouts[index] = hangout
        }
    }
    
    /// Cancel a scheduled hangout
    public func cancelHangout(_ hangoutId: UUID) {
        if let index = scheduledHangouts.firstIndex(where: { $0.id == hangoutId }) {
            var hangout = scheduledHangouts[index]
            hangout = ScheduledHangout(
                id: hangout.id,
                title: hangout.title,
                description: hangout.description,
                hostId: hangout.hostId,
                roomId: hangout.roomId,
                scheduledTime: hangout.scheduledTime,
                timezone: hangout.timezone,
                durationMinutes: hangout.durationMinutes,
                participants: hangout.participants,
                activityType: hangout.activityType,
                isRecurring: hangout.isRecurring,
                recurrenceRule: hangout.recurrenceRule,
                reminders: hangout.reminders,
                culturalEventId: hangout.culturalEventId,
                status: .cancelled,
                createdAt: hangout.createdAt
            )
            scheduledHangouts[index] = hangout
        }
    }
    
    /// Add participant to hangout
    public func addParticipant(_ userId: UUID, to hangoutId: UUID) {
        if let index = scheduledHangouts.firstIndex(where: { $0.id == hangoutId }) {
            var hangout = scheduledHangouts[index]
            var participants = hangout.participants
            if !participants.contains(userId) {
                participants.append(userId)
                hangout = ScheduledHangout(
                    id: hangout.id,
                    title: hangout.title,
                    description: hangout.description,
                    hostId: hangout.hostId,
                    roomId: hangout.roomId,
                    scheduledTime: hangout.scheduledTime,
                    timezone: hangout.timezone,
                    durationMinutes: hangout.durationMinutes,
                    participants: participants,
                    activityType: hangout.activityType,
                    isRecurring: hangout.isRecurring,
                    recurrenceRule: hangout.recurrenceRule,
                    reminders: hangout.reminders,
                    culturalEventId: hangout.culturalEventId,
                    status: hangout.status,
                    createdAt: hangout.createdAt
                )
                scheduledHangouts[index] = hangout
            }
        }
    }
    
    /// Get hangouts for user
    public func hangouts(for userId: UUID) -> [ScheduledHangout] {
        scheduledHangouts.filter { hangout in
            hangout.hostId == userId || hangout.participants.contains(userId)
        }
    }
    
    /// Get hangouts in user's timezone
    public func upcomingHangouts(for userId: UUID, timezone: TimeZone) -> [ScheduledHangout] {
        hangouts(for: userId)
            .filter { $0.status == .scheduled && $0.scheduledTime > Date() }
            .sorted { $0.localTime(for: timezone) < $1.localTime(for: timezone) }
    }
    
    // MARK: - Routines
    
    /// Create a new routine
    public func createRoutine(
        name: String,
        description: String,
        ownerId: UUID,
        routineType: Routine.RoutineType,
        scheduledDays: [Routine.Weekday],
        scheduledTime: Routine.TimeComponents,
        timezone: String,
        activities: [Routine.RoutineActivity]
    ) -> Routine {
        let routine = Routine(
            name: name,
            description: description,
            ownerId: ownerId,
            routineType: routineType,
            scheduledDays: scheduledDays,
            scheduledTime: scheduledTime,
            timezone: timezone,
            activities: activities
        )
        
        routines.append(routine)
        return routine
    }
    
    /// Toggle routine active status
    public func toggleRoutine(_ routineId: UUID) {
        if let index = routines.firstIndex(where: { $0.id == routineId }) {
            var routine = routines[index]
            routine = Routine(
                id: routine.id,
                name: routine.name,
                description: routine.description,
                ownerId: routine.ownerId,
                routineType: routine.routineType,
                scheduledDays: routine.scheduledDays,
                scheduledTime: routine.scheduledTime,
                timezone: routine.timezone,
                activities: routine.activities,
                participants: routine.participants,
                isActive: !routine.isActive
            )
            routines[index] = routine
        }
    }
    
    /// Get routines for user
    public func routines(for userId: UUID) -> [Routine] {
        routines.filter { routine in
            routine.ownerId == userId || routine.participants.contains(userId)
        }
    }
    
    /// Get next routine occurrence
    public func nextRoutineOccurrence(for userId: UUID) -> (routine: Routine, date: Date)? {
        let userRoutines = routines(for: userId).filter { $0.isActive }
        
        var nextOccurrence: (routine: Routine, date: Date)?
        
        for routine in userRoutines {
            if let date = routine.nextOccurrence() {
                if nextOccurrence == nil || date < nextOccurrence!.date {
                    nextOccurrence = (routine, date)
                }
            }
        }
        
        return nextOccurrence
    }
    
    // MARK: - Async Reactions
    
    /// Add async reaction
    public func addReaction(
        userId: UUID,
        roomId: UUID,
        mediaId: String,
        timestamp: TimeInterval,
        reactionType: AsyncReaction.ReactionType,
        comment: String? = nil
    ) -> AsyncReaction {
        let reaction = AsyncReaction(
            userId: userId,
            roomId: roomId,
            mediaId: mediaId,
            timestamp: timestamp,
            reactionType: reactionType,
            comment: comment
        )
        
        asyncReactions.append(reaction)
        return reaction
    }
    
    /// Get reactions for media
    public func reactions(forMedia mediaId: String, in roomId: UUID) -> [AsyncReaction] {
        asyncReactions.filter { $0.mediaId == mediaId && $0.roomId == roomId }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Get unviewed reactions for user
    public func unviewedReactions(for userId: UUID, in roomId: UUID) -> [AsyncReaction] {
        asyncReactions.filter { reaction in
            reaction.roomId == roomId && !reaction.viewedBy.contains(userId)
        }
    }
    
    /// Mark reaction as viewed
    public func markReactionViewed(_ reactionId: UUID, by userId: UUID) {
        if let index = asyncReactions.firstIndex(where: { $0.id == reactionId }) {
            var reaction = asyncReactions[index]
            var viewedBy = reaction.viewedBy
            viewedBy.insert(userId)
            reaction = AsyncReaction(
                id: reaction.id,
                userId: reaction.userId,
                roomId: reaction.roomId,
                mediaId: reaction.mediaId,
                timestamp: reaction.timestamp,
                reactionType: reaction.reactionType,
                comment: reaction.comment,
                createdAt: reaction.createdAt,
                viewedBy: viewedBy
            )
            asyncReactions[index] = reaction
        }
    }
    
    // MARK: - Time Zone Support
    
    /// Find optimal meeting time for participants
    public func findOptimalTime(
        for participantTimezones: [TimeZone],
        preferredHours: ClosedRange<Int> = 9...21
    ) -> Date? {
        TimezoneUtility.optimalMeetingTime(
            timezones: participantTimezones,
            preferredHourRange: preferredHours
        )
    }
    
    // MARK: - Private Methods
    
    private func loadScheduledData() {
        // In a real app, load from persistent storage
        // For now, create sample data
        scheduledHangouts = []
        routines = []
        asyncReactions = []
    }
}
