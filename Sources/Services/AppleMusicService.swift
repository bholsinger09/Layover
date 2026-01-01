import Foundation
import MusicKit
import OSLog

/// Service for managing Apple Music playback
@MainActor
protocol AppleMusicServiceProtocol: LayoverService {
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
final class AppleMusicService: AppleMusicServiceProtocol {
    private let logger = Logger(
        subsystem: "com.bholsinger.LayoverLounge", category: "AppleMusicService")
    private(set) var currentContent: MediaContent?
    private let musicPlayer = ApplicationMusicPlayer.shared
    
    // Cache of MusicKit items for playback
    private var songCache: [String: Song] = [:]
    private var albumCache: [String: Album] = [:]
    private var playlistCache: [String: Playlist] = [:]

    var isAuthorized: Bool {
        get async {
            let status = MusicAuthorization.currentStatus
            return status == .authorized
        }
    }

    func requestAuthorization() async throws {
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            throw MusicError.authorizationDenied
        }
    }

    func loadContent(_ content: MediaContent) async throws {
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
                if let playlist = playlistCache[content.contentID] {
                    logger.info("Found playlist in cache")
                    // Access tracks directly - this will load them if needed
                    do {
                        if let tracks = playlist.tracks, !tracks.isEmpty {
                            logger.info("Playlist has \(tracks.count) tracks")
                            musicPlayer.queue = ApplicationMusicPlayer.Queue(for: tracks)
                            try await musicPlayer.prepareToPlay()
                            logger.info("Player prepared to play")
                        } else {
                            logger.warning("Playlist has no tracks")
                        }
                    }
                } else {
                    logger.warning("Playlist not found in cache: \(content.contentID)")
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

    func play() async {
        do {
            logger.info("Starting playback, queue has \(self.musicPlayer.queue.entries.count) items")
            try await self.musicPlayer.play()
            logger.info("Playback started successfully")
        } catch {
            logger.error("Failed to play music: \(error.localizedDescription)")
        }
    }

    func pause() async {
        self.musicPlayer.pause()
    }
    
    func skipToNext() async {
        do {
            try await musicPlayer.skipToNextEntry()
        } catch {
            logger.error("Failed to skip to next: \(error.localizedDescription)")
        }
    }
    
    func skipToPrevious() async {
        do {
            try await musicPlayer.skipToPreviousEntry()
        } catch {
            logger.error("Failed to skip to previous: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Library Browsing
    
    func fetchRecentlyPlayed() async throws -> [MediaContent] {
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
                contentID: song.id.rawValue,
                artworkURL: song.artwork?.url(width: 300, height: 300),
                duration: song.duration ?? 0,
                contentType: .song
            )
        }
    }
    
    func fetchRecommendations() async throws -> [MediaContent] {
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
    
    func fetchPlaylists() async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let request: MusicLibraryRequest<Playlist> = MusicLibraryRequest()
        let response = try await request.response()
        
        return response.items.map { playlist in
            // Cache the playlist for playback
            playlistCache[playlist.id.rawValue] = playlist
            
            return MediaContent(
                title: playlist.name,
                contentID: playlist.id.rawValue,
                artworkURL: playlist.artwork?.url(width: 300, height: 300),
                duration: 0,
                contentType: .playlist
            )
        }
    }
    
    func fetchSongs(limit: Int = 50) async throws -> [MediaContent] {
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
                contentID: song.id.rawValue,
                artworkURL: song.artwork?.url(width: 300, height: 300),
                duration: song.duration ?? 0,
                contentType: .song
            )
        }
    }
    
    func fetchAlbums(limit: Int = 50) async throws -> [MediaContent] {
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
    
    func searchMusic(query: String) async throws -> [MediaContent] {
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
    
    func createPlaylist(name: String) async throws -> MediaContent {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        let playlist = try await MusicLibrary.shared.createPlaylist(name: name, description: nil)
        
        return MediaContent(
            title: playlist.name,
            contentID: playlist.id.rawValue,
            artworkURL: playlist.artwork?.url(width: 300, height: 300),
            duration: 0,
            contentType: .playlist
        )
    }
    
    func addToPlaylist(playlistID: String, content: MediaContent) async throws {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        // Implementation would require converting contentID to MusicItemID
        // and adding to the specified playlist
        logger.info("Adding \(content.title) to playlist \(playlistID)")
    }
}

enum MusicError: LocalizedError {
    case notAuthorized
    case authorizationDenied
    case loadFailed

    var errorDescription: String? {
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
