import SwiftUI

/// Language and regional settings view
public struct LanguageSettingsView: View {
    
    @State private var languageService = LanguageService()
    @State private var selectedLanguage: Language
    @State private var secondaryLanguages: [Language] = []
    @State private var autoTranslate = true
    @State private var selectedRegion = "US"
    @State private var selectedTimezone = TimeZone.current
    @State private var selectedInterests: Set<CulturalInterest> = []
    
    public init() {
        _selectedLanguage = State(initialValue: Language.english)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Primary Language
                Section {
                    Picker("Primary Language", selection: $selectedLanguage) {
                        ForEach(Language.allSupported, id: \.code) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.name)
                                Text("(\(language.englishName))")
                                    .foregroundColor(.secondary)
                            }
                            .tag(language)
                        }
                    }
                } header: {
                    Text("Primary Language")
                } footer: {
                    Text("This will be used for app interface and content recommendations")
                }
                
                // Secondary Languages
                Section {
                    ForEach(secondaryLanguages, id: \.code) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.name)
                            Spacer()
                            Button {
                                removeSecondaryLanguage(language)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Menu {
                        ForEach(availableSecondaryLanguages, id: \.code) { language in
                            Button {
                                addSecondaryLanguage(language)
                            } label: {
                                HStack {
                                    Text(language.flag)
                                    Text(language.name)
                                }
                            }
                        }
                    } label: {
                        Label("Add Language", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Additional Languages")
                } footer: {
                    Text("Content in these languages will also be recommended")
                }
                
                // Translation Settings
                Section("Translation") {
                    Toggle("Auto-translate content", isOn: $autoTranslate)
                }
                
                // Region & Timezone
                Section("Region & Timezone") {
                    Picker("Region", selection: $selectedRegion) {
                        ForEach(popularRegions, id: \.code) { region in
                            Text("\(region.flag) \(region.name)").tag(region.code)
                        }
                    }
                    
                    Picker("Timezone", selection: $selectedTimezone) {
                        ForEach(TimezoneUtility.popularTimezones, id: \.identifier) { tz in
                            Text(tz.displayName).tag(tz.timezone)
                        }
                    }
                    
                    // Current time preview
                    HStack {
                        Text("Current time")
                        Spacer()
                        Text(currentTimeString)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Cultural Interests
                Section {
                    ForEach(CulturalInterest.allCases, id: \.self) { interest in
                        Toggle(interest.rawValue, isOn: Binding(
                            get: { selectedInterests.contains(interest) },
                            set: { newValue in
                                if newValue {
                                    selectedInterests.insert(interest)
                                } else {
                                    selectedInterests.remove(interest)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Cultural Interests")
                } footer: {
                    Text("Select interests to get personalized event and content recommendations")
                }
                
                // Regional Game Variants
                Section {
                    NavigationLink("Chess Variants") {
                        GameVariantsListView(gameType: .chess)
                    }
                    
                    NavigationLink("Checkers Variants") {
                        GameVariantsListView(gameType: .checkers)
                    }
                    
                    NavigationLink("Connect Four Variants") {
                        GameVariantsListView(gameType: .connectFour)
                    }
                } header: {
                    Text("Regional Game Variants")
                } footer: {
                    Text("Explore different rules from around the world")
                }
            }
            .navigationTitle("Language & Region")
            .onChange(of: selectedLanguage) { _, newValue in
                languageService.setLanguage(newValue)
            }
        }
    }
    
    private var availableSecondaryLanguages: [Language] {
        Language.allSupported.filter { language in
            language.code != selectedLanguage.code &&
            !secondaryLanguages.contains(where: { $0.code == language.code })
        }
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = selectedTimezone
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: Date())
    }
    
    private func addSecondaryLanguage(_ language: Language) {
        secondaryLanguages.append(language)
        languageService.addSecondaryLanguage(language)
    }
    
    private func removeSecondaryLanguage(_ language: Language) {
        secondaryLanguages.removeAll { $0.code == language.code }
        languageService.removeSecondaryLanguage(language)
    }
    
    private var popularRegions: [(code: String, name: String, flag: String)] {
        [
            ("US", "United States", "🇺🇸"),
            ("BR", "Brazil", "🇧🇷"),
            ("GB", "United Kingdom", "🇬🇧"),
            ("IN", "India", "🇮🇳"),
            ("CN", "China", "🇨🇳"),
            ("JP", "Japan", "🇯🇵"),
            ("KR", "South Korea", "🇰🇷"),
            ("ES", "Spain", "🇪🇸"),
            ("FR", "France", "🇫🇷"),
            ("DE", "Germany", "🇩🇪"),
            ("MX", "Mexico", "🇲🇽"),
            ("AR", "Argentina", "🇦🇷"),
            ("SA", "Saudi Arabia", "🇸🇦"),
            ("AE", "UAE", "🇦🇪")
        ]
    }
}

/// View showing game variants
struct GameVariantsListView: View {
    let gameType: GameVariant.GameType
    
    var body: some View {
        List {
            ForEach(GameVariants.variants(for: gameType)) { variant in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(variant.name)
                            .font(.headline)
                        Spacer()
                        Text(variant.region)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Text(variant.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Rules
                    if !variant.rules.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Key Differences:")
                                .font(.caption)
                                .bold()
                            ForEach(Array(variant.rules.keys.sorted()), id: \.self) { key in
                                if let value = variant.rules[key] {
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("\(key.capitalized): \(value)")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("\(gameTypeName) Variants")
    }
    
    private var gameTypeName: String {
        switch gameType {
        case .chess: return "Chess"
        case .checkers: return "Checkers"
        case .connectFour: return "Connect Four"
        }
    }
}

#Preview {
    LanguageSettingsView()
}
