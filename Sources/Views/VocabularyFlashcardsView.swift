import SwiftUI

/// Vocabulary flashcards view for reviewing learned words
public struct VocabularyFlashcardsView: View {
    @State var viewModel: LanguageExchangeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentCardIndex = 0
    @State private var showAnswer = false
    @State private var filter: VocabularyFilter = .needsReview
    
    public init(viewModel: LanguageExchangeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    private var filteredCards: [VocabularyCard] {
        switch filter {
        case .all:
            return viewModel.vocabularyCards
        case .needsReview:
            return viewModel.vocabularyNeedingReview
        case .category(let cat):
            return viewModel.vocabularyCards.filter { $0.category == cat }
        case .difficulty(let diff):
            return viewModel.vocabularyCards.filter { $0.difficulty == diff }
        }
    }
    
    private var currentCard: VocabularyCard? {
        guard !filteredCards.isEmpty, currentCardIndex < filteredCards.count else {
            return nil
        }
        return filteredCards[currentCardIndex]
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header with stats
                headerView
                
                // Filter picker
                Picker("Filter", selection: $filter) {
                    Text("Needs Review (\(viewModel.vocabularyNeedingReview.count))")
                        .tag(VocabularyFilter.needsReview)
                    Text("All (\(viewModel.vocabularyCards.count))")
                        .tag(VocabularyFilter.all)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Flashcard
                if let card = currentCard {
                    flashcardView(for: card)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    emptyStateView
                }
                
                Spacer()
                
                // Navigation controls
                if currentCard != nil {
                    navigationControlsView
                }
            }
            .navigationTitle("Vocabulary Practice")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(VocabularyCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                filter = .category(category)
                                currentCardIndex = 0
                            }
                        }
                    } label: {
                        Label("Filter by Category", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 30) {
                statView(title: "Total", value: "\(viewModel.vocabularyCards.count)")
                statView(title: "Review", value: "\(viewModel.vocabularyNeedingReview.count)")
                statView(title: "Mastered", value: "\(viewModel.vocabularyCards.filter { $0.masteryLevel >= 0.8 }.count)")
            }
            
            if !filteredCards.isEmpty {
                ProgressView(value: Double(currentCardIndex + 1), total: Double(filteredCards.count))
                    .padding(.horizontal, 40)
                
                Text("\(currentCardIndex + 1) / \(filteredCards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    private func statView(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func flashcardView(for card: VocabularyCard) -> some View {
        VStack(spacing: 20) {
            // Card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    #if os(iOS)
                    .fill(Color(.systemBackground))
                    #else
                    .fill(Color(nsColor: .windowBackgroundColor))
                    #endif
                    .shadow(color: .black.opacity(0.1), radius: 10)
                
                VStack(spacing: 24) {
                    // Word
                    VStack(spacing: 8) {
                        Text(card.word)
                            .font(.system(size: 36, weight: .bold))
                        
                        if let pronunciation = card.pronunciation {
                            Text(pronunciation)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Language badge
                        HStack {
                            if let lang = Language.from(code: card.language) {
                                Text("\(lang.flag) \(lang.name)")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            // Difficulty badge
                            Text(card.difficulty.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(difficultyColor(card.difficulty).opacity(0.2))
                                .foregroundStyle(difficultyColor(card.difficulty))
                                .cornerRadius(8)
                        }
                    }
                    
                    Divider()
                    
                    // Translation (revealed)
                    if showAnswer {
                        VStack(spacing: 12) {
                            Text(card.translation)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let example = card.exampleSentence {
                                Text(example)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Context
                            Text(card.context)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                        .transition(.opacity)
                    } else {
                        Button {
                            withAnimation {
                                showAnswer = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "eye")
                                Text("Show Translation")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Mastery progress
                    VStack(spacing: 4) {
                        ProgressView(value: card.masteryLevel)
                            .tint(masteryColor(card.masteryLevel))
                        Text("Mastery: \(Int(card.masteryLevel * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(30)
            }
            .frame(maxHeight: 500)
            .padding(.horizontal, 20)
            
            // Answer buttons
            if showAnswer {
                HStack(spacing: 20) {
                    Button {
                        markAnswer(correct: false)
                    } label: {
                        Label("Hard", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        markAnswer(correct: true)
                    } label: {
                        Label("Easy", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No vocabulary cards")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Start a language exchange session to learn new words!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    private var navigationControlsView: some View {
        HStack(spacing: 40) {
            Button {
                previousCard()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(currentCardIndex > 0 ? .blue : .gray)
            }
            .disabled(currentCardIndex == 0)
            
            Button {
                nextCard()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(currentCardIndex < filteredCards.count - 1 ? .blue : .gray)
            }
            .disabled(currentCardIndex >= filteredCards.count - 1)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func nextCard() {
        guard currentCardIndex < filteredCards.count - 1 else { return }
        
        withAnimation {
            currentCardIndex += 1
            showAnswer = false
        }
    }
    
    private func previousCard() {
        guard currentCardIndex > 0 else { return }
        
        withAnimation {
            currentCardIndex -= 1
            showAnswer = false
        }
    }
    
    private func markAnswer(correct: Bool) {
        guard let card = currentCard else { return }
        
        viewModel.reviewVocabularyCard(card, correct: correct)
        
        // Move to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentCardIndex < filteredCards.count - 1 {
                nextCard()
            } else {
                // Completed all cards
                showAnswer = false
            }
        }
    }
    
    // MARK: - Helpers
    
    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    private func masteryColor(_ mastery: Double) -> Color {
        if mastery < 0.3 { return .red }
        if mastery < 0.6 { return .orange }
        if mastery < 0.8 { return .blue }
        return .green
    }
}

enum VocabularyFilter: Hashable {
    case all
    case needsReview
    case category(VocabularyCategory)
    case difficulty(DifficultyLevel)
}

#if DEBUG
#Preview {
    VocabularyFlashcardsView(viewModel: {
        let vm = LanguageExchangeViewModel()
        vm.vocabularyCards = [
            VocabularyCard(
                word: "こんにちは",
                translation: "Hello",
                language: "ja",
                targetLanguage: "en",
                context: "From chat with Yuki",
                exampleSentence: "こんにちは、元気ですか？",
                pronunciation: "konnichiwa",
                category: .general,
                difficulty: .beginner,
                masteryLevel: 0.6
            ),
            VocabularyCard(
                word: "감사합니다",
                translation: "Thank you",
                language: "ko",
                targetLanguage: "en",
                context: "From K-Drama episode",
                exampleSentence: "정말 감사합니다!",
                pronunciation: "gamsahamnida",
                category: .general,
                difficulty: .beginner,
                masteryLevel: 0.3
            )
        ]
        return vm
    }())
}
#endif
