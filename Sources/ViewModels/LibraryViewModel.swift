import Foundation
import OSLog
import Observation

/// ViewModel for the user's personal library
@MainActor
@Observable
public final class LibraryViewModel {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "LibraryViewModel")
    private let libraryService: LibraryServiceProtocol
    private let aiService: AIRecommendationServiceProtocol
    
    public private(set) var favorites: [MediaContent] = []
    public private(set) var recentlyWatched: [WatchHistoryItem] = []
    public private(set) var stats: LibraryStats?
    public private(set) var recommendations: [MediaContent] = []
    public private(set) var isLoading = false
    
    // Music Library
    public private(set) var favoriteTracks: [MusicTrack] = []
    public private(set) var favoriteAlbums: [MusicAlbum] = []
    public private(set) var playlists: [MusicPlaylist] = []
    public private(set) var musicHistory: [MusicHistoryItem] = []
    public private(set) var musicRecommendations: [MusicTrack] = []
    
    // AI Search Results
    public private(set) var aiMovieResults: [MediaContent] = []
    public private(set) var aiMusicResults: [MusicTrack] = []
    public private(set) var isSearching = false
    
    public init(libraryService: LibraryServiceProtocol, aiService: AIRecommendationServiceProtocol? = nil) {
        self.libraryService = libraryService
        self.aiService = aiService ?? AIRecommendationService()
        loadLibraryData()
    }
    
    public func loadLibraryData() {
        isLoading = true
        logger.info("📚 Loading library data...")
        
        // Video library
        self.favorites = libraryService.library.favorites
        self.recentlyWatched = libraryService.library.recentlyWatched
        self.stats = libraryService.getStats()
        self.recommendations = libraryService.getRecommendations()
        
        // Music library
        self.favoriteTracks = libraryService.musicLibrary.favoriteTracks
        self.favoriteAlbums = libraryService.musicLibrary.favoriteAlbums
        self.playlists = libraryService.musicLibrary.playlists
        self.musicHistory = libraryService.musicLibrary.recentlyPlayed
        self.musicRecommendations = libraryService.getMusicRecommendations()
        
        logger.info("✅ Loaded \(self.favorites.count) favorites, \(self.favoriteTracks.count) favorite tracks")
        isLoading = false
    }
    
    public func toggleFavorite(_ content: MediaContent) async {
        if libraryService.isFavorite(content) {
            await libraryService.removeFromFavorites(content)
            logger.info("⭐ Removed from favorites: \(content.title)")
        } else {
            await libraryService.addToFavorites(content)
            logger.info("⭐ Added to favorites: \(content.title)")
        }
        loadLibraryData()
    }
    
    public func isFavorite(_ content: MediaContent) -> Bool {
        libraryService.isFavorite(content)
    }
    
    public func addToWatchHistory(_ content: MediaContent, duration: TimeInterval = 0, completed: Bool = false) async {
        await libraryService.addToWatchHistory(content, duration: duration, completed: completed)
        logger.info("📺 Added to watch history: \(content.title)")
        loadLibraryData()
    }
    
    public func removeFromFavorites(_ content: MediaContent) async {
        await libraryService.removeFromFavorites(content)
        logger.info("🗑️ Removed from favorites: \(content.title)")
        loadLibraryData()
    }
    
    public func clearHistory() async {
        // This would need to be implemented in the service
        logger.warning("⚠️ Clear history not yet implemented")
    }
    
    // MARK: - Music Functions
    
    public func toggleFavorite(_ track: MusicTrack) async {
        let wasFavorite = libraryService.isFavorite(track)
        logger.info("🎵 Toggling favorite for '\(track.title)' - currently favorite: \(wasFavorite)")
        
        await libraryService.toggleFavorite(track)
        
        let isFavorite = libraryService.isFavorite(track)
        logger.info("🎵 After toggle, '\(track.title)' is favorite: \(isFavorite)")
        
        loadLibraryData()
        logger.info("🎵 Reloaded library data - favoriteTracks count: \(self.favoriteTracks.count)")
    }
    
    public func toggleFavorite(_ album: MusicAlbum) async {
        await libraryService.toggleFavorite(album)
        loadLibraryData()
    }
    
    public func isFavorite(_ track: MusicTrack) -> Bool {
        let result = libraryService.isFavorite(track)
        return result
    }
    
    public func isFavorite(_ album: MusicAlbum) -> Bool {
        libraryService.isFavorite(album)
    }
    
    public func createPlaylist(name: String, description: String? = nil) async -> MusicPlaylist {
        let playlist = await libraryService.createPlaylist(name: name, description: description)
        loadLibraryData()
        return playlist
    }
    
    public func deletePlaylist(_ playlist: MusicPlaylist) async {
        await libraryService.deletePlaylist(playlist)
        loadLibraryData()
    }
    
    public func addTrackToPlaylist(_ track: MusicTrack, playlist: MusicPlaylist) async {
        await libraryService.addTrackToPlaylist(track, playlist: playlist)
        loadLibraryData()
    }
    
    public func removeTrackFromPlaylist(_ track: MusicTrack, playlist: MusicPlaylist) async {
        await libraryService.removeTrackFromPlaylist(track, playlist: playlist)
        loadLibraryData()
    }
    
    // MARK: - AI Search Functions
    
    public func searchMoviesWithAI(query: String) async {
        guard !query.isEmpty else {
            aiMovieResults = []
            return
        }
        
        isSearching = true
        logger.info("🤖 Searching movies with AI: \(query)")
        
        do {
            self.aiMovieResults = try await aiService.searchMoviesAndTV(query: query)
            logger.info("✅ AI found \(self.aiMovieResults.count) movie/TV results")
        } catch {
            logger.error("❌ AI search failed: \(error.localizedDescription)")
            self.aiMovieResults = []
        }
        
        isSearching = false
    }
    
    public func searchMusicWithAI(query: String) async {
        guard !query.isEmpty else {
            aiMusicResults = []
            return
        }
        
        isSearching = true
        logger.info("🤖 Searching music with AI: \(query)")
        print("🔍 VIEWMODEL: Starting search for: \(query)")
        
        do {
            let results = try await aiService.searchMusic(query: query)
            print("🔍 VIEWMODEL: Got \(results.count) results from service")
            self.aiMusicResults = results
            print("🔍 VIEWMODEL: aiMusicResults now has \(self.aiMusicResults.count) items")
            logger.info("✅ AI found \(self.aiMusicResults.count) music results")
        } catch {
            print("🔍 VIEWMODEL: Error occurred: \(error)")
            logger.error("❌ AI search failed: \(error.localizedDescription)")
            self.aiMusicResults = []
        }
        
        isSearching = false
        print("🔍 VIEWMODEL: Search complete, isSearching = false")
    }
    
    public func clearAIResults() {
        aiMovieResults = []
        aiMusicResults = []
    }
}
