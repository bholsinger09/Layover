import SwiftUI

/// Language learning profile setup and editing view
public struct LanguageLearningProfileView: View {
    @State var viewModel: LanguageExchangeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var nativeLanguage: String = "en"
    @State private var learningLanguages: [LanguningLanguageGoal] = []
    @State private var selectedInterests: Set<CulturalInterest> = []
    @State private var preferences = LearningPreferences()
    @State private var showingAddLanguage = false
    
    public init(viewModel: LanguageExchangeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Native Language Section
                Section {
                    Picker("Native Language", selection: $nativeLanguage) {
                        ForEach(Language.allSupported, id: \.code) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.name)
                            }
                            .tag(language.code)
                        }
                    }
                } header: {
                    Text("Your Native Language")
                } footer: {
                    Text("The language you speak fluently")
                }
                
                // Learning Languages Section
                Section {
                    ForEach(learningLanguages) { goal in
                        LanguageGoalRow(goal: goal) {
                            if let index = learningLanguages.firstIndex(where: { $0.id == goal.id }) {
                                learningLanguages.remove(at: index)
                            }
                        }
                    }
                    
                    Button {
                        showingAddLanguage = true
                    } label: {
                        Label("Add Learning Language", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Languages You're Learning")
                } footer: {
                    Text("Add languages you want to practice")
                }
                
                // Cultural Interests
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(CulturalInterest.allCases, id: \.self) { interest in
                            InterestChip(
                                interest: interest,
                                isSelected: selectedInterests.contains(interest)
                            ) {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Cultural Interests")
                } footer: {
                    Text("Help us match you with like-minded language partners")
                }
                
                // Learning Preferences
                Section {
                    Toggle("Auto-translate messages", isOn: $preferences.autoTranslate)
                    Toggle("Show original with translation", isOn: $preferences.showOriginalWithTranslation)
                    Toggle("Auto-save vocabulary", isOn: $preferences.autoSaveVocabulary)
                    Toggle("Show pronunciation", isOn: $preferences.showPronunciation)
                    Toggle("Show cultural notes", isOn: $preferences.showCulturalNotes)
                    
                    Picker("Learning Method", selection: $preferences.preferredLearningMethod) {
                        ForEach(LearningMethod.allCases, id: \.self) { method in
                            VStack(alignment: .leading) {
                                Text(method.displayName)
                                Text(method.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(method)
                        }
                    }
                } header: {
                    Text("Learning Preferences")
                }
                
                // Statistics (if profile exists)
                if let profile = viewModel.userProfile {
                    Section {
                        StatRow(title: "Total Sessions", value: "\(profile.statistics.totalSessions)")
                        StatRow(title: "Practice Time", value: "\(profile.statistics.totalPracticeMinutes) min")
                        StatRow(title: "Vocabulary Learned", value: "\(profile.statistics.vocabularyLearned)")
                        StatRow(title: "Current Streak", value: "\(profile.statistics.currentStreak) days 🔥")
                        StatRow(title: "Longest Streak", value: "\(profile.statistics.longestStreak) days")
                    } header: {
                        Text("Your Statistics")
                    }
                }
            }
            .navigationTitle("Learning Profile")
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
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
            .sheet(isPresented: $showingAddLanguage) {
                AddLanguageGoalView { goal in
                    learningLanguages.append(goal)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadProfile() {
        guard let profile = viewModel.userProfile else { return }
        
        nativeLanguage = profile.nativeLanguage
        learningLanguages = profile.learningLanguages
        selectedInterests = Set(profile.culturalInterests)
        preferences = profile.preferences
    }
    
    private func saveProfile() {
        let profile = LanguageLearningProfile(
            id: viewModel.userProfile?.id ?? UUID(),
            userID: viewModel.userProfile?.userID ?? UUID(),
            nativeLanguage: nativeLanguage,
            learningLanguages: learningLanguages,
            preferences: preferences,
            achievements: viewModel.userProfile?.achievements ?? [],
            statistics: viewModel.userProfile?.statistics ?? LearningStatistics(),
            savedVocabulary: viewModel.userProfile?.savedVocabulary ?? [],
            culturalInterests: Array(selectedInterests)
        )
        
        viewModel.updateProfile(profile)
        dismiss()
    }
}

// MARK: - Subviews

struct LanguageGoalRow: View {
    let goal: LanguningLanguageGoal
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if let language = Language.from(code: goal.languageCode) {
                Text(language.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(goal.currentProficiency.rawValue) → \(goal.targetProficiency.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(goal.dailyGoalMinutes) min/day")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    ProgressView(value: goal.progress)
                        .tint(.blue)
                }
            }
            
            Spacer()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
    }
}

struct InterestChip: View {
    let interest: CulturalInterest
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Text(interest.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                #if os(iOS)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                #else
                .background(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
                #endif
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct AddLanguageGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (LanguningLanguageGoal) -> Void
    
    @State private var selectedLanguage: String = "es"
    @State private var currentProficiency: ProficiencyLevel = .beginner
    @State private var targetProficiency: ProficiencyLevel = .intermediate
    @State private var dailyGoal: Double = 30
    @State private var selectedMotivations: Set<LearningMotivation> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(Language.allSupported, id: \.code) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.name)
                            }
                            .tag(language.code)
                        }
                    }
                } header: {
                    Text("Which language?")
                }
                
                Section {
                    Picker("Current Level", selection: $currentProficiency) {
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                Text(level.description)
                                    .font(.caption)
                            }
                            .tag(level)
                        }
                    }
                    
                    Picker("Target Level", selection: $targetProficiency) {
                        ForEach(ProficiencyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                } header: {
                    Text("Proficiency")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(Int(dailyGoal)) minutes per day")
                            Spacer()
                        }
                        
                        Slider(value: $dailyGoal, in: 5...120, step: 5)
                    }
                } header: {
                    Text("Daily Goal")
                } footer: {
                    Text("Recommended: 30-60 minutes daily for best results")
                }
                
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(LearningMotivation.allCases, id: \.self) { motivation in
                            Button {
                                if selectedMotivations.contains(motivation) {
                                    selectedMotivations.remove(motivation)
                                } else {
                                    selectedMotivations.insert(motivation)
                                }
                            } label: {
                                HStack {
                                    Text(motivation.emoji)
                                    Text(motivation.rawValue)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                #if os(iOS)
                                .background(selectedMotivations.contains(motivation) ? Color.blue : Color(.systemGray5))
                                #else
                                .background(selectedMotivations.contains(motivation) ? Color.blue : Color(nsColor: .controlBackgroundColor))
                                #endif
                                .foregroundStyle(selectedMotivations.contains(motivation) ? .white : .primary)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Why are you learning?")
                }
            }
            .navigationTitle("Add Learning Goal")
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
                    Button("Add") {
                        let goal = LanguningLanguageGoal(
                            languageCode: selectedLanguage,
                            targetProficiency: targetProficiency,
                            currentProficiency: currentProficiency,
                            dailyGoalMinutes: Int(dailyGoal),
                            motivations: Array(selectedMotivations)
                        )
                        onAdd(goal)
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    LanguageLearningProfileView(viewModel: LanguageExchangeViewModel())
}
#endif
