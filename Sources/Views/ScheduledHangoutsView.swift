import SwiftUI

/// View for managing scheduled hangouts
public struct ScheduledHangoutsView: View {
    
    @State private var schedulingService = SchedulingService()
    @State private var showingCreateSheet = false
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tabs
                Picker("View", selection: $selectedTab) {
                    Text("Upcoming").tag(0)
                    Text("Live").tag(1)
                    Text("Routines").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    upcomingHangoutsView
                        .tag(0)
                    
                    liveHangoutsView
                        .tag(1)
                    
                    routinesView
                        .tag(2)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("Scheduled Hangouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateHangoutView(schedulingService: schedulingService)
            }
        }
    }
    
    private var upcomingHangoutsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if schedulingService.upcomingHangouts.isEmpty {
                    emptyStateView(
                        icon: "calendar",
                        message: "No upcoming hangouts",
                        description: "Schedule a hangout to get started"
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(schedulingService.upcomingHangouts) { hangout in
                        HangoutCard(hangout: hangout)
                    }
                }
            }
            .padding()
        }
    }
    
    private var liveHangoutsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if schedulingService.liveHangouts.isEmpty {
                    emptyStateView(
                        icon: "video.circle",
                        message: "No live hangouts",
                        description: "Join when your scheduled hangouts start"
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(schedulingService.liveHangouts) { hangout in
                        HangoutCard(hangout: hangout, isLive: true)
                    }
                }
            }
            .padding()
        }
    }
    
    private var routinesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if schedulingService.activeRoutines.isEmpty {
                    emptyStateView(
                        icon: "repeat.circle",
                        message: "No active routines",
                        description: "Create a routine for regular hangouts"
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(schedulingService.activeRoutines) { routine in
                        RoutineCard(routine: routine)
                    }
                }
            }
            .padding()
        }
    }
    
    private func emptyStateView(icon: String, message: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

/// Card displaying a scheduled hangout
struct HangoutCard: View {
    let hangout: ScheduledHangout
    var isLive: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if isLive {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE NOW")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(hangout.title)
                        .font(.headline)
                    
                    Text(hangout.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                activityBadge
            }
            
            // Timezone info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "clock")
                    Text(formatTime(hangout.scheduledTime))
                        .font(.subheadline)
                    
                    if let tz = hangout.timezone.split(separator: "/").last {
                        Text("•")
                        Text(String(tz))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Time until start or time remaining
                if !isLive {
                    Text(timeUntilStart)
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Ends in \(timeRemaining)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Participants
                HStack {
                    Image(systemName: "person.2")
                    Text("\(hangout.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                if isLive {
                    Button("Join Now") {
                        // Join hangout
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("View Details") {
                        // View details
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Set Reminder") {
                        // Set reminder
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }
    
    private var activityBadge: some View {
        Text(activityLabel)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(activityColor.opacity(0.2))
            .foregroundColor(activityColor)
            .cornerRadius(6)
    }
    
    private var activityLabel: String {
        switch hangout.activityType {
        case .movie: return "Movie"
        case .music: return "Music"
        case .gaming: return "Gaming"
        case .culturalEvent: return "Event"
        case .routine: return "Routine"
        case .casual: return "Casual"
        }
    }
    
    private var activityColor: Color {
        switch hangout.activityType {
        case .movie: return .purple
        case .music: return .pink
        case .gaming: return .green
        case .culturalEvent: return .orange
        case .routine: return .blue
        case .casual: return .gray
        }
    }
    
    private var timeUntilStart: String {
        let interval = hangout.timeUntilStart
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Starts in \(minutes) minutes"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Starts in \(hours) hours"
        } else {
            let days = Int(interval / 86400)
            return "Starts in \(days) days"
        }
    }
    
    private var timeRemaining: String {
        let endTime = hangout.scheduledTime.addingTimeInterval(TimeInterval(hangout.durationMinutes * 60))
        let remaining = endTime.timeIntervalSinceNow
        let minutes = Int(remaining / 60)
        return "\(minutes) min"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Card for routine
struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.headline)
                    
                    Text(routine.routineType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(routine.isActive))
                    .labelsHidden()
            }
            
            // Schedule
            HStack {
                Image(systemName: "calendar")
                Text(scheduleDays)
                    .font(.subheadline)
                
                Text("•")
                
                Image(systemName: "clock")
                Text(routine.scheduledTime.displayString)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
            
            // Next occurrence
            if let nextDate = routine.nextOccurrence() {
                Text("Next: \(formatRelativeDate(nextDate))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            // Activities
            if !routine.activities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(routine.activities) { activity in
                            HStack {
                                Text(activity.name)
                                Text("(\(activity.durationMinutes)m)")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }
    
    private var scheduleDays: String {
        routine.scheduledDays.map { $0.shortName }.joined(separator: ", ")
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// View for creating a new hangout
struct CreateHangoutView: View {
    let schedulingService: SchedulingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedDate = Date()
    @State private var duration = 60
    @State private var activityType: ScheduledHangout.ActivityType = .casual
    @State private var selectedTimezone = TimeZone.current
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Schedule") {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()...)
                    
                    Picker("Duration", selection: $duration) {
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                    }
                    
                    Picker("Timezone", selection: $selectedTimezone) {
                        ForEach(TimezoneUtility.popularTimezones, id: \.identifier) { tz in
                            Text(tz.displayName).tag(tz.timezone)
                        }
                    }
                }
                
                Section("Activity Type") {
                    Picker("Type", selection: $activityType) {
                        Text("Movie").tag(ScheduledHangout.ActivityType.movie)
                        Text("Music").tag(ScheduledHangout.ActivityType.music)
                        Text("Gaming").tag(ScheduledHangout.ActivityType.gaming)
                        Text("Casual").tag(ScheduledHangout.ActivityType.casual)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Schedule Hangout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createHangout()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createHangout() {
        _ = schedulingService.scheduleHangout(
            title: title,
            description: description,
            hostId: UUID(), // Replace with actual user ID
            scheduledTime: selectedDate,
            timezone: selectedTimezone.identifier,
            durationMinutes: duration,
            activityType: activityType
        )
    }
}

#Preview {
    ScheduledHangoutsView()
}
