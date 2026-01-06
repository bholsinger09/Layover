import Foundation
import GroupActivities

/// SharePlay activity for synchronized group experiences
public struct LayoverActivity: GroupActivity {
    public static let activityIdentifier = "com.bholsinger.LayoverLounge.activity"
    
    public let roomID: UUID
    public let activityType: RoomActivityType
    public let customMetadata: [String: String]
    
    public var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        
        // Set title based on room name if available
        if let roomName = customMetadata["roomName"] {
            meta.title = roomName
            meta.subtitle = "LayoverLounge - \(activityTypeName)"
        } else {
            meta.title = "LayoverLounge"
            meta.subtitle = activityTypeName
        }
        
        // Set the type based on activity
        switch activityType {
        case .appleTVPlus:
            meta.type = .watchTogether
            // Add fallback URL for Apple TV content if provided
            if let contentID = customMetadata["contentID"],
               let contentType = customMetadata["contentType"] {
                let urlString = "https://tv.apple.com/\(contentType)/\(contentID)"
                if let url = URL(string: urlString) {
                    meta.fallbackURL = url
                }
            }
        case .appleMusic:
            meta.type = .listenTogether
        case .chess:
            meta.type = .generic
        }
        
        meta.supportsContinuationOnTV = activityType == .appleTVPlus
        
        return meta
    }
    
    private var activityTypeName: String {
        switch activityType {
        case .appleTVPlus:
            return "Apple TV+"
        case .appleMusic:
            return "Apple Music"
        case .chess:
            return "Chess"
        }
    }
}

