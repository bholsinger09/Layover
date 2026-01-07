import Foundation
import Combine

/// ViewModel for managing local music library with SQLite database
@MainActor
public class LocalMusicLibraryViewModel: ObservableObject {
    @Published public var tracks: [LocalMusicTrack] = []
    @Published public var artists: [String] = []
    @Published public var albums: [(artist: String, album: String)] = []
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: MusicScannerService.ScanProgress?
    @Published public var errorMessage: String?
    @Published public var searchQuery: String = ""
    @Published public var filterArtist: String?
    @Published public var filterAlbum: String?
    
    private let databaseService: MusicDatabaseService
    private let scannerService: MusicScannerService
    
    public var filteredTracks: [LocalMusicTrack] {
        var filtered = tracks
        
        if !searchQuery.isEmpty {
            filtered = filtered.filter { track in
                track.title.localizedCaseInsensitiveContains(searchQuery) ||
                track.artist.localizedCaseInsensitiveContains(searchQuery) ||
                track.album.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        if let artist = filterArtist {
            filtered = filtered.filter { $0.artist == artist }
        }
        
        if let album = filterAlbum {
            filtered = filtered.filter { $0.album == album }
        }
        
        return filtered
    }
    
    public var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
    
    public var totalFileSize: Int64 {
        tracks.reduce(0) { $0 + $1.fileSize }
    }
    
    public var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    public var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalFileSize)
    }
    
    public init(databaseService: MusicDatabaseService? = nil) {
        self.databaseService = databaseService ?? MusicDatabaseService()
        self.scannerService = MusicScannerService(databaseService: self.databaseService)
    }
    
    /// Initialize the database
    public func initializeDatabase() async {
        do {
            try databaseService.openDatabase()
            
            // Clear all existing tracks to prevent duplicates
            try databaseService.deleteAllTracks()
            
            await loadTracks()
            await loadMetadata()
        } catch {
            errorMessage = "Failed to initialize database: \(error.localizedDescription)"
        }
    }
    
    /// Load all tracks from database
    public func loadTracks() async {
        do {
            tracks = try databaseService.getAllTracks()
        } catch {
            errorMessage = "Failed to load tracks: \(error.localizedDescription)"
        }
    }
    
    /// Load artists and albums metadata
    public func loadMetadata() async {
        do {
            artists = try databaseService.getAllArtists()
            albums = try databaseService.getAllAlbums()
        } catch {
            errorMessage = "Failed to load metadata: \(error.localizedDescription)"
        }
    }
    
    /// Scan and import music from Apple Music directory
    public func scanAppleMusicLibrary() async {
        isScanning = true
        errorMessage = nil
        
        do {
            let progress = try await scannerService.scanAppleMusicLibrary { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            
            scanProgress = progress
            
            // Reload data after scan
            await loadTracks()
            await loadMetadata()
            
            if progress.errors.isEmpty {
                errorMessage = "Successfully imported \(progress.filesImported) of \(progress.filesScanned) files"
            } else {
                errorMessage = "Imported \(progress.filesImported) of \(progress.filesScanned) files with \(progress.errors.count) errors"
            }
        } catch {
            errorMessage = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    /// Scan bundled music resources
    public func scanBundledMusic() async {
        isScanning = true
        errorMessage = nil
        
        // Debug: Check what's in the bundle
        print("🔍 DEBUG: Checking bundle for music files...")
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Resource path: \(resourcePath)")
        }
        
        // Check for music files
        let extensions = ["m4p", "m4a", "mp3"]
        var totalFound = 0
        for ext in extensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                print("✅ Found \(urls.count) .\(ext) files")
                totalFound += urls.count
                for url in urls.prefix(3) {
                    print("   - \(url.lastPathComponent)")
                }
            }
        }
        print("📊 Total music files in bundle: \(totalFound)")
        
        // If no bundled music found, don't show it as an error on macOS
        if totalFound == 0 {
            print("ℹ️ No bundled music files found - this is expected on macOS")
            #if os(macOS)
            // On macOS, silently skip bundled music scanning
            isScanning = false
            return
            #endif
        }
        
        do {
            let progress = try await scannerService.scanBundledMusic { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            
            scanProgress = progress
            
            // Reload data after scan
            await loadTracks()
            await loadMetadata()
            
            // Only show error messages, not success messages
            if !progress.errors.isEmpty {
                errorMessage = "Imported \(progress.filesImported) of \(progress.filesScanned) files with \(progress.errors.count) errors"
            }
        } catch {
            #if os(macOS)
            // On macOS, don't show bundled music errors
            print("ℹ️ Bundled music not available on macOS: \(error.localizedDescription)")
            #else
            errorMessage = "Scan failed: \(error.localizedDescription)"
            #endif
        }
        
        isScanning = false
    }
    
    /// Scan a custom directory
    public func scanCustomDirectory(at path: String) async {
        isScanning = true
        errorMessage = nil
        
        do {
            let progress = try await scannerService.scanDirectory(at: path) { [weak self] progress in
                Task { @MainActor in
                    self?.scanProgress = progress
                }
            }
            
            scanProgress = progress
            
            // Reload data after scan
            await loadTracks()
            await loadMetadata()
            
            if progress.errors.isEmpty {
                errorMessage = "Successfully imported \(progress.filesImported) of \(progress.filesScanned) files"
            } else {
                errorMessage = "Imported \(progress.filesImported) of \(progress.filesScanned) files with \(progress.errors.count) errors"
            }
        } catch {
            errorMessage = "Scan failed: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    /// Search tracks
    public func search(_ query: String) async {
        searchQuery = query
        
        if query.isEmpty {
            await loadTracks()
        } else {
            do {
                tracks = try databaseService.searchTracks(query)
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Get tracks by artist
    public func filterByArtist(_ artist: String) async {
        do {
            tracks = try databaseService.getTracksByArtist(artist)
            filterArtist = artist
            filterAlbum = nil
        } catch {
            errorMessage = "Filter failed: \(error.localizedDescription)"
        }
    }
    
    /// Get tracks by album
    public func filterByAlbum(_ album: String) async {
        do {
            tracks = try databaseService.getTracksByAlbum(album)
            filterAlbum = album
        } catch {
            errorMessage = "Filter failed: \(error.localizedDescription)"
        }
    }
    
    /// Clear all filters
    public func clearFilters() async {
        filterArtist = nil
        filterAlbum = nil
        searchQuery = ""
        await loadTracks()
    }
    
    /// Delete a track
    public func deleteTrack(_ track: LocalMusicTrack) async {
        do {
            try databaseService.deleteTrack(byId: track.id)
            await loadTracks()
            await loadMetadata()
        } catch {
            errorMessage = "Failed to delete track: \(error.localizedDescription)"
        }
    }
    
    /// Clean up tracks that no longer exist on disk
    public func cleanupMissingTracks() async {
        do {
            let removedCount = try await scannerService.cleanupMissingTracks()
            await loadTracks()
            await loadMetadata()
            errorMessage = "Removed \(removedCount) missing tracks"
        } catch {
            errorMessage = "Cleanup failed: \(error.localizedDescription)"
        }
    }
    
    /// Clear all tracks and rescan bundled music
    public func clearAndRescan() async {
        do {
            try databaseService.deleteAllTracks()
            await scanBundledMusic()
        } catch {
            errorMessage = "Failed to clear database: \(error.localizedDescription)"
        }
    }
    
    /// Get database statistics
    public func getDatabaseStats() async -> (trackCount: Int, artistCount: Int, albumCount: Int) {
        do {
            let trackCount = try databaseService.getTrackCount()
            return (trackCount, artists.count, albums.count)
        } catch {
            return (0, 0, 0)
        }
    }
}
