import Foundation

/// Media content being played in Apple TV+ rooms
public struct MediaContent: LayoverModel {
    public let id: UUID
    public var title: String
    public var contentID: String
    public var streamURL: URL?
    public var artworkURL: URL?
    public var duration: TimeInterval
    public var contentType: ContentType
    
    public enum ContentType: String, Codable, Sendable {
        case movie
        case tvShow
        case song
        case album
        case playlist
    }
    
    // Legacy support
    public var mediaType: ContentType { contentType }
    
    public init(
        id: UUID = UUID(),
        title: String,
        contentID: String,
        streamURL: URL? = nil,
        artworkURL: URL? = nil,
        duration: TimeInterval = 0,
        contentType: ContentType
    ) {
        self.id = id
        self.title = title
        self.contentID = contentID
        self.streamURL = streamURL
        self.artworkURL = artworkURL
        self.duration = duration
        self.contentType = contentType
    }
}
