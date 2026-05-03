import SwiftUI

/// Main hub view integrating global features
public struct GlobalFeaturesHubView: View {
    
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Global Room Directory
            GlobalRoomDirectoryView()
                .tabItem {
                    Label("Explore", systemImage: "globe")
                }
                .tag(0)
            
            // Cultural Events
            CulturalEventsView()
                .tabItem {
                    Label("Events", systemImage: "star.circle")
                }
                .tag(1)
            
            // Scheduled Hangouts
            ScheduledHangoutsView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)
            
            // Settings
            LanguageSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

/// Example integration showing how to use the new features
public struct FeatureIntegrationExample: View {
    
    @State private var languageService = LanguageService()
    @State private var culturalEventService = CulturalEventService()
    @State private var schedulingService = SchedulingService()
    
    public init() {}
    
    public var body: some View {
        List {
            Section("Language Features") {
                Text("Current Language: \(languageService.currentLanguage.name)")
                Text("Flag: \(languageService.currentLanguage.flag)")
                Text("RTL: \(languageService.isRTL ? "Yes" : "No")")
            }
            
            Section("Cultural Events") {
                Text("Live Events: \(culturalEventService.liveEvents.count)")
                Text("Upcoming: \(culturalEventService.upcomingEvents.count)")
                Text("Featured: \(culturalEventService.featuredEvents.count)")
            }
            
            Section("Scheduled Hangouts") {
                Text("Upcoming: \(schedulingService.upcomingHangouts.count)")
                Text("Active Routines: \(schedulingService.activeRoutines.count)")
            }
            
            Section("Game Variants") {
                Text("Chess Variants: \(GameVariants.allChessVariants.count)")
                Text("Checkers Variants: \(GameVariants.allCheckersVariants.count)")
                Text("Total Variants: \(GameVariants.allVariants.count)")
            }
            
            Section("Timezone Utilities") {
                ForEach(Array(TimezoneUtility.worldTimes().sorted(by: { $0.key < $1.key })), id: \.key) { city, time in
                    HStack {
                        Text(city)
                        Spacer()
                        Text(time)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Example Actions") {
                Button("Get K-pop Recommendations") {
                    let recommendations = culturalEventService.recommendations(
                        interests: [.kpop],
                        languages: ["ko", "en"],
                        region: "KR",
                        timezone: .current
                    )
                    print("Found \(recommendations.count) K-pop events")
                }
                
                Button("Find Optimal Meeting Time (US, India, Japan)") {
                    let timezones = [
                        TimeZone(identifier: "America/New_York")!,
                        TimeZone(identifier: "Asia/Kolkata")!,
                        TimeZone(identifier: "Asia/Tokyo")!
                    ]
                    
                    if let optimalTime = schedulingService.findOptimalTime(for: timezones) {
                        print("Optimal time: \(optimalTime)")
                    }
                }
                
                Button("Schedule World Cup Watch Party") {
                    _ = schedulingService.scheduleHangout(
                        title: "World Cup Finals Watch Party",
                        description: "Join fans worldwide!",
                        hostId: UUID(),
                        scheduledTime: Date().addingTimeInterval(86400), // Tomorrow
                        timezone: "UTC",
                        durationMinutes: 120,
                        activityType: .movie
                    )
                }
            }
        }
        .navigationTitle("Feature Integration")
    }
}

#Preview("Global Hub") {
    GlobalFeaturesHubView()
}

#Preview("Integration Example") {
    NavigationStack {
        FeatureIntegrationExample()
    }
}
