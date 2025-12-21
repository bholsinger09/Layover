import Foundation

/// Media content being played in Apple TV+ rooms
struct MediaContent: LayoverModel {
    let id: UUID
    var title: String
    var contentID: String
    var artworkURL: URL?
    var duration: TimeInterval
    var mediaType: MediaType
    
    enum MediaType: String, Codable, Sendable {
        case movie
        case tvShow
        case song
        case album
        case playlist
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        contentID: String,
        artworkURL: URL? = nil,
        duration: TimeInterval = 0,
        mediaType: MediaType
    ) {
        self.id = id
        self.title = title
        self.contentID = contentID
        self.artworkURL = artworkURL
        self.duration = duration
        self.mediaType = mediaType
    }
}
