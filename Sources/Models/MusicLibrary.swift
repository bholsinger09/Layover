import Foundation

/// Represents a music track
struct MusicTrack: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: String?
    
    init(id: String = UUID().uuidString, title: String, artist: String, album: String, duration: TimeInterval, artworkURL: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    static func == (lhs: MusicTrack, rhs: MusicTrack) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a music album
struct MusicAlbum: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let trackCount: Int
    let releaseYear: Int?
    let artworkURL: String?
    
    init(id: String = UUID().uuidString, title: String, artist: String, trackCount: Int, releaseYear: Int? = nil, artworkURL: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.trackCount = trackCount
        self.releaseYear = releaseYear
        self.artworkURL = artworkURL
    }
    
    static func == (lhs: MusicAlbum, rhs: MusicAlbum) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a music playlist
struct MusicPlaylist: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var description: String?
    var tracks: [MusicTrack]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, tracks: [MusicTrack] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.tracks = tracks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var duration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    static func == (lhs: MusicPlaylist, rhs: MusicPlaylist) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a music listening history item
struct MusicHistoryItem: Codable, Identifiable {
    let id: UUID
    let track: MusicTrack
    let playedAt: Date
    let listenDuration: TimeInterval
    let completed: Bool
    
    init(id: UUID = UUID(), track: MusicTrack, playedAt: Date = Date(), listenDuration: TimeInterval = 0, completed: Bool = false) {
        self.id = id
        self.track = track
        self.playedAt = playedAt
        self.listenDuration = listenDuration
        self.completed = completed
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: playedAt, relativeTo: Date())
    }
}

/// User's music library data
struct UserMusicLibrary: Codable {
    var favoriteTracks: [MusicTrack]
    var favoriteAlbums: [MusicAlbum]
    var playlists: [MusicPlaylist]
    var listeningHistory: [MusicHistoryItem]
    var userID: UUID
    
    init(userID: UUID) {
        self.userID = userID
        self.favoriteTracks = []
        self.favoriteAlbums = []
        self.playlists = []
        self.listeningHistory = []
    }
    
    var totalListenTime: TimeInterval {
        listeningHistory.reduce(0) { $0 + $1.listenDuration }
    }
    
    var formattedListenTime: String {
        let hours = Int(totalListenTime) / 3600
        let minutes = (Int(totalListenTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var recentlyPlayed: [MusicHistoryItem] {
        listeningHistory
            .sorted { $0.playedAt > $1.playedAt }
            .prefix(20)
            .map { $0 }
    }
    
    var topArtists: [String] {
        let artistCounts = listeningHistory.reduce(into: [String: Int]()) { counts, item in
            counts[item.track.artist, default: 0] += 1
        }
        return artistCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    mutating func addToFavorites(_ track: MusicTrack) {
        guard !favoriteTracks.contains(where: { $0.id == track.id }) else { return }
        favoriteTracks.append(track)
    }
    
    mutating func removeFromFavorites(_ track: MusicTrack) {
        favoriteTracks.removeAll { $0.id == track.id }
    }
    
    mutating func addToFavorites(_ album: MusicAlbum) {
        guard !favoriteAlbums.contains(where: { $0.id == album.id }) else { return }
        favoriteAlbums.append(album)
    }
    
    mutating func removeFromFavorites(_ album: MusicAlbum) {
        favoriteAlbums.removeAll { $0.id == album.id }
    }
    
    mutating func addPlaylist(_ playlist: MusicPlaylist) {
        playlists.append(playlist)
    }
    
    mutating func removePlaylist(_ playlist: MusicPlaylist) {
        playlists.removeAll { $0.id == playlist.id }
    }
    
    mutating func updatePlaylist(_ playlist: MusicPlaylist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            var updated = playlist
            updated.updatedAt = Date()
            playlists[index] = updated
        }
    }
    
    mutating func addToHistory(_ item: MusicHistoryItem) {
        listeningHistory.append(item)
    }
    
    func isFavorite(_ track: MusicTrack) -> Bool {
        favoriteTracks.contains(where: { $0.id == track.id })
    }
    
    func isFavorite(_ album: MusicAlbum) -> Bool {
        favoriteAlbums.contains(where: { $0.id == album.id })
    }
}
