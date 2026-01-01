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
        
        var request = MusicRecentlyPlayedRequest()
        request.limit = 20
        let response = try await request.response()
        
        return response.items.compactMap { item -> MediaContent? in
            switch item {
            case .song(let song):
                return MediaContent(
                    title: song.title,
                    contentID: song.id.rawValue,
                    duration: Int(song.duration ?? 0),
                    contentType: .song,
                    artworkURL: song.artwork?.url(width: 300, height: 300)
                )
            case .album(let album):
                return MediaContent(
                    title: album.title,
                    contentID: album.id.rawValue,
                    duration: 0,
                    contentType: .album,
                    artworkURL: album.artwork?.url(width: 300, height: 300)
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
        
        // Get personalized recommendations
        var request = MusicPersonalRecommendationRequest()
        request.limit = 20
        let response = try await request.response()
        
        return response.recommendations.flatMap { recommendation -> [MediaContent] in
            recommendation.albums?.compactMap { album in
                MediaContent(
                    title: album.title,
                    contentID: album.id.rawValue,
                    duration: 0,
                    contentType: .album,
                    artworkURL: album.artwork?.url(width: 300, height: 300)
                )
            } ?? []
        }
    }
    
    func fetchPlaylists() async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        var request = MusicLibraryRequest<Playlist>()
        request.limit = 25
        let response = try await request.response()
        
        return response.items.map { playlist in
            MediaContent(
                title: playlist.name,
                contentID: playlist.id.rawValue,
                duration: 0,
                contentType: .playlist,
                artworkURL: playlist.artwork?.url(width: 300, height: 300)
            )
        }
    }
    
    func fetchSongs(limit: Int = 50) async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        let response = try await request.response()
        
        return response.items.map { song in
            MediaContent(
                title: song.title,
                contentID: song.id.rawValue,
                duration: Int(song.duration ?? 0),
                contentType: .song,
                artworkURL: song.artwork?.url(width: 300, height: 300)
            )
        }
    }
    
    func fetchAlbums(limit: Int = 50) async throws -> [MediaContent] {
        guard await isAuthorized else {
            throw MusicError.notAuthorized
        }
        
        var request = MusicLibraryRequest<Album>()
        request.limit = limit
        let response = try await request.response()
        
        return response.items.map { album in
            MediaContent(
                title: album.title,
                contentID: album.id.rawValue,
                duration: 0,
                contentType: .album,
                artworkURL: album.artwork?.url(width: 300, height: 300)
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
        if let songs = response.songs {
            results += songs.map { song in
                MediaContent(
                    title: song.title,
                    contentID: song.id.rawValue,
                    duration: Int(song.duration ?? 0),
                    contentType: .song,
                    artworkURL: song.artwork?.url(width: 300, height: 300)
                )
            }
        }
        
        // Add albums from search results
        if let albums = response.albums {
            results += albums.map { album in
                MediaContent(
                    title: album.title,
                    contentID: album.id.rawValue,
                    duration: 0,
                    contentType: .album,
                    artworkURL: album.artwork?.url(width: 300, height: 300)
                )
            }
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
            duration: 0,
            contentType: .playlist,
            artworkURL: playlist.artwork?.url(width: 300, height: 300)
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
