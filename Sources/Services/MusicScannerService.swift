import Foundation
import AVFoundation

/// Service for scanning and importing local music files
public class MusicScannerService {
    private let databaseService: MusicDatabaseService
    private let fileManager = FileManager.default
    
    public enum ScanError: Error {
        case invalidDirectory
        case accessDenied
        case scanFailed(String)
    }
    
    public struct ScanProgress {
        public let filesScanned: Int
        public let filesImported: Int
        public let currentFile: String?
        public let errors: [String]
    }
    
    public init(databaseService: MusicDatabaseService) {
        self.databaseService = databaseService
    }
    
    /// Scan the default Apple Music directory
    public func scanAppleMusicLibrary(progressHandler: ((ScanProgress) -> Void)? = nil) async throws -> ScanProgress {
        #if os(tvOS)
        // tvOS doesn't have access to local music directories
        throw ScanError.scanFailed("Music library scanning is not available on Apple TV. This feature requires access to local music files which are only available on Mac, iPhone, and iPad.")
        #else
        let homeDirectory: URL
        if #available(iOS 16.0, macOS 13.0, *) {
            homeDirectory = URL.homeDirectory
        } else {
            homeDirectory = fileManager.homeDirectoryForCurrentUser
        }
        
        let musicPath = homeDirectory
            .appendingPathComponent("Music/Music/Media.localized/Apple Music")
        
        // Check if directory exists before scanning
        guard fileManager.fileExists(atPath: musicPath.path) else {
            throw ScanError.scanFailed("Apple Music folder not found at: \(musicPath.path)\n\nPlease ensure you have downloaded songs from Apple Music, or use 'Choose Custom Folder' to select a different location.")
        }
        
        return try await scanDirectory(at: musicPath.path, progressHandler: progressHandler)
        #endif
    }
    
    /// Scan bundled music resources in the app
    public func scanBundledMusic(progressHandler: ((ScanProgress) -> Void)? = nil) async throws -> ScanProgress {
        // Try multiple possible locations for bundled music
        var musicPath: String?
        var foundFiles: [URL] = []
        
        // Method 1: Direct bundle resource lookup
        if let bundlePath = Bundle.main.path(forResource: "Music", ofType: nil) {
            musicPath = bundlePath
            print("📁 Found Music folder at bundle path: \(bundlePath)")
        }
        
        // Method 2: Resource path + Music
        if musicPath == nil, let resourcePath = Bundle.main.resourcePath {
            let testPath = (resourcePath as NSString).appendingPathComponent("Music")
            if fileManager.fileExists(atPath: testPath) {
                musicPath = testPath
                print("📁 Found Music folder at: \(testPath)")
            }
        }
        
        // Method 3: Search for individual music files in bundle
        if musicPath == nil {
            print("🔍 Searching for individual music files in bundle...")
            let extensions = ["m4p", "m4a", "mp3", "aac", "wav", "flac"]
            
            for ext in extensions {
                if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                    foundFiles.append(contentsOf: urls)
                }
            }
            
            if !foundFiles.isEmpty {
                print("✅ Found \(foundFiles.count) music files directly in bundle")
                // Import these files directly
                return try await importBundledFiles(foundFiles, progressHandler: progressHandler)
            }
        }
        
        // If we found a Music folder, scan it
        if let path = musicPath {
            return try await scanDirectory(at: path, progressHandler: progressHandler)
        }
        
        // No music found
        throw ScanError.scanFailed("No bundled music found.\n\nChecklist:\n1. Add music files to Resources/Music in Xcode\n2. Ensure files are added to target membership\n3. Check Build Phases → Copy Bundle Resources\n\nFound 0 music files in app bundle.")
    }
    
    /// Import individual bundled files
    private func importBundledFiles(_ urls: [URL], progressHandler: ((ScanProgress) -> Void)? = nil) async throws -> ScanProgress {
        var filesScanned = 0
        var filesImported = 0
        var errors: [String] = []
        
        for url in urls {
            filesScanned += 1
            
            let progress = ScanProgress(
                filesScanned: filesScanned,
                filesImported: filesImported,
                currentFile: url.lastPathComponent,
                errors: errors
            )
            progressHandler?(progress)
            
            do {
                try await importTrack(from: url)
                filesImported += 1
            } catch {
                errors.append("Failed to import \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return ScanProgress(
            filesScanned: filesScanned,
            filesImported: filesImported,
            currentFile: nil,
            errors: errors
        )
    }
    
    /// Scan a specific directory for music files
    public func scanDirectory(at path: String, progressHandler: ((ScanProgress) -> Void)? = nil) async throws -> ScanProgress {
        guard fileManager.fileExists(atPath: path) else {
            throw ScanError.invalidDirectory
        }
        
        var filesScanned = 0
        var filesImported = 0
        var errors: [String] = []
        
        let supportedExtensions = ["m4a", "m4p", "mp3", "aac", "wav", "flac", "alac"]
        
        // Get all music files recursively
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw ScanError.scanFailed("Failed to enumerate directory")
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            guard supportedExtensions.contains(fileExtension) else {
                continue
            }
            
            filesScanned += 1
            
            // Report progress
            let progress = ScanProgress(
                filesScanned: filesScanned,
                filesImported: filesImported,
                currentFile: fileURL.lastPathComponent,
                errors: errors
            )
            progressHandler?(progress)
            
            // Import the track
            do {
                try await importTrack(from: fileURL)
                filesImported += 1
            } catch {
                errors.append("Failed to import \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return ScanProgress(
            filesScanned: filesScanned,
            filesImported: filesImported,
            currentFile: nil,
            errors: errors
        )
    }
    
    /// Import a single track from a file URL
    private func importTrack(from url: URL) async throws {
        let asset = AVURLAsset(url: url)
        
        // Extract metadata
        let metadata = try await asset.load(.metadata)
        
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var album = "Unknown Album"
        var trackNumber: Int?
        var genre: String?
        var releaseYear: Int?
        
        // Parse metadata
        for item in metadata {
            guard let key = item.commonKey?.rawValue,
                  let value = try await item.load(.value) else {
                continue
            }
            
            switch key {
            case "title":
                if let stringValue = value as? String {
                    title = stringValue
                }
            case "artist":
                if let stringValue = value as? String {
                    artist = stringValue
                }
            case "albumName":
                if let stringValue = value as? String {
                    album = stringValue
                }
            case "type":
                if let stringValue = value as? String {
                    genre = stringValue
                }
            default:
                break
            }
        }
        
        // Get duration
        let duration = try await asset.load(.duration)
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        // Get file size
        let fileSize = try fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
        
        // Extract track number from filename if present
        let filename = url.deletingPathExtension().lastPathComponent
        if let firstComponent = filename.components(separatedBy: " ").first,
           let number = Int(firstComponent.replacingOccurrences(of: "-", with: "")) {
            trackNumber = number
        }
        
        // Create LocalMusicTrack
        let track = LocalMusicTrack(
            title: title,
            artist: artist,
            album: album,
            duration: durationInSeconds,
            filePath: url.path,
            fileSize: fileSize,
            trackNumber: trackNumber,
            genre: genre,
            releaseYear: releaseYear
        )
        
        // Insert into database
        try databaseService.insertTrack(track)
    }
    
    /// Import a single file
    public func importFile(at path: String) async throws {
        let url = URL(fileURLWithPath: path)
        try await importTrack(from: url)
    }
    
    /// Remove tracks that no longer exist on disk
    public func cleanupMissingTracks() async throws -> Int {
        let allTracks = try databaseService.getAllTracks()
        var removedCount = 0
        
        for track in allTracks {
            if !fileManager.fileExists(atPath: track.filePath) {
                try databaseService.deleteTrack(byId: track.id)
                removedCount += 1
            }
        }
        
        return removedCount
    }
}
