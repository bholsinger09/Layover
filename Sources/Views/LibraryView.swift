import SwiftUI

/// Main library view showing favorites, history, stats, and recommendations
struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var selectedTab = 0
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    init(libraryService: LibraryServiceProtocol) {
        self._viewModel = State(initialValue: LibraryViewModel(libraryService: libraryService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Content Type", selection: $selectedTab) {
                    Text("Movies & TV").tag(0)
                    Text("Music").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    MoviesTabView(viewModel: viewModel, searchText: $searchText)
                        .tag(0)
                    
                    MusicTabView(viewModel: viewModel, searchText: $searchText)
                        .tag(1)
                }
                #if !os(macOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("My Library")
            .searchable(text: $searchText, prompt: selectedTab == 0 ? "Search movies and TV shows" : "Search music, artists, and playlists")
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        Task {
                            if selectedTab == 0 {
                                await viewModel.searchMoviesWithAI(query: searchText)
                            } else {
                                await viewModel.searchMusicWithAI(query: searchText)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("AI Search")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding()
                .background(.regularMaterial)
            }
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
                            .foregroundStyle(.tertiary)
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
                            .foregroundStyle(.tertiary)
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
                                .foregroundStyle(.tertiary)
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
        let library = viewModel.favoriteTracks.first?.album
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
                    .foregroundStyle(.tertiary)
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
                        .foregroundStyle(.tertiary)
                    
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
            #if !os(macOS)
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
                            await viewModel.createPlaylist(
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
            #if !os(macOS)
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
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeFromFavorites(content)
                        }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        #if !os(macOS)
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
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    LibraryView(libraryService: LibraryService())
}
