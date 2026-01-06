import Foundation
import Observation

public enum MusicBrowseSection: String, CaseIterable {
    case recentlyPlayed = "Recently Played"
    case recommendations = "For You"
    case playlists = "Playlists"
    case songs = "Songs"
    case albums = "Albums"
}

/// ViewModel for Apple Music listening rooms
@MainActor
@Observable
public final class AppleMusicViewModel: LayoverViewModel {
    private let musicService: AppleMusicServiceProtocol

    public private(set) var currentContent: MediaContent?
    public private(set) var isPlaying = false
    public private(set) var isAuthorized = false
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    
    // Library content
    public private(set) var recentlyPlayed: [MediaContent] = []
    public private(set) var recommendations: [MediaContent] = []
    public private(set) var playlists: [MediaContent] = []
    public private(set) var songs: [MediaContent] = []
    public private(set) var albums: [MediaContent] = []
    public private(set) var searchResults: [MediaContent] = []
    
    // UI state
    public var searchQuery = ""
    public var selectedSection: MusicBrowseSection = .recentlyPlayed

    nonisolated init(musicService: AppleMusicServiceProtocol) {
        self.musicService = musicService
        Task { @MainActor in
            self.isAuthorized = await musicService.isAuthorized
            self.setupStateObservers()
        }
    }
    
    private func setupStateObservers() {
        if let service = musicService as? AppleMusicService {
            service.onPlaybackStateChanged = { [weak self] isPlaying in
                Task { @MainActor in
                    self?.isPlaying = isPlaying
                }
            }
            
            service.onCurrentEntryChanged = { [weak self] content in
                Task { @MainActor in
                    if let content = content {
                        self?.currentContent = content
                    }
                }
            }
        }
    }

    public func requestAuthorization() async {
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

    public func loadContent(_ content: MediaContent) async {
        print("🎵 AppleMusicViewModel: Loading content '\(content.title)' (type: \(content.contentType))")
        isLoading = true
        errorMessage = nil

        do {
            currentContent = content
            print("🎵 AppleMusicViewModel: Calling musicService.loadContent()")
            try await musicService.loadContent(content)
            
            // Small delay to ensure queue is fully settled
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            
            // Success - ensure error is cleared
            errorMessage = nil
            print("✅ AppleMusicViewModel: Content loaded successfully")
        } catch let error as MusicError {
            print("❌ AppleMusicViewModel: MusicError - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            print("❌ AppleMusicViewModel: Error - \(error.localizedDescription)")
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }

        isLoading = false
    }

    public func play() async {
        print("▶️ AppleMusicViewModel: play() called")
        errorMessage = nil // Clear any previous errors
        isPlaying = true
        await musicService.play()
        print("▶️ AppleMusicViewModel: play() completed")
    }

    public func pause() async {
        errorMessage = nil // Clear any previous errors
        isPlaying = false
        await musicService.pause()
    }

    public func togglePlayPause() async {
        if isPlaying {
            await pause()
        } else {
            await play()
        }
    }
    
    public func skipToNext() async {
        await musicService.skipToNext()
    }
    
    public func skipToPrevious() async {
        await musicService.skipToPrevious()
    }
    
    // MARK: - Library Browsing
    
    public func loadLibraryContent() async {
        guard isAuthorized else { return }
        
        isLoading = true
        errorMessage = nil
        
        async let recentTask = fetchRecentlyPlayed()
        async let recommendationsTask = fetchRecommendations()
        async let playlistsTask = fetchPlaylists()
        
        _ = await (recentTask, recommendationsTask, playlistsTask)
        
        isLoading = false
    }
    
    public func fetchRecentlyPlayed() async {
        do {
            recentlyPlayed = try await musicService.fetchRecentlyPlayed()
        } catch {
            errorMessage = "Failed to load recently played: \(error.localizedDescription)"
        }
    }
    
    public func fetchRecommendations() async {
        do {
            recommendations = try await musicService.fetchRecommendations()
        } catch {
            errorMessage = "Failed to load recommendations: \(error.localizedDescription)"
        }
    }
    
    public func fetchPlaylists() async {
        do {
            playlists = try await musicService.fetchPlaylists()
        } catch {
            errorMessage = "Failed to load playlists: \(error.localizedDescription)"
        }
    }
    
    public func fetchSongs() async {
        guard songs.isEmpty else { return }
        
        do {
            songs = try await musicService.fetchSongs(limit: 50)
        } catch {
            errorMessage = "Failed to load songs: \(error.localizedDescription)"
        }
    }
    
    public func fetchAlbums() async {
        guard albums.isEmpty else { return }
        
        do {
            albums = try await musicService.fetchAlbums(limit: 50)
        } catch {
            errorMessage = "Failed to load albums: \(error.localizedDescription)"
        }
    }
    
    public func search() async {
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
    
    public func createPlaylist(name: String) async {
        do {
            let playlist = try await musicService.createPlaylist(name: name)
            playlists.insert(playlist, at: 0)
        } catch {
            errorMessage = "Failed to create playlist: \(error.localizedDescription)"
        }
    }
    
    public func clearError() {
        errorMessage = nil
    }
}
