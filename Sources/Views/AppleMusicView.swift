import SwiftUI

/// View for Apple Music listening rooms
public struct AppleMusicView: View {
    public let room: Room
    public let currentUser: User
    public let sharePlayService: SharePlayServiceProtocol

    @State private var viewModel: AppleMusicViewModel
    @State private var showingContentPicker = false
    @State private var showingCreatePlaylist = false
    @State private var sharePlayStarted = false
    @State private var isSharePlayActive = false
    @State private var showingSearch = false
    
    public init(room: Room, currentUser: User, sharePlayService: SharePlayServiceProtocol) {
        self.room = room
        self.currentUser = currentUser
        self.sharePlayService = sharePlayService
        self._viewModel = State(initialValue: AppleMusicViewModel(musicService: AppleMusicService()))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // SharePlay prompt banner
            if !isSharePlayActive {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await startSharePlay()
                        }
                    } label: {
                        Label("Start SharePlay to listen together", systemImage: "shareplay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.pink.opacity(0.1))
            }

            // Main content
            if viewModel.isAuthorized {
                if showingSearch {
                    searchView
                } else {
                    libraryBrowseView
                }
            } else {
                authorizationView
            }
            
            // Now Playing Bar
            if let content = viewModel.currentContent {
                nowPlayingBar(content)
            }
        }
        .navigationTitle(room.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSearch.toggle()
                } label: {
                    Label(showingSearch ? "Browse" : "Search", systemImage: showingSearch ? "music.note.list" : "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            MusicCreatePlaylistView { name in
                Task {
                    await viewModel.createPlaylist(name: name)
                    showingCreatePlaylist = false
                }
            }
        }
        .onAppear {
            sharePlayService.addSessionStateObserver { isActive in
                isSharePlayActive = isActive
                sharePlayStarted = isActive
            }
        }
        .task {
            if !viewModel.isAuthorized {
                await viewModel.requestAuthorization()
            }
            if viewModel.isAuthorized {
                await viewModel.loadLibraryContent()
            }
        }
    }
    
    // MARK: - Authorization View
    
    private var authorizationView: some View {
        ContentUnavailableView(
            "Apple Music Access Required",
            systemImage: "music.note",
            description: Text("Grant access to browse and play your music library")
        )
    }
    
    // MARK: - Library Browse View
    
    private var libraryBrowseView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Section Picker
                Picker("Browse", selection: $viewModel.selectedSection) {
                    ForEach(MusicBrowseSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected section
                switch viewModel.selectedSection {
                case .recentlyPlayed:
                    contentGrid(items: viewModel.recentlyPlayed, title: "Recently Played")
                case .recommendations:
                    contentGrid(items: viewModel.recommendations, title: "For You")
                case .playlists:
                    playlistsSection
                case .songs:
                    contentList(items: viewModel.songs, title: "Songs") {
                        await viewModel.fetchSongs()
                    }
                case .albums:
                    contentGrid(items: viewModel.albums, title: "Albums", onLoad: {
                        await viewModel.fetchAlbums()
                    })
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Search View
    
    private var searchView: some View {
        VStack {
            TextField("Search music...", text: $viewModel.searchQuery)
#if os(tvOS)
                .textFieldStyle(.plain)
#else
                .textFieldStyle(.roundedBorder)
#endif
                .padding()
                .onChange(of: viewModel.searchQuery) { _, _ in
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await viewModel.search()
                    }
                }
            
            if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                ContentUnavailableView.search
            } else {
                ScrollView {
                    contentList(items: viewModel.searchResults, title: "Results")
                }
            }
        }
    }
    
    // MARK: - Content Sections
    
    private func contentGrid(items: [MediaContent], title: String, onLoad: (() async -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .task {
                        if let onLoad = onLoad {
                            await onLoad()
                        }
                    }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(items, id: \.contentID) { item in
                            MusicItemCard(content: item) {
                                Task {
                                    await viewModel.loadContent(item)
                                    await viewModel.play()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func contentList(items: [MediaContent], title: String, onLoad: (() async -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .task {
                        if let onLoad = onLoad {
                            await onLoad()
                        }
                    }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(items, id: \.contentID) { item in
                        MusicListRow(content: item) {
                            Task {
                                await viewModel.loadContent(item)
                                await viewModel.play()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Playlists")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingCreatePlaylist = true
                } label: {
                    Label("New Playlist", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
            .padding(.horizontal)
            
            if viewModel.playlists.isEmpty {
                ContentUnavailableView(
                    "No Playlists",
                    systemImage: "music.note.list",
                    description: Text("Create a playlist to get started")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.playlists, id: \.contentID) { playlist in
                            MusicItemCard(content: playlist) {
                                Task {
                                    await viewModel.loadContent(playlist)
                                    await viewModel.play()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Now Playing Bar
    
    private func nowPlayingBar(_ content: MediaContent) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Artwork thumbnail
                if let artworkURL = content.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, height: 50)
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Title and Artist
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let artist = content.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    Button {
                        Task {
                            await viewModel.skipToPrevious()
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    
                    Button {
                        Task {
                            await viewModel.togglePlayPause()
                        }
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    
                    Button {
                        Task {
                            await viewModel.skipToNext()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func startSharePlay() async {
        print("🎵 Starting SharePlay for Apple Music room: \(room.name)")
        let activity = LayoverActivity(
            roomID: room.id,
            activityType: .appleMusic,
            customMetadata: ["roomName": room.name]
        )

        do {
            try await sharePlayService.startActivity(activity)

            await MainActor.run {
                sharePlayStarted = true
                isSharePlayActive = sharePlayService.isSessionActive
                print("✅ SharePlay started successfully, session active: \(isSharePlayActive)")
            }

            print("📤 Sending room data to SharePlay participants...")
            await sharePlayService.shareRoom(room)
        } catch {
            print("❌ Failed to start SharePlay: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct MusicItemCard: View {
    let content: MediaContent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let artworkURL = content.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderView
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    placeholderView
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(content.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 150)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundStyle(.white)
        }
    }
    
    private var iconName: String {
        switch content.contentType {
        case .playlist:
            return "music.note.list"
        case .album:
            return "square.stack"
        case .song:
            return "music.note"
        default:
            return "music.note"
        }
    }
    
    private var gradientColors: [Color] {
        switch content.contentType {
        case .playlist:
            return [.purple, .pink]
        case .album:
            return [.blue, .cyan]
        case .song:
            return [.orange, .red]
        default:
            return [.gray, .gray.opacity(0.5)]
        }
    }
}

struct MusicListRow: View {
    let content: MediaContent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let artworkURL = content.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, height: 50)
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let artist = content.artist, content.contentType == .song {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(content.contentType.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct MusicCreatePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playlistName = ""
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Playlist Name", text: $playlistName)
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
                        onCreate(playlistName)
                    }
                    .disabled(playlistName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppleMusicView(
            room: Room(name: "Music Session", hostID: UUID(), activityType: .appleMusic),
            currentUser: User(username: "Test User"),
            sharePlayService: SharePlayService()
        )
    }
}
