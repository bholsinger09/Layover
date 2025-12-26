import Foundation
import OSLog
import Observation

/// ViewModel for the user's personal library
@MainActor
@Observable
final class LibraryViewModel {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "LibraryViewModel")
    private let libraryService: LibraryServiceProtocol
    
    private(set) var favorites: [MediaContent] = []
    private(set) var recentlyWatched: [WatchHistoryItem] = []
    private(set) var stats: LibraryStats?
    private(set) var recommendations: [MediaContent] = []
    private(set) var isLoading = false
    
    init(libraryService: LibraryServiceProtocol) {
        self.libraryService = libraryService
        loadLibraryData()
    }
    
    func loadLibraryData() {
        isLoading = true
        logger.info("📚 Loading library data...")
        
        favorites = libraryService.library.favorites
        recentlyWatched = libraryService.library.recentlyWatched
        stats = libraryService.getStats()
        recommendations = libraryService.getRecommendations()
        
        logger.info("✅ Loaded \(favorites.count) favorites, \(recentlyWatched.count) recent items")
        isLoading = false
    }
    
    func toggleFavorite(_ content: MediaContent) async {
        if libraryService.isFavorite(content) {
            await libraryService.removeFromFavorites(content)
            logger.info("⭐ Removed from favorites: \(content.title)")
        } else {
            await libraryService.addToFavorites(content)
            logger.info("⭐ Added to favorites: \(content.title)")
        }
        loadLibraryData()
    }
    
    func isFavorite(_ content: MediaContent) -> Bool {
        libraryService.isFavorite(content)
    }
    
    func addToWatchHistory(_ content: MediaContent, duration: TimeInterval = 0, completed: Bool = false) async {
        await libraryService.addToWatchHistory(content, duration: duration, completed: completed)
        logger.info("📺 Added to watch history: \(content.title)")
        loadLibraryData()
    }
    
    func removeFromFavorites(_ content: MediaContent) async {
        await libraryService.removeFromFavorites(content)
        logger.info("🗑️ Removed from favorites: \(content.title)")
        loadLibraryData()
    }
    
    func clearHistory() async {
        // This would need to be implemented in the service
        logger.warning("⚠️ Clear history not yet implemented")
    }
}
