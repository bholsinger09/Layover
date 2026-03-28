import Foundation
import Observation
import AVFoundation

/// ViewModel for music player
@MainActor
@Observable
public final class MusicPlayerViewModel {
    public private(set) var songs: [SampleSong] = []
    public private(set) var currentSong: SampleSong?
    public private(set) var isPlaying = false
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public private(set) var currentTime: Double = 0.0
    public private(set) var duration: Double = 0.0
    private var currentIndex = 0
    private let databaseService = MusicDatabaseService()
    nonisolated(unsafe) private var audioPlayer: AVPlayer?
    nonisolated(unsafe) private var timeObserver: Any?
    
    public init() {
        #if os(iOS) || os(tvOS)
        setupAudioSession()
        #endif
        Task {
            await loadSongsFromDatabase()
        }
    }
    
    #if os(iOS) || os(tvOS)
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
        }
    }
    #endif
    
    deinit {
        if let observer = timeObserver {
            audioPlayer?.removeTimeObserver(observer)
        }
        audioPlayer?.pause()
        audioPlayer = nil
    }
    
    public func clearError() {
        errorMessage = nil
    }
    
    public func playSong(_ song: SampleSong) {
        // Try to find the song in the library
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            currentIndex = index
            currentSong = song
        } else {
            // Song not in library, add it temporarily and play it
            print("⚠️ Song not in library, playing directly: \(song.title)")
            currentSong = song
            currentIndex = -1 // Indicate this is not part of the main library
        }
        
        // Play audio if URL exists
        if let audioURL = song.audioURL {
            print("🎵 Attempting to play: \(song.title) from \(audioURL)")
            
            // Check if file exists and is accessible before attempting to play
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: audioURL.path) {
                print("❌ Audio file does not exist at path: \(audioURL.path)")
                errorMessage = "Audio file not found. Please re-import this song."
                isPlaying = false
                return
            }
            
            // Check if file is readable
            if !fileManager.isReadableFile(atPath: audioURL.path) {
                print("❌ Audio file is not readable at path: \(audioURL.path)")
                errorMessage = "Cannot access audio file. Please check permissions or re-import this song."
                isPlaying = false
                return
            }
            
            // Clean up existing observer first
            if let observer = timeObserver, let oldPlayer = audioPlayer {
                oldPlayer.removeTimeObserver(observer)
                timeObserver = nil
            }
            
            // Stop and clean up previous player
            audioPlayer?.pause()
            audioPlayer = nil
            
            // Create player item and player
            let playerItem = AVPlayerItem(url: audioURL)
            let player = AVPlayer(playerItem: playerItem)
            audioPlayer = player
            
            // Set volume to ensure it's audible
            player.volume = 1.0
            
            // Monitor player status and load asynchronously
            Task {
                await loadAndPlayAudio(player: player, item: playerItem, song: song)
            }
        } else {
            isPlaying = true
            print("⚠️ No audio URL for: \(song.title) by \(song.artist)")
            errorMessage = "This song has no audio file. Please import music to play."
        }
    }
    
    private func setupTimeObserver(for player: AVPlayer) {
        // Add periodic time observer (updates every 0.5 seconds)
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = time.seconds
            if seconds.isFinite {
                self.currentTime = seconds
            }
        }
    }
    
    private func loadAndPlayAudio(player: AVPlayer, item: AVPlayerItem, song: SampleSong) async {
        print("⏳ Loading audio for: \(song.title)...")
        
        // Wait for the item to be ready to play
        var attempts = 0
        let maxAttempts = 30 // 3 seconds total (30 * 100ms)
        
        while attempts < maxAttempts {
            let status = item.status
            
            switch status {
            case .readyToPlay:
                print("✅ Player item ready to play")
                let durationSeconds = item.duration.seconds
                print("📊 Duration: \(durationSeconds) seconds")
                
                // Update duration and setup time observer
                await MainActor.run {
                    self.duration = durationSeconds.isFinite ? durationSeconds : 0.0
                    self.currentTime = 0.0
                    self.setupTimeObserver(for: player)
                    
                    // Now play the audio
                    player.play()
                    isPlaying = true
                    print("▶️ Playback started for: \(song.title)")
                }
                
                // Monitor playback
                try? await Task.sleep(nanoseconds: 500_000_000)
                let rate = player.rate
                let currentTime = player.currentTime().seconds
                print("📊 Playback status - Rate: \(rate), Current time: \(currentTime)s")
                
                if rate > 0 {
                    print("✅ Audio is playing successfully")
                } else {
                    print("⚠️ Player rate is 0 - audio may not be playing")
                }
                return
                
            case .failed:
                let error = item.error?.localizedDescription ?? "unknown error"
                print("❌ Player item failed to load: \(error)")
                if let error = item.error {
                    print("❌ Error details: \(error)")
                    
                    // Check for common error codes
                    let nsError = error as NSError
                    if nsError.domain == "AVFoundationErrorDomain" {
                        if nsError.code == -11800 {
                            // General playback error - likely file access issue
                            await MainActor.run {
                                errorMessage = "Cannot play this audio file. It may have been moved or deleted. Try re-importing the song."
                                isPlaying = false
                            }
                            return
                        }
                    }
                }
                await MainActor.run {
                    errorMessage = "Failed to load audio. The file may be inaccessible or corrupted. Try re-importing the song."
                    isPlaying = false
                }
                return
                
            case .unknown:
                // Still loading, wait a bit
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                attempts += 1
                if attempts % 10 == 0 {
                    print("⏳ Still loading... (\(attempts * 100)ms elapsed)")
                }
                
            @unknown default:
                break
            }
        }
        
        // Timeout
        print("⏱️ Timeout waiting for player to be ready")
        await MainActor.run {
            errorMessage = "Audio loading timed out"
            isPlaying = false
        }
    }
    
    public func togglePlayPause() {
        guard let player = audioPlayer else {
            print("⚠️ No player available")
            return
        }
        
        if isPlaying {
            player.pause()
            isPlaying = false
            print("⏸️ Paused at \(currentTime)s")
        } else {
            player.play()
            isPlaying = true
            print("▶️ Resumed from \(currentTime)s")
        }
    }
    
    public func playNext() {
        guard !songs.isEmpty else { return }
        
        currentIndex = (currentIndex + 1) % songs.count
        let nextSong = songs[currentIndex]
        print("⏭️ Next: \(nextSong.title)")
        playSong(nextSong)
    }
    
    public func playPrevious() {
        guard !songs.isEmpty else { return }
        
        currentIndex = currentIndex > 0 ? currentIndex - 1 : songs.count - 1
        let previousSong = songs[currentIndex]
        print("⏮️ Previous: \(previousSong.title)")
        playSong(previousSong)
    }
    
    // MARK: - Database Integration
    
    private func loadSongsFromDatabase() async {
        do {
            try databaseService.openDatabase()
            let tracks = try databaseService.getAllTracks()
            
            // Convert LocalMusicTrack to SampleSong, filtering out inaccessible files
            let fileManager = FileManager.default
            var validSongs: [SampleSong] = []
            var invalidCount = 0
            
            for track in tracks {
                let fileURL = URL(fileURLWithPath: track.filePath)
                
                // Check if file exists and is readable
                if fileManager.fileExists(atPath: track.filePath) && 
                   fileManager.isReadableFile(atPath: track.filePath) {
                    validSongs.append(SampleSong(
                        title: track.title,
                        artist: track.artist,
                        genre: .all,
                        duration: track.formattedDuration,
                        colors: [.blue, .purple],
                        audioURL: fileURL
                    ))
                } else {
                    print("⚠️ Skipping inaccessible file: \(track.title) at \(track.filePath)")
                    invalidCount += 1
                }
            }
            
            songs = validSongs
            
            if invalidCount > 0 {
                print("⚠️ \(invalidCount) track(s) skipped due to inaccessible files")
                print("✅ Loaded \(songs.count) valid songs from database")
                
                // Show a friendly message if we have some invalid files
                if songs.isEmpty && tracks.count > 0 {
                    errorMessage = "No accessible music files found. Please import music to get started."
                } else if invalidCount > 0 {
                    errorMessage = "\(invalidCount) song(s) could not be loaded. They may have been moved or deleted."
                }
            } else {
                print("✅ Loaded \(songs.count) songs from database")
            }
        } catch {
            print("❌ Failed to load songs from database: \(error)")
            errorMessage = "Failed to load music library. Please import music to get started."
        }
    }
    
    public func refreshLibrary() async {
        await loadSongsFromDatabase()
    }
    
    // MARK: - URL Playback (Deprecated - using database instead)
    
    public func playFromURL(_ urlString: String) async {
        errorMessage = "URL playback is no longer supported. Please import songs to your local library first."
        isLoading = false
    }
}
