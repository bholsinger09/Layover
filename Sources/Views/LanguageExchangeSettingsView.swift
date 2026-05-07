import SwiftUI

/// Settings view for language exchange mode
public struct LanguageExchangeSettingsView: View {
    @State var viewModel: LanguageExchangeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMode: ExchangeMode
    
    public init(viewModel: LanguageExchangeViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._selectedMode = State(initialValue: viewModel.currentSession?.mode ?? .balanced)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Current Session Info
                if let session = viewModel.currentSession {
                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(viewModel.sessionDuration)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Messages")
                            Spacer()
                            Text("\(session.statistics.messagesExchanged)")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Vocabulary")
                            Spacer()
                            Text("\(session.statistics.vocabularyLearned)")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Current Session")
                    }
                }
                
                // Exchange Mode
                Section {
                    ForEach([ExchangeMode.balanced, ExchangeMode.free], id: \.self) { mode in
                        modeRow(mode: mode)
                    }
                    
                    // Focus modes for each language
                    if let session = viewModel.currentSession {
                        ForEach(session.participants, id: \.id) { participant in
                            if let lang = Language.from(code: participant.nativeLanguage) {
                                modeRow(mode: .focusOn(participant.nativeLanguage), languageName: lang.name, flag: lang.flag)
                            }
                        }
                    }
                } header: {
                    Text("Exchange Mode")
                } footer: {
                    Text(selectedMode.displayName + " - " + modeDescription(selectedMode))
                }
                
                // Display Options
                Section {
                    Toggle("Show original text", isOn: $viewModel.showOriginalText)
                    
                    if let profile = viewModel.userProfile {
                        Toggle("Auto-translate", isOn: Binding(
                            get: { profile.preferences.autoTranslate },
                            set: { _ in }
                        ))
                        .disabled(true)
                        
                        Toggle("Auto-save vocabulary", isOn: Binding(
                            get: { profile.preferences.autoSaveVocabulary },
                            set: { _ in }
                        ))
                        .disabled(true)
                        
                        Toggle("Show cultural notes", isOn: Binding(
                            get: { profile.preferences.showCulturalNotes },
                            set: { _ in }
                        ))
                        .disabled(true)
                        
                        NavigationLink {
                            LanguageLearningProfileView(viewModel: viewModel)
                        } label: {
                            Text("Edit Learning Profile")
                        }
                    }
                } header: {
                    Text("Display Options")
                } footer: {
                    Text("Change more settings in your learning profile")
                }
                
                // Participants
                if let session = viewModel.currentSession {
                    Section {
                        ForEach(session.participants) { participant in
                            ParticipantRow(participant: participant)
                        }
                    } header: {
                        Text("Participants (\(session.participants.count))")
                    }
                }
                
                // Quick Actions
                Section {
                    Button {
                        viewModel.findPartners(learningLanguage: viewModel.userProfile?.learningLanguages.first?.languageCode ?? "en")
                    } label: {
                        Label("Find Language Partners", systemImage: "person.2.fill")
                    }
                    
                    Button {
                        viewModel.showVocabularySheet = true
                        dismiss()
                    } label: {
                        Label("Practice Vocabulary", systemImage: "book.fill")
                    }
                } header: {
                    Text("Quick Actions")
                }
            }
            .navigationTitle("Language Exchange")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedMode) { _, newMode in
                viewModel.switchMode(to: newMode)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func modeRow(mode: ExchangeMode, languageName: String? = nil, flag: String? = nil) -> some View {
        Button {
            selectedMode = mode
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let name = languageName, let emoji = flag {
                        Text("\(emoji) Focus on \(name)")
                            .foregroundStyle(.primary)
                    } else {
                        Text(mode.displayName)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(modeDescription(mode))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if selectedMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
    
    private func modeDescription(_ mode: ExchangeMode) -> String {
        switch mode {
        case .balanced:
            return "Alternate between languages every 15 minutes"
        case .focusOn(let code):
            if let lang = Language.from(code: code) {
                return "Practice \(lang.name) exclusively"
            }
            return "Focus on one language"
        case .free:
            return "Speak whatever language you prefer"
        }
    }
}

struct ParticipantRow: View {
    let participant: LanguageExchangeParticipant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(participant.username.prefix(1)))
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.username)
                        .font(.headline)
                    
                    if let native = Language.from(code: participant.nativeLanguage) {
                        HStack(spacing: 4) {
                            Text(native.flag)
                            Text("Native: \(native.name)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Learning languages
            if !participant.learningLanguages.isEmpty {
                HStack(spacing: 8) {
                    Text("Learning:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(participant.learningLanguages, id: \.self) { langCode in
                        if let lang = Language.from(code: langCode) {
                            HStack(spacing: 2) {
                                Text(lang.flag)
                                Text(lang.name)
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Shared interests
            if !participant.interests.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("Interests:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ForEach(participant.interests.prefix(5), id: \.self) { interest in
                            Text(interest.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                #if os(iOS)
                                .background(Color(.systemGray6))
                                #else
                                .background(Color(nsColor: .controlBackgroundColor))
                                #endif
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    LanguageExchangeSettingsView(viewModel: {
        let vm = LanguageExchangeViewModel()
        vm.currentSession = LanguageExchangeSession(
            roomID: UUID(),
            participants: [
                LanguageExchangeParticipant(
                    userID: UUID(),
                    username: "Yuki",
                    nativeLanguage: "ja",
                    learningLanguages: ["en"],
                    interests: [.anime, .jDrama]
                ),
                LanguageExchangeParticipant(
                    userID: UUID(),
                    username: "Sarah",
                    nativeLanguage: "en",
                    learningLanguages: ["ja"],
                    interests: [.anime, .kpop]
                )
            ]
        )
        return vm
    }())
}
#endif
