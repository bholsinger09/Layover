import Foundation
import Observation
import AVFoundation

/// ViewModel for music player
@MainActor
@Observable
public final class MusicPlayerViewModel {
    public private(set) var songs: [SampleSong] = SampleSong.samples
    public private(set) var currentSong: SampleSong?
    public private(set) var isPlaying = false
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    private var currentIndex = 0
    private let spotifyService = SpotifyService()
    nonisolated(unsafe) private var audioPlayer: AVPlayer?
    
    public init() {
        setupAudioSession()
    }
    
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
    
    deinit {
        audioPlayer?.pause()
        audioPlayer = nil
    }
    
    public func clearError() {
        errorMessage = nil
    }
    
    public func playSong(_ song: SampleSong) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
            return
        }
        
        currentIndex = index
        currentSong = song
        
        // Play audio if URL exists
        if let audioURL = song.audioURL {
            print("🎵 Attempting to play: \(song.title) from \(audioURL)")
            
            audioPlayer?.pause()
            audioPlayer = nil
            
            let player = AVPlayer(url: audioURL)
            audioPlayer = player
            
            // Monitor player status
            Task {
                await monitorPlayerStatus(player)
            }
            
            player.play()
            isPlaying = true
            
            print("✅ Player created and play() called")
        } else {
            isPlaying = true
            print("⚠️ No audio URL for: \(song.title) by \(song.artist)")
        }
    }
    
    private func monitorPlayerStatus(_ player: AVPlayer) async {
        // Wait a bit for the player to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        switch player.status {
        case .readyToPlay:
            print("✅ Player ready to play")
        case .failed:
            let error = player.error?.localizedDescription ?? "unknown error"
            print("❌ Player failed: \(error)")
            await MainActor.run {
                errorMessage = "Playback failed: \(error)"
            }
        case .unknown:
            print("⏳ Player status unknown")
        @unknown default:
            break
        }
    }
    
    public func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            print("⏸️ Paused")
        } else {
            audioPlayer?.play()
            isPlaying = true
            print("▶️ Playing")
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
    // MARK: - URL Playback
    
    public func playFromURL(_ urlString: String) async {
        errorMessage = nil
        isLoading = true
        
        print("🌐 Playing from URL: \(urlString)")
        
        // Check if it's a Spotify URL
        if urlString.contains("spotify.com") {
            await loadSpotifyPlaylist(urlString)
        }
        // Check if it's a YouTube URL
        else if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
            loadYouTubeURL(urlString)
        }
        // Try as direct audio URL
        else {
            loadDirectAudioURL(urlString)
        }
        
        isLoading = false
    }
    
    private func loadSpotifyPlaylist(_ url: String) async {
        do {
            let playlistSongs = try await spotifyService.fetchPlaylist(url: url)
            songs = playlistSongs
            
            if let firstSong = songs.first {
                playSong(firstSong)
            }
            
            print("✅ Loaded \(songs.count) songs from Spotify")
        } catch {
            errorMessage = "Failed to load Spotify playlist: \(error.localizedDescription)"
            print("❌ Spotify error: \(error)")
        }
    }
    
    private func loadYouTubeURL(_ url: String) {
        // For YouTube URLs, we'll create a placeholder song
        // Note: Direct YouTube playback requires additional implementation
        print("📺 YouTube URL detected: \(url)")
        print("ℹ️ YouTube playback requires browser/webview - adding to playlist")
        
        let youtubeSong = SampleSong(
            title: "YouTube Video",
            artist: "From URL",
            genre: .all,
            duration: "--:--",
            colors: [.red, .pink]
        )
        
        songs.insert(youtubeSong, at: 0)
        playSong(youtubeSong)
        
        // TODO: Open YouTube URL in web view or system browser
        errorMessage = "YouTube playback will open in browser"
    }
    
    private func loadDirectAudioURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        print("🎵 Loading direct audio URL: \(url)")
        
        let audioSong = SampleSong(
            title: url.lastPathComponent,
            artist: "From URL",
            genre: .all,
            duration: "--:--",
            colors: [.blue, .purple],
            audioURL: url
        )
        
        songs.insert(audioSong, at: 0)
        playSong(audioSong)
        
        print("✅ Playing audio from URL")
    }}
