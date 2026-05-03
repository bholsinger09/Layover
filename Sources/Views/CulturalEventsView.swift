import SwiftUI

/// View displaying cultural events
public struct CulturalEventsView: View {
    
    @State private var eventService = CulturalEventService()
    @State private var selectedInterests: Set<CulturalInterest> = []
    @State private var showingFilters = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live events
                    if !eventService.liveEvents.isEmpty {
                        liveEventsSection
                    }
                    
                    // Upcoming events
                    upcomingEventsSection
                    
                    // All events by category
                    eventsbyTypeSection
                }
                .padding()
            }
            .navigationTitle("Cultural Events")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                InterestFilterView(selectedInterests: $selectedInterests)
            }
        }
    }
    
    private var liveEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔴 Live Now")
                .font(.title2)
                .bold()
            
            ForEach(eventService.liveEvents) { event in
                CulturalEventCard(event: event, isLive: true)
            }
        }
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏰ Coming Up")
                .font(.title2)
                .bold()
            
            ForEach(eventService.upcomingEvents.prefix(5)) { event in
                CulturalEventCard(event: event)
            }
        }
    }
    
    private var eventsbyTypeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sports
            if !eventService.events(ofType: .sports).isEmpty {
                eventTypeSection(title: "⚽ Sports", events: eventService.events(ofType: .sports))
            }
            
            // Music
            if !eventService.events(ofType: .musicRelease).isEmpty {
                eventTypeSection(title: "🎵 Music Releases", events: eventService.events(ofType: .musicRelease))
            }
            
            // Awards
            if !eventService.events(ofType: .awardShow).isEmpty {
                eventTypeSection(title: "🏆 Award Shows", events: eventService.events(ofType: .awardShow))
            }
        }
    }
    
    private func eventTypeSection(title: String, events: [CulturalEvent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(events.prefix(3)) { event in
                CulturalEventCard(event: event)
            }
        }
    }
}

/// Card for displaying a cultural event
struct CulturalEventCard: View {
    let event: CulturalEvent
    var isLive: Bool = false
    
    @State private var isSubscribed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if isLive {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(event.title)
                        .font(.headline)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    isSubscribed.toggle()
                } label: {
                    Image(systemName: isSubscribed ? "bell.fill" : "bell")
                        .foregroundColor(isSubscribed ? .blue : .secondary)
                }
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar")
                    Text(formatDate(event.startDate))
                    
                    if !event.primaryLanguages.isEmpty {
                        Text("•")
                        HStack(spacing: 4) {
                            ForEach(event.primaryLanguages.prefix(3), id: \.self) { langCode in
                                if let lang = Language.from(code: langCode) {
                                    Text(lang.flag)
                                }
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Regions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        ForEach(event.regions.prefix(5), id: \.self) { region in
                            Text(region)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            HStack {
                Button("Create Watch Party") {
                    // Create room for this event
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                if let url = event.livestreamURL {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.circle")
                            Text("Stream")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// Filter view for interests
struct InterestFilterView: View {
    @Binding var selectedInterests: Set<CulturalInterest>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(CulturalInterest.allCases, id: \.self) { interest in
                    HStack {
                        Text(interest.rawValue)
                        Spacer()
                        if selectedInterests.contains(interest) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
            .navigationTitle("Filter Interests")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CulturalEventsView()
}
