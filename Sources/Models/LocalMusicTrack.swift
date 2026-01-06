import Foundation

/// Represents a locally stored music track in the SQLite database
public struct LocalMusicTrack: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let duration: TimeInterval
    public let filePath: String
    public let fileSize: Int64
    public let artworkPath: String?
    public let trackNumber: Int?
    public let genre: String?
    public let releaseYear: Int?
    public let bitrate: Int?
    public let sampleRate: Int?
    public let addedAt: Date
    public let lastModified: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        filePath: String,
        fileSize: Int64,
        artworkPath: String? = nil,
        trackNumber: Int? = nil,
        genre: String? = nil,
        releaseYear: Int? = nil,
        bitrate: Int? = nil,
        sampleRate: Int? = nil,
        addedAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.filePath = filePath
        self.fileSize = fileSize
        self.artworkPath = artworkPath
        self.trackNumber = trackNumber
        self.genre = genre
        self.releaseYear = releaseYear
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.addedAt = addedAt
        self.lastModified = lastModified
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Convert to MusicTrack for compatibility with existing code
    public func toMusicTrack() -> MusicTrack {
        return MusicTrack(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkURL: artworkPath
        )
    }
    
    public static func == (lhs: LocalMusicTrack, rhs: LocalMusicTrack) -> Bool {
        lhs.id == rhs.id
    }
}
