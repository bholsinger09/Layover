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

        // In a real app, this would use MusicKit to load the actual content
        self.currentContent = content
    }

    func play() async {
        do {
            try await musicPlayer.play()
        } catch {
            logger.error("Failed to play music: \(error.localizedDescription)")
        }
    }

    func pause() async {
        musicPlayer.pause()
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
        
        let request = MusicRecentlyPlayedRequest()
        let response = try await request.response()
        
        return response.items.compactMap { item -> MediaContent? in
            switch item {
            case .song(let song):
                return MediaContent(
                    title: song.title,
                    contentID: song.id.rawValue,
                    artworkURL: song.artwork?.url(width: 300, height: 300),
                    duration: song.duration ?? 0,
                    contentType: .song
                )
            case .album(let album):
                return MediaContent(
                    title: album.title,
                    contentID: album.id.rawValue,
                    artworkURL: album.artwork?.url(width: 300, height: 300),
                    duration: 0,
                    contentType: .album
                )
            default:
                return nil
            }
        }
    }
    
    func fetchRecommendations() async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        // Get top charts as recommendations
        let request = MusicCatalogChartsRequest(kinds: [.mostPlayed], types: [Album.self])
        let response = try await request.response()
        
        var results: [MediaContent] = []
        
        // Add albums from charts
        for album in response.albumCharts.flatMap({ $0.items }) {
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
        
        let response = try await MusicLibrary.shared.playlists()
        
        return response.map { playlist in
            MediaContent(
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
        
        let response = try await MusicLibrary.shared.songs()
        
        return response.prefix(limit).map { song in
            MediaContent(
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
        
        let response = try await MusicLibrary.shared.albums()
        
        return response.prefix(limit).map { album in
            MediaContent(
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
        
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self, Album.self])
        request.limit = 20
        let response = try await request.response()
        
        var results: [MediaContent] = []
        
        // Add songs from search results
        for song in response.songs {
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
