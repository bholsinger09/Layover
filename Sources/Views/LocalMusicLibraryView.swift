import SwiftUI

/// View for browsing curated music
public struct LocalMusicLibraryView: View {
    @StateObject private var viewModel = LocalMusicLibraryViewModel()
    @State private var musicPlayer = MusicPlayerViewModel()
    @State private var selectedTrack: LocalMusicTrack?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
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
                                .tint(.white)
                            
                            Text("Loading your music...")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        tracksListView
                    }
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("🎵")
                        .font(.title)
                    Text("Top Hits just for you")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Text("\(viewModel.tracks.count) Songs • \(viewModel.formattedTotalDuration)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Tracks List
    
    private var tracksListView: some View {
        List {
            LocalAudioNoticeView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

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
                    .listRowBackground(Color.clear)
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
        .scrollContentBackground(.hidden)
        .background(Color.clear)
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
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if song.artist != "Unknown Artist" {
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        musicPlayer.playPrevious()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        musicPlayer.togglePlayPause()
                    }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        musicPlayer.playNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(musicPlayer.currentTime / max(musicPlayer.duration, 1)), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            
            HStack {
                Text(formatTime(musicPlayer.currentTime))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
                Spacer()
                Text(formatTime(musicPlayer.duration))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .monospacedDigit()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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

private struct LocalAudioNoticeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Audio Notice", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.white)

            Text("These recordings are presented as publicly available archival/reference audio from third-party sources. They are not official releases and are not provided for public streaming, downloading, resale, or official artist distribution.")

            Text("For official music, releases, and artist-supported listening, please use Apple Music or the artist's official website.")
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.72))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct TrackRowView: View {
    let track: LocalMusicTrack
    
    private var shouldShowArtistInfo: Bool {
        track.artist != "Unknown Artist" || track.album != "Unknown Album"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Music note icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if shouldShowArtistInfo {
                    HStack(spacing: 4) {
                        if track.artist != "Unknown Artist" {
                            Text(track.artist)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        if track.artist != "Unknown Artist" && track.album != "Unknown Album" {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        if track.album != "Unknown Album" {
                            Text(track.album)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .font(.subheadline)
                    .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
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
