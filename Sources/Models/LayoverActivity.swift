import Foundation
import GroupActivities

/// SharePlay activity for synchronized group experiences
struct LayoverActivity: GroupActivity {
    static let activityIdentifier = "com.bholsinger.LayoverLounge.activity"
    
    let roomID: UUID
    let activityType: RoomActivityType
    let customMetadata: [String: String]
    
    var metadata: GroupActivityMetadata {
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
        case .texasHoldem, .chess:
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
        case .texasHoldem:
            return "Texas Hold'em"
        case .chess:
            return "Chess"
        }
    }
}

