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
    private var audioPlayer: AVPlayer?
    
    public init() {}
    
    public func playSong(_ song: SampleSong) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
            return
        }
        
        currentIndex = index
        currentSong = song
        isPlaying = true
        
        print("🎵 Now playing: \(song.title) by \(song.artist)")
    }
    
    public func togglePlayPause() {
        isPlaying.toggle()
        print(isPlaying ? "▶️ Playing" : "⏸️ Paused")
    }
    
    public func playNext() {
        guard !songs.isEmpty else { return }
        
        currentIndex = (currentIndex + 1) % songs.count
        currentSong = songs[currentIndex]
        isPlaying = true
        
        print("⏭️ Next: \(currentSong?.title ?? "")")
    }
    
    public func playPrevious() {
        guard !songs.isEmpty else { return }
        
        currentIndex = currentIndex > 0 ? currentIndex - 1 : songs.count - 1
        currentSong = songs[currentIndex]
        isPlaying = true
        
        print("⏮️ Previous: \(currentSong?.title ?? "")")
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
        
        // Create AVPlayer for direct audio URLs
        audioPlayer = AVPlayer(url: url)
        
        let audioSong = SampleSong(
            title: url.lastPathComponent,
            artist: "From URL",
            genre: .all,
            duration: "--:--",
            colors: [.blue, .purple]
        )
        
        songs.insert(audioSong, at: 0)
        currentSong = audioSong
        isPlaying = true
        audioPlayer?.play()
        
        print("✅ Playing audio from URL")
    }}
