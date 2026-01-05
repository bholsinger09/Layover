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
        // 90s Pop style songs
        SampleSong(
            title: "Summer Nights",
            artist: "Pop Collective",
            genre: .nineties,
            duration: "3:45",
            colors: [.pink, .purple],
            audioURL: URL(string: "https://ia804605.us.archive.org/18/items/freemusicarchive_201904/The_Kyoto_Connection_-_04_-_Wake_Up.mp3")
        ),
        SampleSong(
            title: "Dancing Dreams",
            artist: "The Melody Makers",
            genre: .nineties,
            duration: "4:12",
            colors: [.blue, .cyan],
            audioURL: URL(string: "https://ia804605.us.archive.org/18/items/freemusicarchive_201904/Broke_For_Free_-_01_-_Night_Owl.mp3")
        ),
        SampleSong(
            title: "Forever Young",
            artist: "Rhythm Nation",
            genre: .nineties,
            duration: "3:58",
            colors: [.orange, .red],
            audioURL: URL(string: "https://ia804605.us.archive.org/18/items/freemusicarchive_201904/Ketsa_-_02_-_Lets_Feel_Good_Today.mp3")
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
            colors: [.purple, .blue],
            audioURL: URL(string: "https://ia804605.us.archive.org/18/items/freemusicarchive_201904/Tobin_Sprout_-_01_-_High_Flying_Cloud_Structures.mp3")
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
