import SwiftUI

// MARK: - Sections Extension

extension AppleMusicView {
    
    var authorizationView: some View {
        ContentUnavailableView(
            "Apple Music Access Required",
            systemImage: "music.note",
            description: Text("Grant access to browse and play your music library")
        )
    }
    
    var libraryBrowseView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Picker("Browse", selection: $viewModel.selectedSection) {
                    ForEach(MusicBrowseSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
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
    
    var searchView: some View {
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
    
    var playlistsSection: some View {
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
                                print("🎵 AppleMusicView: Tapped on playlist '\(playlist.title)'")
                                Task {
                                    print("🎵 AppleMusicView: Starting async task for playlist '\(playlist.title)'")
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
    
    func contentGrid(items: [MediaContent], title: String, onLoad: (() async -> Void)? = nil) -> some View {
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
                                print("🎵 AppleMusicView: Tapped on '\(item.title)'")
                                Task {
                                    print("🎵 AppleMusicView: Starting async task for '\(item.title)'")
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
    
    func contentList(items: [MediaContent], title: String, onLoad: (() async -> Void)? = nil) -> some View {
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
                            print("🎵 AppleMusicView: Tapped on list item '\(item.title)'")
                            Task {
                                print("🎵 AppleMusicView: Starting async task for list item '\(item.title)'")
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
