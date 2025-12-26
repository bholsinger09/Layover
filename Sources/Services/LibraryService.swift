import Foundation
import OSLog

/// Service for managing user's personal content library
@MainActor
protocol LibraryServiceProtocol: LayoverService {
    var library: UserLibrary { get }
    var musicLibrary: UserMusicLibrary { get }
    
    func addToFavorites(_ content: MediaContent) async
    func removeFromFavorites(_ content: MediaContent) async
    func toggleFavorite(_ content: MediaContent) async
    func isFavorite(_ content: MediaContent) -> Bool
    func addToWatchHistory(_ content: MediaContent, duration: TimeInterval, completed: Bool) async
    func getStats() -> LibraryStats
    func getRecommendations() -> [MediaContent]
    
    // Music library functions
    func addToFavorites(_ track: MusicTrack) async
    func removeFromFavorites(_ track: MusicTrack) async
    func toggleFavorite(_ track: MusicTrack) async
    func isFavorite(_ track: MusicTrack) -> Bool
    func addToFavorites(_ album: MusicAlbum) async
    func removeFromFavorites(_ album: MusicAlbum) async
    func toggleFavorite(_ album: MusicAlbum) async
    func isFavorite(_ album: MusicAlbum) -> Bool
    func createPlaylist(name: String, description: String?) async -> MusicPlaylist
    func deletePlaylist(_ playlist: MusicPlaylist) async
    func addTrackToPlaylist(_ track: MusicTrack, playlist: MusicPlaylist) async
    func removeTrackFromPlaylist(_ track: MusicTrack, playlist: MusicPlaylist) async
    func addToListeningHistory(_ track: MusicTrack, duration: TimeInterval, completed: Bool) async
    func getMusicRecommendations() -> [MusicTrack]
}

@MainActor
final class LibraryService: LibraryServiceProtocol {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "LibraryService")
    private let userDefaults = UserDefaults.standard
    private let libraryKey = "userLibrary"
    private let musicLibraryKey = "userMusicLibrary"
    
    private(set) var library: UserLibrary
    private(set) var musicLibrary: UserMusicLibrary
    
    init(userID: UUID = UUID()) {
        // Load existing library or create new one
        if let data = userDefaults.data(forKey: libraryKey),
           let decoded = try? JSONDecoder().decode(UserLibrary.self, from: data) {
            self.library = decoded
            logger.info("📚 Loaded existing library with \(decoded.favorites.count) favorites and \(decoded.watchHistory.count) history items")
        } else {
            self.library = UserLibrary(userID: userID)
            logger.info("📚 Created new library for user \(userID)")
        }
        
        // Load music library
        if let data = userDefaults.data(forKey: musicLibraryKey),
           let decoded = try? JSONDecoder().decode(UserMusicLibrary.self, from: data) {
            self.musicLibrary = decoded
            logger.info("🎵 Loaded existing music library with \(decoded.favoriteTracks.count) favorite tracks")
        } else {
            self.musicLibrary = UserMusicLibrary(userID: userID)
            logger.info("🎵 Created new music library for user \(userID)")
        }
    }
    
    func addToFavorites(_ content: MediaContent) async {
        library.addToFavorites(content)
        await saveLibrary()
        logger.info("⭐ Added '\(content.title)' to favorites")
    }
    
    func removeFromFavorites(_ content: MediaContent) async {
        library.removeFromFavorites(content)
        await saveLibrary()
        logger.info("⭐ Removed '\(content.title)' from favorites")
    }
    
    func toggleFavorite(_ content: MediaContent) async {
        if isFavorite(content) {
            await removeFromFavorites(content)
        } else {
            await addToFavorites(content)
        }
    }
    
    func isFavorite(_ content: MediaContent) -> Bool {
        library.isFavorite(content)
    }
    
    func addToWatchHistory(_ content: MediaContent, duration: TimeInterval = 0, completed: Bool = false) async {
        let item = WatchHistoryItem(
            content: content,
            watchedAt: Date(),
            watchDuration: duration,
            completed: completed
        )
        library.addToHistory(item)
        await saveLibrary()
        logger.info("📺 Added '\(content.title)' to watch history (duration: \(duration)s, completed: \(completed))")
    }
    
    func getStats() -> LibraryStats {
        LibraryStats.from(library: library)
    }
    
    func getRecommendations() -> [MediaContent] {
        // Simple recommendation algorithm based on favorites and watch history
        var recommendations: [MediaContent] = []
        
        // Get content similar to favorites (same type)
        let favoriteTypes = library.favorites.map { $0.contentType }
        
        // Sample Apple TV+ content for recommendations
        let allContent = getSampleContent()
        
        // Filter out already watched or favorited content
        let watchedIDs = Set(library.watchHistory.map { $0.content.contentID })
        let favoriteIDs = Set(library.favorites.map { $0.contentID })
        let excludedIDs = watchedIDs.union(favoriteIDs)
        
        recommendations = allContent.filter { !excludedIDs.contains($0.contentID) }
        
        // Prioritize content of same type as favorites
        if !favoriteTypes.isEmpty {
            recommendations.sort { content1, content2 in
                let match1 = favoriteTypes.contains(content1.contentType)
                let match2 = favoriteTypes.contains(content2.contentType)
                return match1 && !match2
            }
        }
        
        return Array(recommendations.prefix(10))
    }
    
    private func saveLibrary() async {
        do {
            let encoded = try JSONEncoder().encode(library)
            userDefaults.set(encoded, forKey: libraryKey)
            logger.debug("💾 Library saved successfully")
        } catch {
            logger.error("❌ Failed to save library: \(error.localizedDescription)")
        }
    }
    
    private func saveMusicLibrary() async {
        do {
            let encoded = try JSONEncoder().encode(musicLibrary)
            userDefaults.set(encoded, forKey: musicLibraryKey)
            logger.debug("💾 Music library saved successfully")
        } catch {
            logger.error("❌ Failed to save music library: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Music Library Functions
    
    func addToFavorites(_ track: MusicTrack) async {
        musicLibrary.addToFavorites(track)
        await saveMusicLibrary()
        logger.info("⭐ Added '\(track.title)' to favorite tracks")
    }
    
    func removeFromFavorites(_ track: MusicTrack) async {
        musicLibrary.removeFromFavorites(track)
        await saveMusicLibrary()
        logger.info("⭐ Removed '\(track.title)' from favorite tracks")
    }
    
    func toggleFavorite(_ track: MusicTrack) async {
        if isFavorite(track) {
            await removeFromFavorites(track)
        } else {
            await addToFavorites(track)
        }
    }
    
    func isFavorite(_ track: MusicTrack) -> Bool {
        musicLibrary.isFavorite(track)
    }
    
    func addToFavorites(_ album: MusicAlbum) async {
        musicLibrary.addToFavorites(album)
        await saveMusicLibrary()
        logger.info("⭐ Added '\(album.title)' to favorite albums")
    }
    
    func removeFromFavorites(_ album: MusicAlbum) async {
        musicLibrary.removeFromFavorites(album)
        await saveMusicLibrary()
        logger.info("⭐ Removed '\(album.title)' from favorite albums")
    }
    
    func toggleFavorite(_ album: MusicAlbum) async {
        if isFavorite(album) {
            await removeFromFavorites(album)
        } else {
            await addToFavorites(album)
        }
    }
    
    func isFavorite(_ album: MusicAlbum) -> Bool {
        musicLibrary.isFavorite(album)
    }
    
    func createPlaylist(name: String, description: String?) async -> MusicPlaylist {
        let playlist = MusicPlaylist(name: name, description: description)
        musicLibrary.addPlaylist(playlist)
        await saveMusicLibrary()
        logger.info("📝 Created playlist '\(name)'")
        return playlist
    }
    
    func deletePlaylist(_ playlist: MusicPlaylist) async {
        musicLibrary.removePlaylist(playlist)
        await saveMusicLibrary()
        logger.info("🗑️ Deleted playlist '\(playlist.name)'")
    }
    
    func addTrackToPlaylist(_ track: MusicTrack, playlist: MusicPlaylist) async {
        var updatedPlaylist = playlist
        if !updatedPlaylist.tracks.contains(where: { $0.id == track.id }) {
            updatedPlaylist.tracks.append(track)
            musicLibrary.updatePlaylist(updatedPlaylist)
            await saveMusicLibrary()
            logger.info("➕ Added '\(track.title)' to playlist '\(playlist.name)'")
        }
    }
    
    func removeTrackFromPlaylist(_ track: MusicTrack, playlist: MusicPlaylist) async {
        var updatedPlaylist = playlist
        updatedPlaylist.tracks.removeAll { $0.id == track.id }
        musicLibrary.updatePlaylist(updatedPlaylist)
        await saveMusicLibrary()
        logger.info("➖ Removed '\(track.title)' from playlist '\(playlist.name)'")
    }
    
    func addToListeningHistory(_ track: MusicTrack, duration: TimeInterval, completed: Bool) async {
        let item = MusicHistoryItem(track: track, playedAt: Date(), listenDuration: duration, completed: completed)
        musicLibrary.addToHistory(item)
        await saveMusicLibrary()
        logger.info("🎵 Added '\(track.title)' to listening history")
    }
    
    func getMusicRecommendations() -> [MusicTrack] {
        // Simple recommendation: return sample tracks not in favorites
        let sampleTracks = getSampleMusicTracks()
        let favoriteIDs = Set(musicLibrary.favoriteTracks.map { $0.id })
        return sampleTracks.filter { !favoriteIDs.contains($0.id) }
    }
    
    private func getSampleMusicTracks() -> [MusicTrack] {
        [
            MusicTrack(title: "Anti-Hero", artist: "Taylor Swift", album: "Midnights", duration: 200),
            MusicTrack(title: "Flowers", artist: "Miley Cyrus", album: "Endless Summer Vacation", duration: 200),
            MusicTrack(title: "As It Was", artist: "Harry Styles", album: "Harry's House", duration: 167),
            MusicTrack(title: "Cruel Summer", artist: "Taylor Swift", album: "Lover", duration: 178),
            MusicTrack(title: "Vampire", artist: "Olivia Rodrigo", album: "GUTS", duration: 219),
            MusicTrack(title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200),
            MusicTrack(title: "Levitating", artist: "Dua Lipa", album: "Future Nostalgia", duration: 203),
            MusicTrack(title: "good 4 u", artist: "Olivia Rodrigo", album: "SOUR", duration: 178),
            MusicTrack(title: "Heat Waves", artist: "Glass Animals", album: "Dreamland", duration: 239),
            MusicTrack(title: "Stay", artist: "The Kid LAROI & Justin Bieber", album: "Stay", duration: 141),
        ]
    }
    
    /// Sample content for recommendations
    private func getSampleContent() -> [MediaContent] {
        [
            MediaContent(title: "Ted Lasso", contentID: "umc.cmc.vtoh0mn0xn7t3c643xqonfzy", duration: 3600, contentType: .tvShow),
            MediaContent(title: "Foundation", contentID: "umc.cmc.5983fipzqbicvrve6jdfep4x3", duration: 3600, contentType: .tvShow),
            MediaContent(title: "Severance", contentID: "umc.cmc.1srk2goyh2q2zdxcx605w8vtx", duration: 3600, contentType: .tvShow),
            MediaContent(title: "The Morning Show", contentID: "umc.cmc.25tn3v8ku4b39tr6ccgb8nl6m", duration: 3600, contentType: .tvShow),
            MediaContent(title: "For All Mankind", contentID: "umc.cmc.6wsi780sz5tdbqcf11k76mkp7", duration: 3600, contentType: .tvShow),
            MediaContent(title: "Silo", contentID: "umc.cmc.3xx8h9n7p3wintj0gw1gg1ebc", duration: 3600, contentType: .tvShow),
            MediaContent(title: "Shrinking", contentID: "umc.cmc.3j1l0mzkcp94jy1trg74lh71c", duration: 1800, contentType: .tvShow),
            MediaContent(title: "Slow Horses", contentID: "umc.cmc.3j91e0rvlcasd9w3xfm5bx4n2", duration: 3000, contentType: .tvShow),
            MediaContent(title: "Hijack", contentID: "umc.cmc.4s4v02k31x63t4cqks6w0nzcq", duration: 3600, contentType: .tvShow),
            MediaContent(title: "The Last Thing He Told Me", contentID: "umc.cmc.2vpk2qlqfn2zqp9v1b5v9hwdb", duration: 3000, contentType: .tvShow),
            MediaContent(title: "Monarch: Legacy of Monsters", contentID: "umc.cmc.54uus12z3rpkn1hwq1p0u4ksu", duration: 3600, contentType: .tvShow),
            MediaContent(title: "Masters of the Air", contentID: "umc.cmc.3k7y5fdbn1bfz0b1wqnvlm8kk", duration: 3600, contentType: .tvShow),
            MediaContent(title: "Killers of the Flower Moon", contentID: "umc.cmc.5xd3q2r4kz35uu2vfz6r0dkr7", duration: 12600, contentType: .movie),
            MediaContent(title: "Napoleon", contentID: "umc.cmc.7dz2abl3gd6l5p2kjvx36v9xg", duration: 9480, contentType: .movie),
            MediaContent(title: "CODA", contentID: "umc.cmc.3eh9r5iz32ggdm4ccvw5igiir", duration: 6660, contentType: .movie),
        ]
    }
}
