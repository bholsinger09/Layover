import SwiftUI

/// Main language exchange view with chat and vocabulary features
public struct LanguageExchangeView: View {
    @State private var viewModel: LanguageExchangeViewModel
    let room: Room
    let currentUser: User
    
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var selectedReactionMessage: UUID?
    @State private var showEndSessionConfirmation = false
    
    public init(room: Room, currentUser: User, viewModel: LanguageExchangeViewModel = LanguageExchangeViewModel()) {
        self.room = room
        self.currentUser = currentUser
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Welcome banner if session not started
            if !viewModel.isSessionActive {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "globe.americas.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome to Language Exchange")
                                .font(.headline)
                            Text("Start a session to practice languages with real-time translation")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Start Session") {
                            startSession()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    #if os(iOS)
                    .background(Color(.systemBackground))
                    #else
                    .background(Color(nsColor: .windowBackgroundColor))
                    #endif
                }
                .background(Color.blue.opacity(0.1))
            }
            
            // Active language indicator
            if let hint = viewModel.currentLanguageHint {
                HStack {
                    Image(systemName: "globe")
                    Text(hint)
                        .font(.subheadline)
                    Spacer()
                    if viewModel.isSessionActive {
                        Text(viewModel.sessionDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
            }
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                currentUserID: currentUser.id,
                                userLanguage: viewModel.targetLanguage,
                                showOriginal: viewModel.showOriginalText,
                                onReaction: { emoji in
                                    viewModel.addReaction(to: message.id, emoji: emoji, from: currentUser.id)
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            
            // Input area
            messageInputView
        }
        .navigationTitle("Language Exchange")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Vocabulary button
                Button {
                    viewModel.showVocabularySheet = true
                } label: {
                    Label("Vocabulary", systemImage: "book.fill")
                }
                
                // Settings button
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                
                // Start/End session
                if viewModel.isSessionActive {
                    Button("End Session") {
                        viewModel.endSession()
                    }
                    .foregroundStyle(.red)
                } else {
                    Button("Start Session") {
                        startSession()
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            LanguageExchangeSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showVocabularySheet) {
            VocabularyFlashcardsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showProfile) {
            LanguageLearningProfileView(viewModel: viewModel)
        }
        .confirmationDialog(
            "End Language Exchange Session?",
            isPresented: $showEndSessionConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Session", role: .destructive) {
                endSession()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
        .onAppear {
            // Load profile in background
            Task { @MainActor in
                viewModel.loadProfile(for: currentUser.id)
                viewModel.currentRoomID = room.id
                viewModel.loadMessages()
                
                // Create a default profile if none exists
                if viewModel.userProfile == nil {
                    let defaultProfile = LanguageLearningProfile(
                        userID: currentUser.id,
                        nativeLanguage: "en",
                        learningLanguages: [
                            LanguningLanguageGoal(
                                languageCode: "es",
                                targetProficiency: .intermediate,
                                currentProficiency: .beginner
                            )
                        ]
                    )
                    viewModel.updateProfile(defaultProfile)
                    viewModel.targetLanguage = "es" // Set default target
                }
                
                // Set target language from profile if available
                if let firstGoal = viewModel.userProfile?.learningLanguages.first {
                    viewModel.targetLanguage = firstGoal.languageCode
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.headline)
                
                if viewModel.isSessionActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Exchange Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // End Session button (when active)
            if viewModel.isSessionActive {
                Button {
                    showEndSessionConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.circle")
                        Text("End Session")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            // Participants count
            HStack(spacing: -8) {
                ForEach(room.participants.prefix(3)) { participant in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String(participant.username.prefix(1)))
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                }
                
                if room.participants.count > 3 {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("+\(room.participants.count - 3)")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }
    
    private var messageInputView: some View {
        VStack(spacing: 8) {
            // Language selectors and toggle
            HStack(spacing: 12) {
                // Speaking language picker
                VStack(alignment: .leading, spacing: 2) {
                    Text("Speaking:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(Language.allSupported, id: \.code) { language in
                            Button {
                                viewModel.selectedLanguage = language.code
                            } label: {
                                HStack {
                                    Text("\(language.flag) \(language.name)")
                                    if viewModel.selectedLanguage == language.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let lang = Language.from(code: viewModel.selectedLanguage) {
                                Text("\(lang.flag) \(lang.name)")
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        #if os(iOS)
                        .background(Color(.systemGray6))
                        #else
                        .background(Color(nsColor: .controlBackgroundColor))
                        #endif
                        .cornerRadius(8)
                    }
                    .disabled(!viewModel.isSessionActive)
                }
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Target language picker (learning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Translate to:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        ForEach(Language.allSupported, id: \.code) { language in
                            Button {
                                viewModel.targetLanguage = language.code
                            } label: {
                                HStack {
                                    Text("\(language.flag) \(language.name)")
                                    if viewModel.targetLanguage == language.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let lang = Language.from(code: viewModel.targetLanguage) {
                                Text("\(lang.flag) \(lang.name)")
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        #if os(iOS)
                        .background(Color(.systemGray6))
                        #else
                        .background(Color(nsColor: .controlBackgroundColor))
                        #endif
                        .cornerRadius(8)
                    }
                    .disabled(!viewModel.isSessionActive)
                }
                
                Spacer()
                
                // Toggle for showing original vs translation
                Toggle(isOn: $viewModel.showOriginalText) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showOriginalText ? "doc.text" : "doc.text.below.ecg")
                        Text(viewModel.showOriginalText ? "Original" : "Translated")
                    }
                    .font(.caption)
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .disabled(!viewModel.isSessionActive)
            }
            .padding(.horizontal)
            
            // Message input
            HStack(spacing: 12) {
                #if os(iOS)
                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(!viewModel.isSessionActive)
                #else
                TextField("Type a message...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!viewModel.isSessionActive)
                #endif
                
                Button {
                    Task {
                        await viewModel.sendMessage(
                            senderID: currentUser.id,
                            senderUsername: currentUser.username
                        )
                    }
                } label: {
                    Image(systemName: viewModel.isTranslating ? "arrow.triangle.2.circlepath" : "paperplane.fill")
                        .foregroundStyle(viewModel.messageText.isEmpty ? .gray : .blue)
                }
                .disabled(!viewModel.isSessionActive || viewModel.messageText.isEmpty || viewModel.isTranslating)
                #if os(iOS)
                .buttonStyle(.borderless)
                #endif
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        #if os(iOS)
        .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
        #endif
    }
    
    // MARK: - Actions
    
    private func startSession() {
        let mode: ExchangeMode = viewModel.userProfile?.preferences.preferredLearningMethod == .immersion ?
            .focusOn(viewModel.userProfile?.learningLanguages.first?.languageCode ?? "en") :
            .balanced
        
        viewModel.startSession(
            roomID: room.id,
            participants: room.participants,
            mode: mode,
            currentUserID: currentUser.id
        )
    }
    
    private func endSession() {
        viewModel.endSession()
    }
}

/// Message bubble view with translation
struct MessageBubbleView: View {
    let message: ChatMessage
    let currentUserID: UUID
    let userLanguage: String
    let showOriginal: Bool
    let onReaction: (String) -> Void
    
    @State private var showReactions = false
    
    private var isCurrentUser: Bool {
        message.senderID == currentUserID
    }
    
    private var displayText: String {
        if showOriginal {
            return message.originalText
        }
        return message.text(for: userLanguage)
    }
    
    private var isTranslated: Bool {
        !showOriginal && message.originalLanguage != userLanguage && message.hasTranslation(for: userLanguage)
    }
    
    private var showBothLanguages: Bool {
        !showOriginal && isTranslated
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Username
                if !isCurrentUser {
                    Text(message.senderUsername)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Message bubble
                VStack(alignment: .leading, spacing: 6) {
                    // Translated text (main)
                    if showBothLanguages {
                        Text(displayText)
                            .font(.body)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        
                        // Original text (secondary)
                        HStack {
                            Image(systemName: "globe")
                                .font(.caption2)
                            Text(message.originalText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    } else {
                        Text(displayText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                }
                #if os(iOS)
                .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                #else
                .background(isCurrentUser ? Color.blue : Color(nsColor: .controlBackgroundColor))
                #endif
                .foregroundStyle(isCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .contextMenu {
                    Button("React") {
                        showReactions = true
                    }
                    if isTranslated {
                        Button("Show Original") {
                            // Toggle original
                        }
                    }
                }
                
                // Reactions
                if !message.reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.reactions.keys.sorted(), id: \.self) { emoji in
                            if let users = message.reactions[emoji], !users.isEmpty {
                                Text("\(emoji) \(users.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    #if os(iOS)
                                    .background(Color(.systemGray6))
                                    #else
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    #endif
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .sheet(isPresented: $showReactions) {
            ReactionPickerView(onReact: onReaction)
        }
    }
}

/// Reaction picker view
struct ReactionPickerView: View {
    let onReact: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let reactions = ["👍", "❤️", "😂", "😮", "🎉", "🔥", "💯", "🙌"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Reaction")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                ForEach(reactions, id: \.self) { emoji in
                    Button {
                        onReact(emoji)
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 40))
                    }
                }
            }
            .padding()
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LanguageExchangeView(
            room: Room(
                name: "K-Drama Watch Party",
                hostID: UUID(),
                participants: [
                    User(username: "Alice"),
                    User(username: "Bob"),
                    User(username: "Carol")
                ],
                activityType: .appleTVPlus,
                primaryLanguage: "ko"
            ),
            currentUser: User(username: "You")
        )
    }
}
#endif
