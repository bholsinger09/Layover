import Foundation
import MusicKit
import OSLog

/// Service for managing Apple Music playback
@MainActor
public protocol AppleMusicServiceProtocol: LayoverService {
    var currentContent: MediaContent? { get }
    var isAuthorized: Bool { get async }

    func requestAuthorization() async throws
    func loadContent(_ content: MediaContent) async throws
    func play() async
    func pause() async
    func skipToNext() async
    func skipToPrevious() async
    
    // Library browsing
    func fetchRecentlyPlayed() async throws -> [MediaContent]
    func fetchRecommendations() async throws -> [MediaContent]
    func fetchPlaylists() async throws -> [MediaContent]
    func fetchSongs(limit: Int) async throws -> [MediaContent]
    func fetchAlbums(limit: Int) async throws -> [MediaContent]
    func searchMusic(query: String) async throws -> [MediaContent]
    
    // Playlist management
    func createPlaylist(name: String) async throws -> MediaContent
    func addToPlaylist(playlistID: String, content: MediaContent) async throws
}

@MainActor
public final class AppleMusicService: AppleMusicServiceProtocol {
    private let logger = Logger(
        subsystem: "com.bholsinger.LayoverLounge", category: "AppleMusicService")
    public private(set) var currentContent: MediaContent?
    private let musicPlayer = ApplicationMusicPlayer.shared
    
    // Cache of MusicKit items for playback
    private var songCache: [String: Song] = [:]
    private var albumCache: [String: Album] = [:]
    private var playlistCache: [String: Playlist] = [:]
    
    // State change callback
    var onPlaybackStateChanged: ((Bool) -> Void)?
    var onCurrentEntryChanged: ((MediaContent?) -> Void)?
    
    // Timer for polling playback state
    private var stateMonitoringTimer: Timer?
    
    public init() {
        setupStateMonitoring()
    }
    
    private func setupStateMonitoring() {
        // Poll playback state every 0.5 seconds
        stateMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.checkPlaybackState()
            }
        }
    }
    
    private func checkPlaybackState() async {
        let state = musicPlayer.state
        let isPlaying = state.playbackStatus == .playing
        onPlaybackStateChanged?(isPlaying)
        
        // Check if current entry changed and update current content
        if let currentEntry = musicPlayer.queue.currentEntry {
            // Get the item and check if it's a Song
            if let song = currentEntry.item as? Song {
                // Only update if it's a different song
                if currentContent?.contentID != song.id.rawValue {
                    let content = MediaContent(
                        title: song.title,
                        artist: song.artistName,
                        contentID: song.id.rawValue,
                        artworkURL: song.artwork?.url(width: 300, height: 300),
                        duration: song.duration ?? 0,
                        contentType: .song
                    )
                    self.currentContent = content
                    onCurrentEntryChanged?(content)
                    logger.info("Updated current song: \(song.title) by \(song.artistName)")
                }
            }
        }
    }
    
    private func updateCurrentContent(from entry: ApplicationMusicPlayer.Queue.Entry) async {
        // This method is no longer needed but keeping for compatibility
    }
    
    deinit {
        stateMonitoringTimer?.invalidate()
    }

    public var isAuthorized: Bool {
        get async {
            let status = MusicAuthorization.currentStatus
            return status == .authorized
        }
    }

    public func requestAuthorization() async throws {
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            throw MusicError.authorizationDenied
        }
    }

    public func loadContent(_ content: MediaContent) async throws {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }

        // Store the current content for display
        self.currentContent = content
        
        logger.info("Loading content: \(content.title), type: \(String(describing: content.contentType)), ID: \(content.contentID)")
        
        // Load from cache and set up player queue
        do {
            switch content.contentType {
            case .song:
                if let song = songCache[content.contentID] {
                    logger.info("Found song in cache, setting queue")
                    musicPlayer.queue = [song]
                    logger.info("Queue set with song: \(song.title)")
                    try await musicPlayer.prepareToPlay()
                    logger.info("Player prepared to play")
                } else {
                    logger.warning("Song not found in cache: \(content.contentID)")
                }
            case .album:
                if let album = albumCache[content.contentID] {
                    logger.info("Found album in cache")
                    // Access tracks directly - this will load them if needed
                    do {
                        if let tracks = album.tracks, !tracks.isEmpty {
                            logger.info("Album has \(tracks.count) tracks")
                            musicPlayer.queue = ApplicationMusicPlayer.Queue(for: tracks)
                            try await musicPlayer.prepareToPlay()
                            logger.info("Player prepared to play")
                        } else {
                            logger.warning("Album has no tracks")
                        }
                    }
                } else {
                    logger.warning("Album not found in cache: \(content.contentID)")
                }
            case .playlist:
                logger.info("Loading playlist: \(content.contentID)")
                
                // Determine if it's a library playlist (user's own) or catalog playlist
                // Catalog playlists: start with "pl." (e.g., "pl.u-" for user-curated catalog playlists)
                // Library playlists: everything else (numeric IDs or "p." prefix)
                let isCatalogPlaylist = content.contentID.starts(with: "pl.")
                
                if !isCatalogPlaylist {
                    // Load from user's library
                    logger.info("Attempting to load as library playlist")
                    var libraryRequest = MusicLibraryRequest<Playlist>()
                    libraryRequest.filter(matching: \.id, equalTo: MusicItemID(content.contentID))
                    let libraryResponse = try await libraryRequest.response()
                    
                    if let playlist = libraryResponse.items.first {
                        logger.info("Found library playlist: \(playlist.name)")
                        
                        // Load the playlist with tracks using the with() method
                        do {
                            let detailedPlaylist = try await playlist.with([.tracks])
                            
                            if let tracks = detailedPlaylist.tracks, !tracks.isEmpty {
                                logger.info("Library playlist has \(tracks.count) tracks, setting queue")
                                musicPlayer.queue = ApplicationMusicPlayer.Queue(for: tracks)
                                try await musicPlayer.prepareToPlay()
                                logger.info("Player prepared to play")
                            } else {
                                logger.error("Library playlist has no tracks after loading")
                                throw MusicError.loadFailed
                            }
                        } catch {
                            logger.error("Error loading playlist with tracks: \(error.localizedDescription)")
                            
                            // Fallback: try checking if tracks are already available
                            if let tracks = playlist.tracks, !tracks.isEmpty {
                                logger.info("Using already-loaded tracks: \(tracks.count)")
                                musicPlayer.queue = ApplicationMusicPlayer.Queue(for: tracks)
                                try await musicPlayer.prepareToPlay()
                                logger.info("Player prepared to play")
                            } else {
                                logger.error("No tracks available in playlist")
                                throw MusicError.loadFailed
                            }
                        }
                    } else {
                        logger.error("Library playlist not found")
                        throw MusicError.loadFailed
                    }
                } else {
                    // Load from catalog
                    logger.info("Attempting to load as catalog playlist")
                    var catalogRequest = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(content.contentID))
                    catalogRequest.properties = [.tracks]
                    let catalogResponse = try await catalogRequest.response()
                    
                    if let playlist = catalogResponse.items.first {
                        logger.info("Found catalog playlist: \(playlist.name)")
                        
                        if let tracks = playlist.tracks, !tracks.isEmpty {
                            logger.info("Catalog playlist has \(tracks.count) tracks, setting queue")
                            musicPlayer.queue = ApplicationMusicPlayer.Queue(for: tracks)
                            try await musicPlayer.prepareToPlay()
                            logger.info("Player prepared to play")
                        } else {
                            logger.error("Catalog playlist has no tracks")
                            throw MusicError.loadFailed
                        }
                    } else {
                        logger.error("Catalog playlist not found")
                        throw MusicError.loadFailed
                    }
                }
            default:
                logger.warning("Unsupported content type: \(String(describing: content.contentType))")
                break
            }
        } catch {
            logger.error("Failed to load content: \(error.localizedDescription)")
            throw MusicError.loadFailed
        }
    }

    public func play() async {
        do {
            logger.info("Starting playback, queue has \(self.musicPlayer.queue.entries.count) items")
            try await self.musicPlayer.play()
            logger.info("Playback started successfully")
        } catch {
            logger.error("Failed to play music: \(error.localizedDescription)")
        }
    }

    public func pause() async {
        self.musicPlayer.pause()
    }
    
    public func skipToNext() async {
        do {
            try await musicPlayer.skipToNextEntry()
        } catch {
            logger.error("Failed to skip to next: \(error.localizedDescription)")
        }
    }
    
    public func skipToPrevious() async {
        do {
            try await musicPlayer.skipToPreviousEntry()
        } catch {
            logger.error("Failed to skip to previous: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Library Browsing
    
    public func fetchRecentlyPlayed() async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let request = MusicRecentlyPlayedRequest<Song>()
        let response = try await request.response()
        
        return response.items.compactMap { song -> MediaContent? in
            // Cache the song for playback
            songCache[song.id.rawValue] = song
            
            return MediaContent(
                title: song.title,
                artist: song.artistName,
                contentID: song.id.rawValue,
                artworkURL: song.artwork?.url(width: 300, height: 300),
                duration: song.duration ?? 0,
                contentType: .song
            )
        }
    }
    
    public func fetchRecommendations() async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        // Get top charts as recommendations
        let request: MusicCatalogChartsRequest = MusicCatalogChartsRequest(kinds: [.mostPlayed], types: [Album.self])
        let response = try await request.response()
        
        var results: [MediaContent] = []
        
        // Add albums from charts
        for album in response.albumCharts.flatMap({ $0.items }) {
            // Cache the album for playback
            albumCache[album.id.rawValue] = album
            
            results.append(MediaContent(
                title: album.title,
                contentID: album.id.rawValue,
                artworkURL: album.artwork?.url(width: 300, height: 300),
                duration: 0,
                contentType: .album
            ))
        }
        
        return results
    }
    
    public func fetchPlaylists() async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let request: MusicLibraryRequest<Playlist> = MusicLibraryRequest()
        let response = try await request.response()
        
        return response.items.map { playlist in
            // Cache the playlist for playback
            playlistCache[playlist.id.rawValue] = playlist
            
            logger.info("Fetched playlist: \(playlist.name), ID: \(playlist.id.rawValue), has tracks: \(playlist.tracks != nil)")
            
            return MediaContent(
                title: playlist.name,
                contentID: playlist.id.rawValue,
                artworkURL: playlist.artwork?.url(width: 300, height: 300),
                duration: 0,
                contentType: .playlist
            )
        }
    }
    
    public func fetchSongs(limit: Int = 50) async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let request: MusicLibraryRequest<Song> = MusicLibraryRequest()
        let response = try await request.response()
        
        return response.items.prefix(limit).map { song in
            // Cache the song for playback
            songCache[song.id.rawValue] = song
            
            return MediaContent(
                title: song.title,
                artist: song.artistName,
                contentID: song.id.rawValue,
                artworkURL: song.artwork?.url(width: 300, height: 300),
                duration: song.duration ?? 0,
                contentType: .song
            )
        }
    }
    
    public func fetchAlbums(limit: Int = 50) async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let request: MusicLibraryRequest<Album> = MusicLibraryRequest()
        let response = try await request.response()
        
        return response.items.prefix(limit).map { album in
            // Cache the album for playback
            albumCache[album.id.rawValue] = album
            
            return MediaContent(
                title: album.title,
                contentID: album.id.rawValue,
                artworkURL: album.artwork?.url(width: 300, height: 300),
                duration: 0,
                contentType: .album
            )
        }
    }
    
    public func searchMusic(query: String) async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let request: MusicCatalogSearchRequest = MusicCatalogSearchRequest(term: query, types: [Song.self, Album.self])
        let response = try await request.response()
        
        var results: [MediaContent] = []
        
        // Add songs from search results
        for song in response.songs {
            // Cache the song for playback
            songCache[song.id.rawValue] = song
            
            results.append(MediaContent(
                title: song.title,
                artist: song.artistName,
                contentID: song.id.rawValue,
                artworkURL: song.artwork?.url(width: 300, height: 300),
                duration: song.duration ?? 0,
                contentType: .song
            ))
        }
        
        // Add albums from search results
        for album in response.albums {
            // Cache the album for playback
            albumCache[album.id.rawValue] = album
            
            results.append(MediaContent(
                title: album.title,
                contentID: album.id.rawValue,
                artworkURL: album.artwork?.url(width: 300, height: 300),
                duration: 0,
                contentType: .album
            ))
        }
        
        return results
    }
    
    public func createPlaylist(name: String) async throws -> MediaContent {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        #if os(iOS)
        let playlist = try await MusicLibrary.shared.createPlaylist(name: name, description: nil)
        
        return MediaContent(
            title: playlist.name,
            contentID: playlist.id.rawValue,
            artworkURL: playlist.artwork?.url(width: 300, height: 300),
            duration: 0,
            contentType: .playlist
        )
        #else
        // macOS doesn't support creating playlists via MusicKit
        throw MusicError.loadFailed
        #endif
    }
    
    public func addToPlaylist(playlistID: String, content: MediaContent) async throws {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        // Implementation would require converting contentID to MusicItemID
        // and adding to the specified playlist
        logger.info("Adding \(content.title) to playlist \(playlistID)")
    }
}

public enum MusicError: LocalizedError {
    case notAuthorized
    case authorizationDenied
    case loadFailed

    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Music authorization required"
        case .authorizationDenied:
            return "Music authorization was denied"
        case .loadFailed:
            return "Failed to load music content"
        }
    }
}
