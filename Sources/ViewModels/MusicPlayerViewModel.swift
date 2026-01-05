import Foundation
import Observation

/// ViewModel for music player
@MainActor
@Observable
public final class MusicPlayerViewModel {
    public private(set) var songs: [SampleSong] = SampleSong.samples
    public private(set) var currentSong: SampleSong?
    public private(set) var isPlaying = false
    private var currentIndex = 0
    
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
}
