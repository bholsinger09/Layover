import Foundation
import SwiftUI

/// Sample song model for music player demo
public struct SampleSong: Identifiable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let genre: MusicGenre
    public let duration: String
    public let colors: [Color]
    public let audioURL: URL?
    
    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        genre: MusicGenre,
        duration: String,
        colors: [Color],
        audioURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genre = genre
        self.duration = duration
        self.colors = colors
        self.audioURL = audioURL
    }
}

/// Music genres for filtering
public enum MusicGenre: String, CaseIterable {
    case all = "All"
    case nineties = "90s Pop"
    case remix = "Remix"
    case classic = "Classic"
    
    public var displayName: String {
        self.rawValue
    }
}

extension SampleSong {
    /// Sample songs for demonstration
    public static let samples: [SampleSong] = [
        // 90s Pop Songs
        SampleSong(
            title: "Wannabe",
            artist: "Spice Girls",
            genre: .nineties,
            duration: "2:52",
            colors: [.pink, .purple],
            audioURL: Bundle.main.url(forResource: "Wannabe", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "What's Up?",
            artist: "4 Non Blondes",
            genre: .nineties,
            duration: "3:33",
            colors: [.cyan, .blue],
            audioURL: Bundle.main.url(forResource: "Whats-Up", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "No Scrubs",
            artist: "TLC",
            genre: .nineties,
            duration: "3:27",
            colors: [.red, .pink],
            audioURL: Bundle.main.url(forResource: "No-Scrubs", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "Creep",
            artist: "Radiohead",
            genre: .nineties,
            duration: "3:56",
            colors: [.green, .blue],
            audioURL: Bundle.main.url(forResource: "Creep", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "Bitter Sweet Symphony",
            artist: "The Verve",
            genre: .nineties,
            duration: "3:34",
            colors: [.purple, .pink],
            audioURL: Bundle.main.url(forResource: "Bitter-Sweet-Symphony", withExtension: "mp3", subdirectory: "Music")
        ),
        
        // Remix Songs
        SampleSong(
            title: "Levitating (The Blessed Madonna Remix)",
            artist: "Dua Lipa & Missy Elliott",
            genre: .remix,
            duration: "3:23",
            colors: [.orange, .yellow],
            audioURL: Bundle.main.url(forResource: "Levitating-Remix", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "Blinding Lights (PNAU Remix)",
            artist: "The Weeknd",
            genre: .remix,
            duration: "3:25",
            colors: [.red, .orange],
            audioURL: Bundle.main.url(forResource: "Blinding-Lights-Remix", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "One Dance (Remix)",
            artist: "Drake ft. Wizkid & Kyla",
            genre: .remix,
            duration: "2:54",
            colors: [.blue, .cyan],
            audioURL: Bundle.main.url(forResource: "One-Dance-Remix", withExtension: "mp3", subdirectory: "Music")
        ),
        
        // Classic Songs
        SampleSong(
            title: "Ob-La-Di, Ob-La-Da",
            artist: "The Beatles",
            genre: .classic,
            duration: "3:20",
            colors: [.yellow, .orange],
            audioURL: Bundle.main.url(forResource: "Ob-La-Di-Ob-La-Da", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "Hey Jude",
            artist: "The Beatles",
            genre: .classic,
            duration: "7:11",
            colors: [.yellow, .red],
            audioURL: Bundle.main.url(forResource: "Hey-Jude", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "Imagine",
            artist: "John Lennon",
            genre: .classic,
            duration: "3:03",
            colors: [.blue, .white],
            audioURL: Bundle.main.url(forResource: "Imagine", withExtension: "mp3", subdirectory: "Music")
        ),
        SampleSong(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            genre: .classic,
            duration: "5:55",
            colors: [.black, .red],
            audioURL: Bundle.main.url(forResource: "Bohemian-Rhapsody", withExtension: "mp3", subdirectory: "Music")
        )
    ]
}
