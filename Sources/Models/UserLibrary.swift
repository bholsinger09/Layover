import Foundation

/// Represents a user's personal content library
struct UserLibrary: Codable {
    var favorites: [MediaContent]
    var watchHistory: [WatchHistoryItem]
    var userID: UUID
    
    init(userID: UUID) {
        self.userID = userID
        self.favorites = []
        self.watchHistory = []
    }
    
    /// Get unique content from watch history (no duplicates)
    var uniqueWatchedContent: [MediaContent] {
        var seen = Set<String>()
        return watchHistory.compactMap { item in
            guard !seen.contains(item.content.contentID) else { return nil }
            seen.insert(item.content.contentID)
            return item.content
        }
    }
    
    /// Calculate total watch time in seconds
    var totalWatchTime: TimeInterval {
        watchHistory.reduce(0) { $0 + $1.watchDuration }
    }
    
    /// Get favorite genres based on watch history
    var favoriteGenres: [String] {
        let genreCounts = watchHistory.reduce(into: [String: Int]()) { counts, item in
            let genre = item.content.contentType == .movie ? "Movies" : "TV Shows"
            counts[genre, default: 0] += 1
        }
        return genreCounts.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    /// Get most watched content
    var mostWatchedContent: [MediaContent] {
        let contentCounts = watchHistory.reduce(into: [String: (content: MediaContent, count: Int)]()) { counts, item in
            let id = item.content.contentID
            if let existing = counts[id] {
                counts[id] = (existing.content, existing.count + 1)
            } else {
                counts[id] = (item.content, 1)
            }
        }
        return contentCounts.values
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0.content }
    }
    
    /// Get recently watched content
    var recentlyWatched: [WatchHistoryItem] {
        watchHistory
            .sorted { $0.watchedAt > $1.watchedAt }
            .prefix(20)
            .map { $0 }
    }
    
    /// Check if content is in favorites
    func isFavorite(_ content: MediaContent) -> Bool {
        favorites.contains { $0.contentID == content.contentID }
    }
    
    /// Add content to favorites
    mutating func addToFavorites(_ content: MediaContent) {
        guard !isFavorite(content) else { return }
        favorites.append(content)
    }
    
    /// Remove content from favorites
    mutating func removeFromFavorites(_ content: MediaContent) {
        favorites.removeAll { $0.contentID == content.contentID }
    }
    
    /// Add to watch history
    mutating func addToHistory(_ item: WatchHistoryItem) {
        watchHistory.append(item)
    }
}

/// Represents a single watch history entry
struct WatchHistoryItem: Codable, Identifiable {
    let id: UUID
    let content: MediaContent
    let watchedAt: Date
    let watchDuration: TimeInterval // How long was watched in seconds
    let completed: Bool // Whether they finished watching
    
    init(content: MediaContent, watchedAt: Date = Date(), watchDuration: TimeInterval = 0, completed: Bool = false) {
        self.id = UUID()
        self.content = content
        self.watchedAt = watchedAt
        self.watchDuration = watchDuration
        self.completed = completed
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: watchedAt, relativeTo: Date())
    }
}

/// User statistics and insights
struct LibraryStats {
    let totalWatchTime: TimeInterval
    let favoriteGenres: [String]
    let totalMovies: Int
    let totalTVShows: Int
    let totalFavorites: Int
    let mostWatchedContent: [MediaContent]
    let recentStreak: Int // Days watched in a row
    
    /// Format watch time as human readable
    var formattedWatchTime: String {
        let hours = Int(totalWatchTime) / 3600
        let minutes = (Int(totalWatchTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    static func from(library: UserLibrary) -> LibraryStats {
        let movieCount = library.watchHistory.filter { $0.content.contentType == .movie }.count
        let tvShowCount = library.watchHistory.filter { $0.content.contentType == .tvShow }.count
        
        return LibraryStats(
            totalWatchTime: library.totalWatchTime,
            favoriteGenres: library.favoriteGenres,
            totalMovies: movieCount,
            totalTVShows: tvShowCount,
            totalFavorites: library.favorites.count,
            mostWatchedContent: library.mostWatchedContent,
            recentStreak: calculateStreak(from: library.watchHistory)
        )
    }
    
    private static func calculateStreak(from history: [WatchHistoryItem]) -> Int {
        guard !history.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = history
            .map { calendar.startOfDay(for: $0.watchedAt) }
            .sorted(by: >)
        
        guard let mostRecent = sortedDates.first else { return 0 }
        
        // Check if streak is still active (watched today or yesterday)
        let today = calendar.startOfDay(for: Date())
        guard mostRecent >= calendar.date(byAdding: .day, value: -1, to: today)! else { return 0 }
        
        var streak = 1
        var currentDate = mostRecent
        
        for date in sortedDates.dropFirst() {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            
            if date == previousDay {
                streak += 1
                currentDate = date
            } else if date < previousDay {
                break
            }
        }
        
        return streak
    }
}
