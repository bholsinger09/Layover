import SwiftUI

// MARK: - Stories Tab

struct LibraryStoriesTab: View {
    let viewModel: LibraryViewModel
    @Binding var searchText: String
    @State private var selectedStory: Story?
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sampleStories.filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }) { story in
                            StoryRowView(story: story)
                                .onTapGesture {
                                    selectedStory = story
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(item: $selectedStory) { story in
                StoryReaderView(story: story)
            }
        }
    }
    
    private let sampleStories: [Story] = [
        Story(
            title: "The Legend of Sleepy Hollow",
            author: "Washington Irving",
            genre: "Gothic Fiction",
            duration: "12 min read",
            content: "In the bosom of one of those spacious coves which indent the eastern shore of the Hudson..."
        ),
        Story(
            title: "The Yellow Wallpaper",
            author: "Charlotte Perkins Gilman",
            genre: "Psychological Fiction",
            duration: "15 min read",
            content: "It is very seldom that mere ordinary people like John and myself secure ancestral halls..."
        ),
        Story(
            title: "The Masque of the Red Death",
            author: "Edgar Allan Poe",
            genre: "Gothic Horror",
            duration: "10 min read",
            content: "The Red Death had long devastated the country..."
        ),
    ]
}

// MARK: - Story Model

struct Story: Identifiable, Hashable {
    let id: UUID
    let title: String
    let author: String
    let genre: String
    let duration: String
    let content: String
    
    init(title: String, author: String, genre: String, duration: String, content: String) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.genre = genre
        self.duration = duration
        self.content = content
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Story, rhs: Story) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Story Reader View

struct StoryReaderView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(story.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(story.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Text("by \(story.author)")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            HStack {
                                Text(story.genre)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Text(story.duration)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        Text(story.content)
                            .font(.body)
                            .lineSpacing(8)
                            .foregroundStyle(.white)
                    }
                    .padding()
                }
                .background(Color.black)
            }
        }
    }
}

// MARK: - Story Row View

struct StoryRowView: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("by \(story.author)")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(story.genre)
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(story.duration)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 12)
    }
}
