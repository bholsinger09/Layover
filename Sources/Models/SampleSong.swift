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
        // Bundled Music
        SampleSong(
            title: "Ob-La-Di, Ob-La-Da",
            artist: "The Beatles",
            genre: .classic,
            duration: "3:20",
            colors: [.yellow, .orange],
            audioURL: Bundle.main.url(forResource: "Ob-La-Di-Ob-La-Da", withExtension: "mp3", subdirectory: "Music")
        )
    ]
}
