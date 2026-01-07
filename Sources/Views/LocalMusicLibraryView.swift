import SwiftUI

/// View for browsing curated music
public struct LocalMusicLibraryView: View {
    @StateObject private var viewModel = LocalMusicLibraryViewModel()
    @State private var musicPlayer = MusicPlayerViewModel()
    @State private var selectedTrack: LocalMusicTrack?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with title
                headerView
                
                // Mini player at top (shows when playing)
                if let currentSong = musicPlayer.currentSong {
                    miniPlayer(song: currentSong)
                }
                
                // Content
                if viewModel.tracks.isEmpty && !viewModel.isScanning {
                    // Loading state
                    VStack(spacing: 20) {
                        Spacer()
                        
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Loading your music...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    tracksListView
                }
            }
            .navigationTitle("")
            #if os(iOS) || os(tvOS)
            .navigationBarHidden(true)
            #endif
            .alert("Message", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .task {
                await viewModel.initializeDatabase()
                // Always load bundled music on startup
                await viewModel.scanBundledMusic()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("🎵")
                        .font(.title)
                    Text("Top Hits just for you")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("\(viewModel.tracks.count) Songs • \(viewModel.formattedTotalDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        #if os(tvOS)
        .background(Color.secondary.opacity(0.1))
        #elseif os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemGroupedBackground))
        #endif
    }
    
    // MARK: - Tracks List
    
    private var tracksListView: some View {
        List {
            ForEach(viewModel.tracks) { track in
                #if os(tvOS)
                Button(action: {
                    selectedTrack = track
                    print("🎯 Selected track: \(track.title)")
                    print("📁 File path: \(track.filePath)")
                    
                    // Play the track
                    let song = SampleSong(
                        title: track.title,
                        artist: track.artist,
                        genre: .all,
                        duration: track.formattedDuration,
                        colors: [.blue, .purple],
                        audioURL: URL(fileURLWithPath: track.filePath)
                    )
                    print("🎵 Calling playSong with URL: \(song.audioURL?.absoluteString ?? "nil")")
                    musicPlayer.playSong(song)
                }) {
                    TrackRowView(track: track)
                }
                .buttonStyle(.plain)
                #else
                TrackRowView(track: track)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTrack = track
                        // Play the track
                        let song = SampleSong(
                            title: track.title,
                            artist: track.artist,
                            genre: .all,
                            duration: track.formattedDuration,
                            colors: [.blue, .purple],
                            audioURL: URL(fileURLWithPath: track.filePath)
                        )
                        musicPlayer.playSong(song)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteTrack(track)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                #endif
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Artists List
    
    private var artistsListView: some View {
        List {
            ForEach(viewModel.artists, id: \.self) { artist in
                NavigationLink(destination: ArtistDetailView(
                    artist: artist,
                    viewModel: viewModel
                )) {
                    HStack {
                        Image(systemName: "music.mic")
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                        Text(artist)
                            .font(.headline)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Albums List
    
    private var albumsListView: some View {
        List {
            ForEach(viewModel.albums, id: \.album) { item in
                NavigationLink(destination: AlbumDetailView(
                    artist: item.artist,
                    album: item.album,
                    viewModel: viewModel
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.album)
                            .font(.headline)
                        Text(item.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Mini Player
    
    private func miniPlayer(song: SampleSong) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        musicPlayer.playPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    
                    Button(action: {
                        musicPlayer.togglePlayPause()
                    }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    
                    Button(action: {
                        musicPlayer.playNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(musicPlayer.currentTime / max(musicPlayer.duration, 1)), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(musicPlayer.currentTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(musicPlayer.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Track Row View

struct TrackRowView: View {
    let track: LocalMusicTrack
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                HStack {
                    Text(track.artist)
                    Text("•")
                    Text(track.album)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Artist Detail View

struct ArtistDetailView: View {
    let artist: String
    @ObservedObject var viewModel: LocalMusicLibraryViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.tracks.filter { $0.artist == artist }) { track in
                TrackRowView(track: track)
            }
        }
        .navigationTitle(artist)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

// MARK: - Album Detail View

struct AlbumDetailView: View {
    let artist: String
    let album: String
    @ObservedObject var viewModel: LocalMusicLibraryViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.tracks.filter { $0.album == album && $0.artist == artist }.sorted { ($0.trackNumber ?? 999) < ($1.trackNumber ?? 999) }) { track in
                HStack {
                    if let trackNum = track.trackNumber {
                        Text("\(trackNum)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                    TrackRowView(track: track)
                }
            }
        }
        .navigationTitle(album)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    LocalMusicLibraryView()
}
