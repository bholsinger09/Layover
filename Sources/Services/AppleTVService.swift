import AVFoundation
import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

/// Service for managing Apple TV+ playback
@MainActor
public protocol AppleTVServiceProtocol: LayoverService {
    var currentContent: MediaContent? { get }
    var player: AVPlayer? { get }

    func loadContent(_ content: MediaContent) async throws
    func openInTVApp(_ content: MediaContent) async throws
    func play() async
    func pause() async
    func seek(to time: TimeInterval) async
}

@MainActor
public final class AppleTVService: AppleTVServiceProtocol {
    public private(set) var currentContent: MediaContent?
    public private(set) var player: AVPlayer?

    public init() {}

    /// Open content in the Apple TV app with SharePlay support
    public func openInTVApp(_ content: MediaContent) async throws {
        #if canImport(UIKit)
            // Construct Apple TV+ deep link URL
            // Format: https://tv.apple.com/show/umc.cmc.SHOW_ID or /movie/umc.cmc.MOVIE_ID
            let baseURL = "https://tv.apple.com"
            let contentPath = content.contentType == .movie ? "movie" : "show"
            let urlString = "\(baseURL)/\(contentPath)/\(content.contentID)"

            guard let url = URL(string: urlString) else {
                throw MediaError.invalidURL
            }

            // Open in TV app - this will work with SharePlay automatically
            if await UIApplication.shared.canOpenURL(url) {
                await UIApplication.shared.open(url, options: [:])
                currentContent = content
            } else {
                throw MediaError.tvAppNotAvailable
            }
        #elseif canImport(AppKit)
            // On macOS, open TV app with deep link
            let baseURL = "https://tv.apple.com"
            let contentPath = content.contentType == .movie ? "movie" : "show"
            let urlString = "\(baseURL)/\(contentPath)/\(content.contentID)"

            guard let url = URL(string: urlString) else {
                throw MediaError.invalidURL
            }

            // Open URL - macOS will open it in the TV app
            NSWorkspace.shared.open(url)
            currentContent = content
        #else
            throw MediaError.tvAppNotAvailable
        #endif
    }

    public func loadContent(_ content: MediaContent) async throws {
        // This method is for potential future in-app playback
        // For now, we use openInTVApp for all Apple TV+ content
        try await openInTVApp(content)
    }

    public func play() async {
        player?.play()
    }

    public func pause() async {
        player?.pause()
    }

    public func seek(to time: TimeInterval) async {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        await player?.seek(to: cmTime)
    }
}

public enum MediaError: LocalizedError {
    case invalidURL
    case loadFailed
    case tvAppNotAvailable

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid media URL"
        case .loadFailed:
            return "Failed to load media content"
        case .tvAppNotAvailable:
            return "Apple TV app is not available"
        }
    }
}
