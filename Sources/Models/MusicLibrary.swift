import Foundation

/// Represents a music track
public struct MusicTrack: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let duration: TimeInterval
    public let artworkURL: String?
    public let fileURL: String?  // Local file path for imported tracks
    
    public init(id: String = UUID().uuidString, title: String, artist: String, album: String, duration: TimeInterval, artworkURL: String? = nil, fileURL: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
        self.fileURL = fileURL
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public static func == (lhs: MusicTrack, rhs: MusicTrack) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a music album
public struct MusicAlbum: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let trackCount: Int
    public let releaseYear: Int?
    public let artworkURL: String?
    
    public init(id: String = UUID().uuidString, title: String, artist: String, trackCount: Int, releaseYear: Int? = nil, artworkURL: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.trackCount = trackCount
        self.releaseYear = releaseYear
        self.artworkURL = artworkURL
    }
    
    public static func == (lhs: MusicAlbum, rhs: MusicAlbum) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a music playlist
public struct MusicPlaylist: Codable, Identifiable, Equatable {
    public let id: String
    public var name: String
    public var description: String?
    public var tracks: [MusicTrack]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString, name: String, description: String? = nil, tracks: [MusicTrack] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.tracks = tracks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var duration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    public var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    public static func == (lhs: MusicPlaylist, rhs: MusicPlaylist) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a music listening history item
public struct MusicHistoryItem: Codable, Identifiable {
    public let id: UUID
    public let track: MusicTrack
    public let playedAt: Date
    public let listenDuration: TimeInterval
    public let completed: Bool
    
    public init(id: UUID = UUID(), track: MusicTrack, playedAt: Date = Date(), listenDuration: TimeInterval = 0, completed: Bool = false) {
        self.id = id
        self.track = track
        self.playedAt = playedAt
        self.listenDuration = listenDuration
        self.completed = completed
    }
    
    public var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: playedAt, relativeTo: Date())
    }
}

/// User's music library data
public struct UserMusicLibrary: Codable {
    public var favoriteTracks: [MusicTrack]
    public var favoriteAlbums: [MusicAlbum]
    public var playlists: [MusicPlaylist]
    public var listeningHistory: [MusicHistoryItem]
    public var userID: UUID
    
    public init(userID: UUID) {
        self.userID = userID
        self.favoriteTracks = []
        self.favoriteAlbums = []
        self.playlists = []
        self.listeningHistory = []
    }
    
    public var totalListenTime: TimeInterval {
        listeningHistory.reduce(0) { $0 + $1.listenDuration }
    }
    
    public var formattedListenTime: String {
        let hours = Int(totalListenTime) / 3600
        let minutes = (Int(totalListenTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    public var recentlyPlayed: [MusicHistoryItem] {
        listeningHistory
            .sorted { $0.playedAt > $1.playedAt }
            .prefix(20)
            .map { $0 }
    }
    
    public var topArtists: [String] {
        let artistCounts = listeningHistory.reduce(into: [String: Int]()) { counts, item in
            counts[item.track.artist, default: 0] += 1
        }
        return artistCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    public mutating func addToFavorites(_ track: MusicTrack) {
        guard !favoriteTracks.contains(where: { $0.id == track.id }) else { return }
        favoriteTracks.append(track)
    }
    
    public mutating func removeFromFavorites(_ track: MusicTrack) {
        favoriteTracks.removeAll { $0.id == track.id }
    }
    
    public mutating func addToFavorites(_ album: MusicAlbum) {
        guard !favoriteAlbums.contains(where: { $0.id == album.id }) else { return }
        favoriteAlbums.append(album)
    }
    
    public mutating func removeFromFavorites(_ album: MusicAlbum) {
        favoriteAlbums.removeAll { $0.id == album.id }
    }
    
    public mutating func addPlaylist(_ playlist: MusicPlaylist) {
        playlists.append(playlist)
    }
    
    public mutating func removePlaylist(_ playlist: MusicPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
    }
    
    public mutating func updatePlaylist(_ playlist: MusicPlaylist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updated = playlist
            updated.updatedAt = Date()
            playlists[index] = updated
        }
    }
    
    public mutating func addToHistory(_ item: MusicHistoryItem) {
        listeningHistory.append(item)
    }
    
    public func isFavorite(_ track: MusicTrack) -> Bool {
        favoriteTracks.contains(where: { $0.id == track.id })
    }
    
    public func isFavorite(_ album: MusicAlbum) -> Bool {
        favoriteAlbums.contains(where: { $0.id == album.id })
    }
}
