import Foundation
import OSLog

/// Service for managing user's personal content library
@MainActor
protocol LibraryServiceProtocol: LayoverService {
    var library: UserLibrary { get }
    
    func addToFavorites(_ content: MediaContent) async
    func removeFromFavorites(_ content: MediaContent) async
    func toggleFavorite(_ content: MediaContent) async
    func isFavorite(_ content: MediaContent) -> Bool
    func addToWatchHistory(_ content: MediaContent, duration: TimeInterval, completed: Bool) async
    func getStats() -> LibraryStats
    func getRecommendations() -> [MediaContent]
}

@MainActor
final class LibraryService: LibraryServiceProtocol {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "LibraryService")
    private let userDefaults = UserDefaults.standard
    private let libraryKey = "userLibrary"
    
    private(set) var library: UserLibrary
    
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
