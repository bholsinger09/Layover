import SwiftUI

/// Main library view showing favorites, history, stats, and recommendations
public struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var selectedTab = 0
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    public init(libraryService: LibraryServiceProtocol) {
        self._viewModel = State(initialValue: LibraryViewModel(libraryService: libraryService))
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Content Type", selection: $selectedTab) {
                    Text("Music").tag(0)
                    Text("Read a Short Story").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    MusicTabView(viewModel: viewModel, searchText: $searchText)
                        .tag(0)
                    
                    StoryTabView(viewModel: viewModel, searchText: $searchText)
                        .tag(1)
                }
                #if !os(macOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("My Library")
            .refreshable {
                viewModel.loadLibraryData()
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
    }
}

/// Movies & TV Shows tab
struct MoviesTabView: View {
    let viewModel: LibraryViewModel
    @Binding var searchText: String
    @State private var showSearchAlert = false
    
    var movieFavorites: [MediaContent] {
        let filtered = viewModel.favorites.filter { $0.contentType == .movie || $0.contentType == .tvShow }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var movieHistory: [WatchHistoryItem] {
        let filtered = viewModel.recentlyWatched.filter { $0.content.contentType == .movie || $0.content.contentType == .tvShow }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.content.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var movieRecommendations: [MediaContent] {
        let filtered = viewModel.recommendations.filter { $0.contentType == .movie || $0.contentType == .tvShow }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Search Results Section
                if !viewModel.aiMovieResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Search Results (\(viewModel.aiMovieResults.count))")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearAIResults()
                                searchText = ""
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.aiMovieResults, id: \.contentID) { content in
                                    ContentCardView(content: content, libraryViewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if !searchText.isEmpty && !viewModel.isSearching {
                    // Show message when search completed but no results
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Click the 'AI search' button below")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Results will appear here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
                
                // Loading indicator
                if viewModel.isSearching {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Searching with AI...")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                // Stats Overview Card
                if let stats = viewModel.stats {
                    StatsCardView(stats: stats)
                        .padding(.horizontal)
                }
                
                // Recommendations Section
                if !movieRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(movieRecommendations, id: \.contentID) { content in
                                    ContentCardView(content: content, libraryViewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Favorites Section
                if !movieFavorites.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Favorites")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink {
                                FavoritesListView(viewModel: viewModel)
                            } label: {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(movieFavorites.prefix(10), id: \.contentID) { content in
                                    ContentCardView(content: content, libraryViewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Recently Watched Section
                if !movieHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recently Watched")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            NavigationLink {
                                WatchHistoryView(viewModel: viewModel)
                            } label: {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            ForEach(movieHistory.prefix(5)) { item in
                                HistoryRowView(item: item, libraryViewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Empty State
                if movieFavorites.isEmpty && movieHistory.isEmpty {
                    ContentUnavailableView {
                        Label("No Movies or TV Shows Yet", systemImage: "tv")
                    } description: {
                        Text("Start watching content and adding favorites to build your library")
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
        .alert("Web Search", isPresented: $showSearchAlert) {
            Button("OK") { }
        } message: {
            Text("Opening Google search for: '\(searchText)'")
        }
    }
    
    private func searchWeb(query: String, context: String) {
        guard !query.isEmpty else { return }
        let searchQuery = "\(query) \(context)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.google.com/search?q=\(searchQuery)") else {
            print("❌ Failed to create URL for query: \(query)")
            return
        }
        
        print("🔍 Opening web search: \(url.absoluteString)")
        
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
}

/// Story Reading tab
struct StoryTabView: View {
    let viewModel: LibraryViewModel
    @Binding var searchText: String
    @State private var selectedStory: Story?
    
    // Sample short stories - All Public Domain
    private let sampleStories = [
        Story(
            title: "The Legend of Sleepy Hollow",
            author: "Washington Irving",
            genre: "Gothic Fiction",
            duration: "12 min read",
            content: """
            In the bosom of one of those spacious coves which indent the eastern shore of the Hudson, at that broad expansion of the river denominated by the ancient Dutch navigators the Tappan Zee, there lies a small market town which is generally known by the name of Tarry Town.
            
            Not far from this village, perhaps about two miles, there is a little valley among high hills, which is one of the quietest places in the whole world. A small brook glides through it, with just murmur enough to lull one to repose; and the occasional whistle of a quail or tapping of a woodpecker is almost the only sound that ever breaks in upon the uniform tranquility.
            
            From the listless repose of the place, and the peculiar character of its inhabitants, who are descendants from the original Dutch settlers, this sequestered glen has long been known by the name of SLEEPY HOLLOW. A drowsy, dreamy influence seems to hang over the land, and to pervade the very atmosphere.
            
            The dominant spirit that haunts this enchanted region is the apparition of a figure on horseback without a head. It is said to be the ghost of a Hessian trooper, whose head had been carried away by a cannon-ball in some nameless battle during the Revolutionary War.
            
            [This classic tale of Ichabod Crane and the Headless Horseman remains a beloved American ghost story.]
            """
        ),
        Story(
            title: "The Yellow Wallpaper",
            author: "Charlotte Perkins Gilman",
            genre: "Psychological Fiction",
            duration: "15 min read",
            content: """
            It is very seldom that mere ordinary people like John and myself secure ancestral halls for the summer. A colonial mansion, a hereditary estate, I would say a haunted house, and reach the height of romantic felicity—but that would be asking too much of fate!
            
            Still I will proudly declare that there is something queer about it. Else, why should it be let so cheaply? And why have stood so long untenanted?
            
            John is practical in the extreme. He has no patience with faith, an intense horror of superstition, and he scoffs openly at any talk of things not to be felt and seen and put down in figures. John is a physician, and perhaps—I would not say it to a living soul, of course, but this is dead paper and a great relief to my mind—perhaps that is one reason I do not get well faster.
            
            You see, he does not believe I am sick! And what can one do? If a physician of high standing, and one's own husband, assures friends and relatives that there is really nothing the matter with one but temporary nervous depression—a slight hysterical tendency—what is one to do?
            
            [A powerful exploration of mental health and the constraints placed on women in the 19th century.]
            """
        ),
        Story(
            title: "The Masque of the Red Death",
            author: "Edgar Allan Poe",
            genre: "Gothic Horror",
            duration: "10 min read",
            content: """
            The "Red Death" had long devastated the country. No pestilence had ever been so fatal, or so hideous. Blood was its Avatar and its seal—the redness and the horror of blood. There were sharp pains, and sudden dizziness, and then profuse bleeding at the pores, with dissolution.
            
            But the Prince Prospero was happy and dauntless and sagacious. When his dominions were half depopulated, he summoned to his presence a thousand hale and light-hearted friends from among the knights and dames of his court, and with these retired to the deep seclusion of one of his castellated abbeys.
            
            A strong and lofty wall girdled it in. This wall had gates of iron. The courtiers, having entered, brought furnaces and massy hammers and welded the bolts. They resolved to leave means neither of ingress nor egress to the sudden impulses of despair or of frenzy from within.
            
            It was toward the close of the fifth or sixth month of his seclusion that the Prince Prospero entertained his thousand friends at a masked ball of the most unusual magnificence. It was a voluptuous scene, that masquerade.
            
            [Poe's haunting allegory about the inevitability of death, written in 1842.]
            """
        ),
        Story(
            title: "An Occurrence at Owl Creek Bridge",
            author: "Ambrose Bierce",
            genre: "War Fiction",
            duration: "12 min read",
            content: """
            A man stood upon a railroad bridge in northern Alabama, looking down into the swift water twenty feet below. The man's hands were behind his back, the wrists bound with a cord. A rope closely encircled his neck.
            
            Peyton Farquhar was a well-to-do planter, of an old and highly respected Alabama family. Being a slave owner and like other slave owners a politician, he was naturally an original secessionist and ardently devoted to the Southern cause.
            
            Circumstances of an imperious nature, which it is unnecessary to relate here, had prevented him from taking service with the gallant army. Meanwhile, he did what he could. No service was too humble for him to perform in aid of the South, no adventure too perilous for him to undertake.
            
            As Peyton Farquhar fell straight downward through the bridge he lost consciousness and was as one already dead. From this state he was awakened—ages later, it seemed to him—by the pain of a sharp pressure upon his throat, followed by a sense of suffocation.
            
            [Bierce's masterful tale of the Civil War, known for its unexpected twist ending.]
            """
        ),
        Story(
            title: "The Lady, or the Tiger?",
            author: "Frank R. Stockton",
            genre: "Fantasy",
            duration: "10 min read",
            content: """
            In the very olden time there lived a semi-barbaric king, whose ideas, though somewhat polished and sharpened by the progressiveness of distant Latin neighbors, were still large, florid, and untrammeled, as became the half of him which was barbaric.
            
            Among the borrowed notions by which his barbarism had become semified was that of the public arena, in which, by exhibitions of manly and beastly valor, the minds of his subjects were refined and cultured. But even here the exuberant and barbaric fancy asserted itself.
            
            When a subject was accused of a crime of sufficient importance to interest the king, public notice was given that on an appointed day the fate of the accused person would be decided in the king's arena, a structure which well deserved its name.
            
            When all the people had assembled in the galleries, the king gave a signal, a door beneath him opened, and the accused subject stepped out into the amphitheater. Directly opposite were two doors, exactly alike and side by side. Behind one door was a hungry tiger; behind the other was a lady.
            
            [A thought-provoking tale that leaves readers to decide the ending themselves.]
            """
        ),
        Story(
            title: "The Celebrated Jumping Frog",
            author: "Mark Twain",
            genre: "Humor",
            duration: "8 min read",
            content: """
            In compliance with the request of a friend of mine, who wrote me from the East, I called on good-natured, garrulous old Simon Wheeler, and inquired after my friend's friend, Leonidas W. Smiley, as requested to do, and I hereunto append the result.
            
            I found Simon Wheeler dozing comfortably by the bar-room stove of the dilapidated tavern in the decayed mining camp of Angel's, and I noticed that he was fat and bald-headed, and had an expression of winning gentleness and simplicity upon his tranquil countenance.
            
            He never smiled, he never frowned, he never changed his voice from the gentle-flowing key to which he tuned his initial sentence, he never betrayed the slightest suspicion of enthusiasm; but all through the interminable narrative there ran a vein of impressive earnestness and sincerity.
            
            "Rev. Leonidas W. H'm, Reverend Le—well, there was a feller here once by the name of Jim Smiley, in the winter of '49—or maybe it was the spring of '50—I don't recollect exactly, somehow, though what makes me think it was one or the other is because I remember the big flume warn't finished when he first come to the camp."
            
            [Mark Twain's humorous tale of a betting man and his talented frog, published in 1865.]
            """
        ),
    ]
    
    var filteredStories: [Story] {
        if searchText.isEmpty {
            return sampleStories
        }
        return sampleStories.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText) ||
            $0.genre.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        Text("Short Stories")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text("Classic tales to enjoy")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Stories List
                if filteredStories.isEmpty {
                    ContentUnavailableView {
                        Label("No Stories Found", systemImage: "book")
                    } description: {
                        Text("Try a different search term")
                    }
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredStories) { story in
                            Button {
                                selectedStory = story
                            } label: {
                                StoryRowView(story: story)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        #if os(tvOS)
        .fullScreenCover(item: $selectedStory) { story in
            StoryReaderView(story: story)
        }
        #else
        .sheet(item: $selectedStory) { story in
            StoryReaderView(story: story)
        }
        #endif
    }
}

/// Story model
struct Story: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let genre: String
    let duration: String
    let content: String
}

/// Story Reader View
struct StoryReaderView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    
    var paragraphs: [String] {
        story.content.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }
    
    var body: some View {
        ZStack {
            // Opaque background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(story.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("by \(story.author)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            Label(story.genre, systemImage: "tag")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            
                            Label(story.duration, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(40)
                
                Divider()
                
                // Scrollable story content - each paragraph as a focusable row
                List(paragraphs.indices, id: \.self) { index in
                    #if os(tvOS)
                    Button(action: {}) {
                        Text(paragraphs[index])
                            .font(.title3)
                            .lineSpacing(12)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                    #else
                    Text(paragraphs[index])
                        .font(.title3)
                        .lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 8)
                    #endif
                }
                .listStyle(.plain)
                .padding(.horizontal, 40)
            }
        }
    }
}

/// Story row view
struct StoryRowView: View {
    let story: Story
    
    var body: some View {
        HStack(spacing: 16) {
            // Book icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 80)
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            // Story info
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("by \(story.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Label(story.genre, systemImage: "tag")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    Label(story.duration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Read button
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        #if os(tvOS)
        .background(Color.gray.opacity(0.2))
        #else
        .background(Color(.systemGray6))
        #endif
        .cornerRadius(12)
    }
}

/// Music tab
struct MusicTabView: View {
    let viewModel: LibraryViewModel
    @Binding var searchText: String
    @State private var showCreatePlaylist = false
    
    var filteredFavoriteTracks: [MusicTrack] {
        if searchText.isEmpty {
            return viewModel.favoriteTracks
        }
        return viewModel.favoriteTracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredPlaylists: [MusicPlaylist] {
        if searchText.isEmpty {
            return viewModel.playlists
        }
        return viewModel.playlists.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var filteredMusicHistory: [MusicHistoryItem] {
        if searchText.isEmpty {
            return viewModel.musicHistory
        }
        return viewModel.musicHistory.filter {
            $0.track.title.localizedCaseInsensitiveContains(searchText) ||
            $0.track.artist.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredRecommendations: [MusicTrack] {
        if searchText.isEmpty {
            return viewModel.musicRecommendations
        }
        return viewModel.musicRecommendations.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Top Hits Link
                NavigationLink(destination: LocalMusicLibraryView()) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("🎵")
                                    .font(.title2)
                                Text("Top Hits just for you")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("Your curated music collection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                
                // Music Player Link
                NavigationLink(destination: MusicPlayerView()) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text("Music Player")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            Text("Play songs from your library")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                
                // AI Search Results Section
                if !viewModel.aiMusicResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Search Results (\(viewModel.aiMusicResults.count))")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearAIResults()
                                searchText = ""
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                        .padding(.horizontal)
                        
                        ForEach(viewModel.aiMusicResults) { track in
                            MusicTrackRow(track: track, viewModel: viewModel)
                        }
                        .padding(.horizontal)
                    }
                } else if !searchText.isEmpty && !viewModel.isSearching {
                    // Show message when search completed but no results
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Click the 'AI search' button below")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Results will appear here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
                
                // Loading indicator
                if viewModel.isSearching {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Searching with AI...")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                // Music Stats Card
                MusicStatsCard(viewModel: viewModel)
                
                // Recommendations Section
                if !filteredRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(filteredRecommendations) { track in
                                    MusicTrackCard(track: track, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Favorite Tracks Section
                if !filteredFavoriteTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite Tracks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(filteredFavoriteTracks) { track in
                            MusicTrackRow(track: track, viewModel: viewModel)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Playlists Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("My Playlists")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            showCreatePlaylist = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.playlists.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No playlists yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Tap + to create your first playlist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                    } else if filteredPlaylists.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No matching playlists")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredPlaylists) { playlist in
                            PlaylistRow(playlist: playlist, viewModel: viewModel)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recently Played Section
                if !filteredMusicHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recently Played")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(filteredMusicHistory) { item in
                            HistoryTrackRow(historyItem: item, viewModel: viewModel)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showCreatePlaylist) {
            CreatePlaylistView(viewModel: viewModel)
        }
    }
    
    private func searchWeb(query: String, context: String) {
        guard !query.isEmpty else { return }
        let searchQuery = "\(query) \(context)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.google.com/search?q=\(searchQuery)") else {
            print("❌ Failed to create URL for query: \(query)")
            return
        }
        
        print("🔍 Opening web search: \(url.absoluteString)")
        
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
}

/// Music stats overview card
struct MusicStatsCard: View {
    let viewModel: LibraryViewModel
    
    private var listenTime: String {
        // Calculate listen time from history
        let totalSeconds = viewModel.musicHistory.reduce(0.0) { $0 + $1.listenDuration }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var topArtists: [String] {
        let artistCounts = viewModel.musicHistory.reduce(into: [String: Int]()) { counts, item in
            counts[item.track.artist, default: 0] += 1
        }
        return artistCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItemView(
                    icon: "music.note",
                    value: "\(viewModel.favoriteTracks.count)",
                    label: "Favorite Songs"
                )
                
                Divider()
                
                StatItemView(
                    icon: "play.circle.fill",
                    value: "\(viewModel.playlists.count)",
                    label: "Playlists"
                )
                
                Divider()
                
                StatItemView(
                    icon: "headphones",
                    value: listenTime,
                    label: "Listen Time"
                )
            }
            .frame(maxWidth: .infinity)
            
            // Top Artists
            if !topArtists.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Artists")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(topArtists, id: \.self) { artist in
                            Text(artist)
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

/// Music track card for horizontal scrolling
struct MusicTrackCard: View {
    let track: MusicTrack
    let viewModel: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.gradient)
                .frame(width: 140, height: 140)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.7))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Button {
                Task {
                    await viewModel.toggleFavorite(track)
                }
            } label: {
                Image(systemName: viewModel.isFavorite(track) ? "heart.fill" : "heart")
                    .foregroundStyle(viewModel.isFavorite(track) ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 140)
    }
}

/// Music track row for lists
struct MusicTrackRow: View {
    let track: MusicTrack
    let viewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white.opacity(0.7))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
            Image(systemName: viewModel.isFavorite(track) ? "heart.fill" : "heart")
                .foregroundStyle(viewModel.isFavorite(track) ? .red : .secondary)
                .font(.title3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    Task {
                        await viewModel.toggleFavorite(track)
                    }
                }
        }
        .padding(.vertical, 4)
    }
}

/// Playlist row
struct PlaylistRow: View {
    let playlist: MusicPlaylist
    let viewModel: LibraryViewModel
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 12) {
                // Playlist icon
                RoundedRectangle(cornerRadius: 6)
                    .fill(.purple.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("\(playlist.tracks.count) songs • \(playlist.formattedDuration)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .sheet(isPresented: $showDetail) {
            PlaylistDetailView(playlist: playlist, viewModel: viewModel)
        }
    }
}

/// History track row
struct HistoryTrackRow: View {
    let historyItem: MusicHistoryItem
    let viewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white.opacity(0.7))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(historyItem.track.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(historyItem.track.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(historyItem.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if historyItem.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Create playlist sheet
struct CreatePlaylistView: View {
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Playlist Name", text: $playlistName)
                    TextField("Description (optional)", text: $playlistDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Playlist")
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
                        Task {
                            _ = await viewModel.createPlaylist(
                                name: playlistName.isEmpty ? "Untitled Playlist" : playlistName,
                                description: playlistDescription.isEmpty ? nil : playlistDescription
                            )
                            dismiss()
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 250)
        #endif
    }
}

/// Playlist detail view
struct PlaylistDetailView: View {
    let playlist: MusicPlaylist
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                if playlist.tracks.isEmpty {
                    ContentUnavailableView {
                        Label("No Tracks", systemImage: "music.note")
                    } description: {
                        Text("This playlist is empty")
                    }
                } else {
                    ForEach(playlist.tracks) { track in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(.body)
                                Text(track.artist)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(track.formattedDuration)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            
                            Button {
                                Task {
                                    await viewModel.removeTrackFromPlaylist(track, playlist: playlist)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(playlist.name)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .confirmationDialog(
                "Delete Playlist",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Playlist", role: .destructive) {
                    Task {
                        await viewModel.deletePlaylist(playlist)
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete '\(playlist.name)' and cannot be undone.")
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }
}

/// Stats overview card
struct StatsCardView: View {
    let stats: LibraryStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItemView(
                    icon: "clock.fill",
                    value: stats.formattedWatchTime,
                    label: "Watch Time"
                )
                
                Divider()
                
                StatItemView(
                    icon: "star.fill",
                    value: "\(stats.totalFavorites)",
                    label: "Favorites"
                )
                
                Divider()
                
                StatItemView(
                    icon: "flame.fill",
                    value: "\(stats.recentStreak)",
                    label: "Day Streak"
                )
            }
            .frame(maxWidth: .infinity)
            
            if !stats.favoriteGenres.isEmpty {
                Divider()
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.secondary)
                    Text("Top Genre:")
                        .foregroundStyle(.secondary)
                    Text(stats.favoriteGenres.first ?? "N/A")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Content card for horizontal scrolling
struct ContentCardView: View {
    let content: MediaContent
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 160, height: 240)
                .overlay {
                    VStack {
                        Spacer()
                        Image(systemName: content.contentType == .movie ? "film" : "tv")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        
                        // Favorite button
                        HStack {
                            Spacer()
                            Button {
                                Task {
                                    await libraryViewModel.toggleFavorite(content)
                                }
                            } label: {
                                Image(systemName: libraryViewModel.isFavorite(content) ? "heart.fill" : "heart")
                                    .foregroundStyle(libraryViewModel.isFavorite(content) ? .red : .white)
                                    .font(.title3)
                                    .padding(8)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                            .padding(8)
                        }
                    }
                }
            
            Text(content.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
            
            Text(content.contentType == .movie ? "Movie" : "TV Show")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// History row item
struct HistoryRowView: View {
    let item: WatchHistoryItem
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 120)
                .overlay {
                    Image(systemName: item.content.contentType == .movie ? "film" : "tv")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.7))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.content.contentType == .movie ? "Movie" : "TV Show")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(item.formattedDate)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await libraryViewModel.toggleFavorite(item.content)
                }
            } label: {
                Image(systemName: libraryViewModel.isFavorite(item.content) ? "heart.fill" : "heart")
                    .foregroundStyle(libraryViewModel.isFavorite(item.content) ? .red : .gray)
            }
        }
        .padding()
        .background(.quaternary)
        .cornerRadius(8)
    }
}

/// Full favorites list view
struct FavoritesListView: View {
    let viewModel: LibraryViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.favorites, id: \.contentID) { content in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 90)
                        .overlay {
                            Image(systemName: content.contentType == .movie ? "film" : "tv")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .font(.headline)
                        Text(content.contentType == .movie ? "Movie" : "TV Show")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
#if !os(tvOS)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeFromFavorites(content)
                        }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
#endif
            }
        }
        .navigationTitle("Favorites")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

/// Full watch history view
struct WatchHistoryView: View {
    let viewModel: LibraryViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.recentlyWatched) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 90)
                            .overlay {
                                Image(systemName: item.content.contentType == .movie ? "film" : "tv")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.content.title)
                                .font(.headline)
                            Text(item.content.contentType == .movie ? "Movie" : "TV Show")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(item.formattedDate)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await viewModel.toggleFavorite(item.content)
                            }
                        } label: {
                            Image(systemName: viewModel.isFavorite(item.content) ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isFavorite(item.content) ? .red : .gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Watch History")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview {
    LibraryView(libraryService: LibraryService())
}
