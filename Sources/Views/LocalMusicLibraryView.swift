import SwiftUI

/// View for browsing and managing the local music library
public struct LocalMusicLibraryView: View {
    @StateObject private var viewModel = LocalMusicLibraryViewModel()
    @State private var musicPlayer = MusicPlayerViewModel()
    @State private var selectedTab = 0
    @State private var selectedTrack: LocalMusicTrack?
    @State private var showingScanSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats header
                statsHeader
                
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    Text("All Songs").tag(0)
                    Text("Artists").tag(1)
                    Text("Albums").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search music...", text: $viewModel.searchQuery)
                        #if !os(tvOS)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        #endif
                }
                .padding(.horizontal)
                
                // Content based on selected tab
                if viewModel.tracks.isEmpty && !viewModel.isScanning {
                    // Empty state with prominent scan button
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Songs in Library")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        #if os(tvOS)
                        Text("Scan bundled music resources")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            showingScanSheet = true
                        } label: {
                            Label("Scan Bundled Music", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                        
                        Text("Add music files to Resources/Music in Xcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        #else
                        Text("Import songs from your Apple Music downloads")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            showingScanSheet = true
                        } label: {
                            Label("Scan Music Library", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                        #endif
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Group {
                        switch selectedTab {
                        case 0:
                            tracksListView
                        case 1:
                            artistsListView
                        case 2:
                            albumsListView
                        default:
                            tracksListView
                        }
                    }
                }
            }
            .navigationTitle("Local Music Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showingScanSheet = true
                        }) {
                            Label("Scan Music Library", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.cleanupMissingTracks()
                            }
                        }) {
                            Label("Clean Up Missing", systemImage: "trash")
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.clearAndRescan()
                            }
                        }) {
                            Label("Clear & Rescan", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.clearFilters()
                            }
                        }) {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingScanSheet) {
                scanView
            }
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
                // Always rescan on load to pick up any file changes
                await viewModel.clearAndRescan()
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.tracks.count) Songs")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(viewModel.formattedTotalDuration) • \(viewModel.formattedTotalSize)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        #if os(tvOS)
        .background(Color.secondary.opacity(0.1))
        #else
        .background(Color(.systemGroupedBackground))
        #endif
    }
    
    // MARK: - Tracks List
    
    private var tracksListView: some View {
        List {
            ForEach(viewModel.filteredTracks) { track in
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
    
    // MARK: - Scan View
    
    private var scanView: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isScanning {
                    ProgressView()
                    Text("Scanning...")
                        .font(.headline)
                    
                    if let progress = viewModel.scanProgress {
                        Text("Scanned: \(progress.filesScanned)")
                        Text("Imported: \(progress.filesImported)")
                        if let currentFile = progress.currentFile {
                            Text(currentFile)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                } else {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Scan Your Music Library")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose how to import your music")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        // Bundled Music Button (works on all platforms)
                        Button(action: {
                            Task {
                                await viewModel.scanBundledMusic()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Label("Scan Bundled Music", systemImage: "shippingbox.fill")
                                Text("Music files included in the app")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        #if !os(tvOS)
                        // Apple Music Library Button (Mac/iOS only)
                        Button(action: {
                            Task {
                                await viewModel.scanAppleMusicLibrary()
                            }
                        }) {
                            VStack(spacing: 4) {
                                Label("Scan Apple Music Library", systemImage: "music.note")
                                Text("From ~/Music folder")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // TODO: Show directory picker
                        }) {
                            Label("Choose Custom Folder", systemImage: "folder")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        #endif
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Import Music")
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showingScanSheet = false
                    }
                    .disabled(viewModel.isScanning)
                }
            }
        }
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
        #if !os(tvOS)
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
        #if !os(tvOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    LocalMusicLibraryView()
}
