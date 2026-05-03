import SwiftUI

/// Global directory showing active rooms from around the world
public struct GlobalRoomDirectoryView: View {
    
    @State private var searchText = ""
    @State private var selectedRegion: String?
    @State private var selectedLanguage: String?
    @State private var selectedActivity: RoomActivityType?
    @State private var rooms: [Room] = []
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                filterSection
                
                // Room list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRooms) { room in
                            GlobalRoomCard(room: room)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Global Rooms")
            .searchable(text: $searchText, prompt: "Search rooms...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Refresh rooms
                        loadRooms()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            loadRooms()
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Region filter
                Menu {
                    Button("All Regions") {
                        selectedRegion = nil
                    }
                    ForEach(popularRegions, id: \.self) { region in
                        Button(region) {
                            selectedRegion = region
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRegion ?? "All Regions")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Language filter
                Menu {
                    Button("All Languages") {
                        selectedLanguage = nil
                    }
                    ForEach(Language.allSupported, id: \.code) { language in
                        Button("\(language.flag) \(language.name)") {
                            selectedLanguage = language.code
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedLanguage ?? "All Languages")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Activity filter
                Menu {
                    Button("All Activities") {
                        selectedActivity = nil
                    }
                    Button("TV & Movies") {
                        selectedActivity = .appleTVPlus
                    }
                    Button("Music") {
                        selectedActivity = .appleMusic
                    }
                    Button("Games") {
                        selectedActivity = .chess
                    }
                } label: {
                    HStack {
                        Text(activityFilterLabel)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }
    
    private var filteredRooms: [Room] {
        rooms.filter { room in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                room.name.localizedCaseInsensitiveContains(searchText) ||
                room.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            // Region filter
            let matchesRegion = selectedRegion == nil || room.region == selectedRegion
            
            // Language filter
            let matchesLanguage = selectedLanguage == nil ||
                room.primaryLanguage == selectedLanguage ||
                room.supportedLanguages.contains(selectedLanguage!)
            
            // Activity filter
            let matchesActivity = selectedActivity == nil || room.activityType == selectedActivity
            
            return matchesSearch && matchesRegion && matchesLanguage && matchesActivity && room.isGloballyVisible
        }
    }
    
    private var activityFilterLabel: String {
        guard let activity = selectedActivity else { return "All Activities" }
        switch activity {
        case .appleTVPlus: return "TV & Movies"
        case .appleMusic: return "Music"
        case .chess: return "Games"
        }
    }
    
    private var popularRegions: [String] {
        ["US", "BR", "IN", "CN", "JP", "KR", "GB", "ES", "FR", "DE"]
    }
    
    private func loadRooms() {
        // In a real app, fetch from server
        // For now, create sample data
        rooms = createSampleRooms()
    }
    
    private func createSampleRooms() -> [Room] {
        [
            Room(
                name: "K-Pop Dance Party 🎵",
                hostID: UUID(),
                activityType: .appleMusic,
                primaryLanguage: "ko",
                supportedLanguages: ["en", "ja"],
                region: "KR",
                timezone: "Asia/Seoul",
                tags: ["kpop", "music", "dance"],
                isGloballyVisible: true
            ),
            Room(
                name: "Bollywood Movie Night",
                hostID: UUID(),
                activityType: .appleTVPlus,
                primaryLanguage: "hi",
                supportedLanguages: ["en"],
                region: "IN",
                timezone: "Asia/Kolkata",
                tags: ["bollywood", "movies", "hindi"],
                isGloballyVisible: true
            ),
            Room(
                name: "Chess Masters (Xiangqi)",
                hostID: UUID(),
                activityType: .chess,
                primaryLanguage: "zh",
                supportedLanguages: ["en"],
                region: "CN",
                timezone: "Asia/Shanghai",
                tags: ["chess", "xiangqi", "strategy"],
                isGloballyVisible: true
            )
        ]
    }
}

/// Card displaying a global room
struct GlobalRoomCard: View {
    let room: Room
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        if let language = room.primaryLanguage,
                           let lang = Language.from(code: language) {
                            Text(lang.flag)
                        }
                        
                        if let region = room.region {
                            Text(region)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let timezone = room.timezone {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(currentTimeIn(timezone))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("\(room.participantIDs.count)/\(room.maxParticipants)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    activityBadge
                }
            }
            
            // Tags
            if !room.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(room.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Button("Join Room") {
                // Join room action
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var activityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: activityIcon)
            Text(activityLabel)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(activityColor.opacity(0.2))
        .foregroundColor(activityColor)
        .cornerRadius(6)
    }
    
    private var activityIcon: String {
        switch room.activityType {
        case .appleTVPlus: return "tv"
        case .appleMusic: return "music.note"
        case .chess: return "gamecontroller"
        }
    }
    
    private var activityLabel: String {
        switch room.activityType {
        case .appleTVPlus: return "TV"
        case .appleMusic: return "Music"
        case .chess: return "Game"
        }
    }
    
    private var activityColor: Color {
        switch room.activityType {
        case .appleTVPlus: return .purple
        case .appleMusic: return .pink
        case .chess: return .green
        }
    }
    
    private func currentTimeIn(_ timezoneId: String) -> String {
        guard let timezone = TimeZone(identifier: timezoneId) else {
            return ""
        }
        return TimezoneUtility.formatWithTimezone(Date(), timezone: timezone, style: .short)
    }
}

#Preview {
    GlobalRoomDirectoryView()
}
