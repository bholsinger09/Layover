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
    
    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        genre: MusicGenre,
        duration: String,
        colors: [Color]
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genre = genre
        self.duration = duration
        self.colors = colors
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
        // 90s Pop style songs
        SampleSong(
            title: "Summer Nights",
            artist: "Pop Collective",
            genre: .nineties,
            duration: "3:45",
            colors: [.pink, .purple]
        ),
        SampleSong(
            title: "Dancing Dreams",
            artist: "The Melody Makers",
            genre: .nineties,
            duration: "4:12",
            colors: [.blue, .cyan]
        ),
        SampleSong(
            title: "Forever Young",
            artist: "Rhythm Nation",
            genre: .nineties,
            duration: "3:58",
            colors: [.orange, .red]
        ),
        SampleSong(
            title: "Starlight",
            artist: "Pop Icons",
            genre: .nineties,
            duration: "4:03",
            colors: [.yellow, .orange]
        ),
        
        // Remix style songs
        SampleSong(
            title: "Yesterday (EDM Remix)",
            artist: "DJ ModernBeat",
            genre: .remix,
            duration: "3:32",
            colors: [.purple, .blue]
        ),
        SampleSong(
            title: "Come Together (House Mix)",
            artist: "Electronic Legends",
            genre: .remix,
            duration: "4:45",
            colors: [.green, .teal]
        ),
        SampleSong(
            title: "Hey Jude (Chill Remix)",
            artist: "LoFi Masters",
            genre: .remix,
            duration: "5:12",
            colors: [.indigo, .purple]
        ),
        SampleSong(
            title: "Let It Be (Acoustic Remix)",
            artist: "Studio Reimagined",
            genre: .remix,
            duration: "3:48",
            colors: [.brown, .orange]
        ),
        SampleSong(
            title: "Here Comes the Sun (Tropical Mix)",
            artist: "Island Beats",
            genre: .remix,
            duration: "4:01",
            colors: [.yellow, .green]
        ),
        
        // Classic style songs
        SampleSong(
            title: "Timeless Melody",
            artist: "Classic Quartet",
            genre: .classic,
            duration: "4:22",
            colors: [.gray, .blue]
        ),
        SampleSong(
            title: "Harmony Road",
            artist: "The Legends",
            genre: .classic,
            duration: "3:55",
            colors: [.red, .pink]
        ),
        SampleSong(
            title: "Golden Hour",
            artist: "Vintage Collective",
            genre: .classic,
            duration: "4:18",
            colors: [.orange, .yellow]
        )
    ]
}
