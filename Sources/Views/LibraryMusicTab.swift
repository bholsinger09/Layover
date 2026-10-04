import SwiftUI

// MARK: - Music Tab

struct LibraryMusicTab: View {
    let viewModel: LibraryViewModel
    @Binding var searchText: String
    @State private var selectedTab: MusicTab = .tracks
    @State private var showCreatePlaylist = false
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Music Content", selection: $selectedTab) {
                Text("Tracks").tag(MusicTab.tracks)
                Text("Playlists").tag(MusicTab.playlists)
                Text("History").tag(MusicTab.history)
                Text("Favorites").tag(MusicTab.favorites)
            }
            .pickerStyle(.segmented)
            .padding()
            
            TabView(selection: $selectedTab) {
                tracksView
                    .tag(MusicTab.tracks)
                playlistsView
                    .tag(MusicTab.playlists)
                historyView
                    .tag(MusicTab.history)
                favoritesView
                    .tag(MusicTab.favorites)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
        }
    }
    
    private var tracksView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.favoriteTracks) { track in
                    MusicTrackRow(track: track, viewModel: viewModel)
                }
            }
            .padding()
        }
    }
    
    private var playlistsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button(action: { showCreatePlaylist = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Playlist")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
                .padding()
                
                ForEach(viewModel.playlists) { playlist in
                    PlaylistRow(playlist: playlist, viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $showCreatePlaylist) {
            CreatePlaylistView(viewModel: viewModel, isPresented: $showCreatePlaylist)
        }
    }
    
    private var historyView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.musicHistory) { item in
                    HistoryTrackRow(item: item, viewModel: viewModel)
                }
            }
            .padding()
        }
    }
    
    private var favoritesView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.favoriteTracks) { track in
                    MusicTrackRow(track: track, viewModel: viewModel)
                }
            }
            .padding()
        }
    }
}

enum MusicTab: Hashable {
    case tracks
    case playlists
    case history
    case favorites
}

// MARK: - Music Track Row

struct MusicTrackRow: View {
    let track: MusicTrack
    let viewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.toggleFavorite(track)
                }
            }) {
                Image(systemName: viewModel.favoriteTracks.contains(track) ? "heart.fill" : "heart")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Playlist Row

struct PlaylistRow: View {
    let playlist: MusicPlaylist
    let viewModel: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let desc = playlist.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(playlist.tracks.count)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("tracks")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - History Track Row

struct HistoryTrackRow: View {
    let item: MusicHistoryItem
    let viewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.track.title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text(item.track.artist)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.playedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(item.playedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Create Playlist View

struct CreatePlaylistView: View {
    let viewModel: LibraryViewModel
    @Binding var isPresented: Bool
    
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Details") {
                    TextField("Name", text: $playlistName)
                    TextField("Description (optional)", text: $playlistDescription)
                }
            }
            .navigationTitle("New Playlist")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createPlaylist(name: playlistName, description: playlistDescription)
                            isPresented = false
                        }
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
