import Foundation
import Observation

enum MusicBrowseSection: String, CaseIterable {
    case recentlyPlayed = "Recently Played"
    case recommendations = "For You"
    case playlists = "Playlists"
    case songs = "Songs"
    case albums = "Albums"
}

/// ViewModel for Apple Music listening rooms
@MainActor
@Observable
final class AppleMusicViewModel: LayoverViewModel {
    private let musicService: AppleMusicServiceProtocol

    private(set) var currentContent: MediaContent?
    private(set) var isPlaying = false
    private(set) var isAuthorized = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    // Library content
    private(set) var recentlyPlayed: [MediaContent] = []
    private(set) var recommendations: [MediaContent] = []
    private(set) var playlists: [MediaContent] = []
    private(set) var songs: [MediaContent] = []
    private(set) var albums: [MediaContent] = []
    private(set) var searchResults: [MediaContent] = []
    
    // UI state
    var searchQuery = ""
    var selectedSection: MusicBrowseSection = .recentlyPlayed

    nonisolated init(musicService: AppleMusicServiceProtocol) {
        self.musicService = musicService
        Task { @MainActor in
            self.isAuthorized = await musicService.isAuthorized
        }
    }

    func requestAuthorization() async {
        isLoading = true
        errorMessage = nil

        do {
            try await musicService.requestAuthorization()
            isAuthorized = await musicService.isAuthorized
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadContent(_ content: MediaContent) async {
        isLoading = true
        errorMessage = nil

        do {
            try await musicService.loadContent(content)
            currentContent = content
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func play() async {
        await musicService.play()
        isPlaying = true
    }

    func pause() async {
        await musicService.pause()
        isPlaying = false
    }

    func togglePlayPause() async {
        if isPlaying {
            await pause()
        } else {
            await play()
        }
    }
    
    func skipToNext() async {
        await musicService.skipToNext()
    }
    
    func skipToPrevious() async {
        await musicService.skipToPrevious()
    }
    
    // MARK: - Library Browsing
    
    func loadLibraryContent() async {
        guard isAuthorized else { return }
        
        isLoading = true
        errorMessage = nil
        
        async let recentTask = fetchRecentlyPlayed()
        async let recommendationsTask = fetchRecommendations()
        async let playlistsTask = fetchPlaylists()
        
        _ = await (recentTask, recommendationsTask, playlistsTask)
        
        isLoading = false
    }
    
    func fetchRecentlyPlayed() async {
        do {
            recentlyPlayed = try await musicService.fetchRecentlyPlayed()
        } catch {
            errorMessage = "Failed to load recently played: \(error.localizedDescription)"
        }
    }
    
    func fetchRecommendations() async {
        do {
            recommendations = try await musicService.fetchRecommendations()
        } catch {
            errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
        }
    }
    
    func fetchPlaylists() async {
        do {
            playlists = try await musicService.fetchPlaylists()
        } catch {
            errorMessage = "Failed to load playlists: \(error.localizedDescription)"
        }
    }
    
    func fetchSongs() async {
        guard songs.isEmpty else { return }
        
        do {
            songs = try await musicService.fetchSongs(limit: 50)
        } catch {
            errorMessage = "Failed to load songs: \(error.localizedDescription)"
        }
    }
    
    func fetchAlbums() async {
        guard albums.isEmpty else { return }
        
        do {
            albums = try await musicService.fetchAlbums(limit: 50)
        } catch {
            errorMessage = "Failed to load albums: \(error.localizedDescription)"
        }
    }
    
    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        do {
            searchResults = try await musicService.searchMusic(query: searchQuery)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func createPlaylist(name: String) async {
        do {
            let playlist = try await musicService.createPlaylist(name: name)
            playlists.insert(playlist, at: 0)
        } catch {
            errorMessage = "Failed to create playlist: \(error.localizedDescription)"
        }
    }
}
