import Foundation

/// Service for Spotify Web API integration (no user authentication required for public playlists)
@MainActor
public final class SpotifyService {
    private let clientId = "YOUR_SPOTIFY_CLIENT_ID" // Set in app settings
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    
    public init() {}
    
    /// Get client credentials token (doesn't require user login)
    public func getClientToken() async throws {
        // Skip if we have a valid token
        if let token = accessToken, let expiration = tokenExpirationDate, expiration > Date() {
            print("✅ Using existing Spotify token")
            return
        }
        
        print("🔑 Getting Spotify client credentials token...")
        
        // For now, use demo mode without actual API calls
        // TODO: Implement actual Spotify API authentication when client ID is configured
        print("⚠️ Spotify API not configured - using demo mode")
        print("ℹ️ To enable Spotify: Add your Client ID in SpotifyService.swift")
    }
    
    /// Fetch tracks from a Spotify playlist URL
    public func fetchPlaylist(url: String) async throws -> [SampleSong] {
        print("🎵 Fetching Spotify playlist: \(url)")
        
        // Extract playlist ID from URL
        guard let playlistId = extractPlaylistId(from: url) else {
            throw SpotifyError.invalidURL
        }
        
        print("📋 Playlist ID: \(playlistId)")
        
        // TODO: Implement actual API call when credentials are configured
        // For now, return sample songs
        print("⚠️ Demo mode: Returning sample playlist")
        
        return [
            SampleSong(
                title: "Playlist Track 1",
                artist: "Spotify Artist",
                genre: .nineties,
                duration: "3:45",
                colors: [.purple, .pink]
            ),
            SampleSong(
                title: "Playlist Track 2",
                artist: "Spotify Artist",
                genre: .remix,
                duration: "4:12",
                colors: [.blue, .cyan]
            )
        ]
    }
    
    /// Search for tracks on Spotify
    public func search(query: String) async throws -> [SampleSong] {
        print("🔍 Searching Spotify: \(query)")
        
        try await getClientToken()
        
        // TODO: Implement actual API search when credentials are configured
        print("⚠️ Demo mode: Returning sample results")
        
        return [
            SampleSong(
                title: "Search Result: \(query)",
                artist: "Various Artists",
                genre: .nineties,
                duration: "3:30",
                colors: [.orange, .red]
            )
        ]
    }
    
    private func extractPlaylistId(from url: String) -> String? {
        // Extract playlist ID from Spotify URL
        // Format: https://open.spotify.com/playlist/PLAYLIST_ID
        if let range = url.range(of: "playlist/") {
            let startIndex = range.upperBound
            let id = String(url[startIndex...])
            return id.components(separatedBy: "?").first
        }
        return nil
    }
}

public enum SpotifyError: LocalizedError {
    case invalidURL
    case authenticationFailed
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Spotify URL"
        case .authenticationFailed:
            return "Failed to authenticate with Spotify"
        case .apiError(let message):
            return "Spotify API error: \(message)"
        }
    }
}
