import Foundation
import SQLite3

/// Service for managing the local music SQLite database
public class MusicDatabaseService {
    private var db: OpaquePointer?
    private let dbPath: String
    
    public enum DatabaseError: Error {
        case failedToOpen(String)
        case failedToCreateTable(String)
        case failedToInsert(String)
        case failedToUpdate(String)
        case failedToDelete(String)
        case failedToQuery(String)
        case invalidData
    }
    
    public init(dbPath: String? = nil) {
        // Default to app support directory
        if let customPath = dbPath {
            self.dbPath = customPath
        } else {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let layoverDir = appSupport.appendingPathComponent("Layover", isDirectory: true)
            
            if !fileManager.fileExists(atPath: layoverDir.path) {
                try? fileManager.createDirectory(at: layoverDir, withIntermediateDirectories: true)
            }
            
            self.dbPath = layoverDir.appendingPathComponent("music_library.db").path
        }
    }
    
    /// Open the database connection
    public func openDatabase() throws {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            throw DatabaseError.failedToOpen("Unable to open database at \(dbPath)")
        }
        try createTables()
    }
    
    /// Close the database connection
    public func closeDatabase() {
        sqlite3_close(db)
        db = nil
    }
    
    /// Create the necessary tables
    private func createTables() throws {
        let createTracksTable = """
        CREATE TABLE IF NOT EXISTS tracks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            album TEXT NOT NULL,
            duration REAL NOT NULL,
            file_path TEXT UNIQUE NOT NULL,
            file_size INTEGER NOT NULL,
            artwork_path TEXT,
            track_number INTEGER,
            genre TEXT,
            release_year INTEGER,
            bitrate INTEGER,
            sample_rate INTEGER,
            added_at REAL NOT NULL,
            last_modified REAL NOT NULL
        );
        """
        
        let createIndexes = """
        CREATE INDEX IF NOT EXISTS idx_artist ON tracks(artist);
        CREATE INDEX IF NOT EXISTS idx_album ON tracks(album);
        CREATE INDEX IF NOT EXISTS idx_genre ON tracks(genre);
        CREATE INDEX IF NOT EXISTS idx_added_at ON tracks(added_at);
        """
        
        try executeSQL(createTracksTable)
        try executeSQL(createIndexes)
    }
    
    /// Execute a SQL statement
    private func executeSQL(_ sql: String) throws {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.failedToCreateTable(error)
        }
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let error = String(cString: sqlite3_errmsg(db))
            sqlite3_finalize(statement)
            throw DatabaseError.failedToCreateTable(error)
        }
        
        sqlite3_finalize(statement)
    }
    
    // MARK: - CRUD Operations
    
    /// Insert a new track into the database
    public func insertTrack(_ track: LocalMusicTrack) throws {
        let sql = """
        INSERT OR REPLACE INTO tracks (
            id, title, artist, album, duration, file_path, file_size,
            artwork_path, track_number, genre, release_year, bitrate,
            sample_rate, added_at, last_modified
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.failedToInsert(String(cString: sqlite3_errmsg(db)))
        }
        
        sqlite3_bind_text(statement, 1, (track.id as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (track.title as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (track.artist as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (track.album as NSString).utf8String, -1, nil)
        sqlite3_bind_double(statement, 5, track.duration)
        sqlite3_bind_text(statement, 6, (track.filePath as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(statement, 7, track.fileSize)
        
        if let artworkPath = track.artworkPath {
            sqlite3_bind_text(statement, 8, (artworkPath as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 8)
        }
        
        if let trackNumber = track.trackNumber {
            sqlite3_bind_int(statement, 9, Int32(trackNumber))
        } else {
            sqlite3_bind_null(statement, 9)
        }
        
        if let genre = track.genre {
            sqlite3_bind_text(statement, 10, (genre as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 10)
        }
        
        if let releaseYear = track.releaseYear {
            sqlite3_bind_int(statement, 11, Int32(releaseYear))
        } else {
            sqlite3_bind_null(statement, 11)
        }
        
        if let bitrate = track.bitrate {
            sqlite3_bind_int(statement, 12, Int32(bitrate))
        } else {
            sqlite3_bind_null(statement, 12)
        }
        
        if let sampleRate = track.sampleRate {
            sqlite3_bind_int(statement, 13, Int32(sampleRate))
        } else {
            sqlite3_bind_null(statement, 13)
        }
        
        sqlite3_bind_double(statement, 14, track.addedAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 15, track.lastModified.timeIntervalSince1970)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let error = String(cString: sqlite3_errmsg(db))
            sqlite3_finalize(statement)
            throw DatabaseError.failedToInsert(error)
        }
        
        sqlite3_finalize(statement)
    }
    
    /// Get all tracks from the database
    public func getAllTracks() throws -> [LocalMusicTrack] {
        let sql = "SELECT * FROM tracks ORDER BY artist, album, track_number;"
        return try queryTracks(sql)
    }
    
    /// Get tracks by artist
    public func getTracksByArtist(_ artist: String) throws -> [LocalMusicTrack] {
        let sql = "SELECT * FROM tracks WHERE artist = ? ORDER BY album, track_number;"
        return try queryTracks(sql, bindings: [artist])
    }
    
    /// Get tracks by album
    public func getTracksByAlbum(_ album: String) throws -> [LocalMusicTrack] {
        let sql = "SELECT * FROM tracks WHERE album = ? ORDER BY track_number;"
        return try queryTracks(sql, bindings: [album])
    }
    
    /// Search tracks by title, artist, or album
    public func searchTracks(_ query: String) throws -> [LocalMusicTrack] {
        let sql = """
        SELECT * FROM tracks
        WHERE title LIKE ? OR artist LIKE ? OR album LIKE ?
        ORDER BY artist, album, track_number;
        """
        let searchQuery = "%\(query)%"
        return try queryTracks(sql, bindings: [searchQuery, searchQuery, searchQuery])
    }
    
    /// Get a single track by ID
    public func getTrack(byId id: String) throws -> LocalMusicTrack? {
        let sql = "SELECT * FROM tracks WHERE id = ?;"
        let results = try queryTracks(sql, bindings: [id])
        return results.first
    }
    
    /// Delete a track by ID
    public func deleteTrack(byId id: String) throws {
        let sql = "DELETE FROM tracks WHERE id = ?;"
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.failedToDelete(String(cString: sqlite3_errmsg(db)))
        }
        
        sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            let error = String(cString: sqlite3_errmsg(db))
            sqlite3_finalize(statement)
            throw DatabaseError.failedToDelete(error)
        }
        
        sqlite3_finalize(statement)
    }
    
    /// Get total track count
    public func getTrackCount() throws -> Int {
        let sql = "SELECT COUNT(*) FROM tracks;"
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.failedToQuery(String(cString: sqlite3_errmsg(db)))
        }
        
        var count = 0
        if sqlite3_step(statement) == SQLITE_ROW {
            count = Int(sqlite3_column_int(statement, 0))
        }
        
        sqlite3_finalize(statement)
        return count
    }
    
    /// Get all unique artists
    public func getAllArtists() throws -> [String] {
        let sql = "SELECT DISTINCT artist FROM tracks ORDER BY artist;"
        var artists: [String] = []
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.failedToQuery(String(cString: sqlite3_errmsg(db)))
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let artist = sqlite3_column_text(statement, 0) {
                artists.append(String(cString: artist))
            }
        }
        
        sqlite3_finalize(statement)
        return artists
    }
    
    /// Get all unique albums
    public func getAllAlbums() throws -> [(artist: String, album: String)] {
        let sql = "SELECT DISTINCT artist, album FROM tracks ORDER BY artist, album;"
        var albums: [(String, String)] = []
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.failedToQuery(String(cString: sqlite3_errmsg(db)))
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let artist = sqlite3_column_text(statement, 0),
               let album = sqlite3_column_text(statement, 1) {
                albums.append((String(cString: artist), String(cString: album)))
            }
        }
        
        sqlite3_finalize(statement)
        return albums
    }
    
    /// Delete all tracks from the database
    public func deleteAllTracks() throws {
        let sql = "DELETE FROM tracks;"
        try executeSQL(sql)
    }
    
    // MARK: - Private Helpers
    
    private func queryTracks(_ sql: String, bindings: [String] = []) throws -> [LocalMusicTrack] {
        var tracks: [LocalMusicTrack] = []
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.failedToQuery(String(cString: sqlite3_errmsg(db)))
        }
        
        // Bind parameters
        for (index, binding) in bindings.enumerated() {
            sqlite3_bind_text(statement, Int32(index + 1), (binding as NSString).utf8String, -1, nil)
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let track = parseTrackFromStatement(statement) else {
                continue
            }
            tracks.append(track)
        }
        
        sqlite3_finalize(statement)
        return tracks
    }
    
    private func parseTrackFromStatement(_ statement: OpaquePointer?) -> LocalMusicTrack? {
        guard let statement = statement else { return nil }
        
        guard let idText = sqlite3_column_text(statement, 0),
              let titleText = sqlite3_column_text(statement, 1),
              let artistText = sqlite3_column_text(statement, 2),
              let albumText = sqlite3_column_text(statement, 3),
              let filePathText = sqlite3_column_text(statement, 5) else {
            return nil
        }
        
        let id = String(cString: idText)
        let title = String(cString: titleText)
        let artist = String(cString: artistText)
        let album = String(cString: albumText)
        let duration = sqlite3_column_double(statement, 4)
        let filePath = String(cString: filePathText)
        let fileSize = sqlite3_column_int64(statement, 6)
        
        let artworkPath: String? = {
            if let text = sqlite3_column_text(statement, 7) {
                return String(cString: text)
            }
            return nil
        }()
        
        let trackNumber: Int? = {
            let value = sqlite3_column_int(statement, 8)
            return sqlite3_column_type(statement, 8) == SQLITE_NULL ? nil : Int(value)
        }()
        
        let genre: String? = {
            if let text = sqlite3_column_text(statement, 9) {
                return String(cString: text)
            }
            return nil
        }()
        
        let releaseYear: Int? = {
            let value = sqlite3_column_int(statement, 10)
            return sqlite3_column_type(statement, 10) == SQLITE_NULL ? nil : Int(value)
        }()
        
        let bitrate: Int? = {
            let value = sqlite3_column_int(statement, 11)
            return sqlite3_column_type(statement, 11) == SQLITE_NULL ? nil : Int(value)
        }()
        
        let sampleRate: Int? = {
            let value = sqlite3_column_int(statement, 12)
            return sqlite3_column_type(statement, 12) == SQLITE_NULL ? nil : Int(value)
        }()
        
        let addedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 13))
        let lastModified = Date(timeIntervalSince1970: sqlite3_column_double(statement, 14))
        
        return LocalMusicTrack(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            fileSize: fileSize,
            artworkPath: artworkPath,
            trackNumber: trackNumber,
            genre: genre,
            releaseYear: releaseYear,
            bitrate: bitrate,
            sampleRate: sampleRate,
            addedAt: addedAt,
            lastModified: lastModified
        )
    }
    
    deinit {
        closeDatabase()
    }
}
