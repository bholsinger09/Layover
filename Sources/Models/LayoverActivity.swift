import Foundation
import GroupActivities

/// SharePlay activity for synchronized group experiences
struct LayoverActivity: GroupActivity {
    static let activityIdentifier = "com.layover.activity"
    
    let roomID: UUID
    let activityType: RoomActivityType
    let customMetadata: [String: String]
    
    var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.title = "Layover - \(activityType.rawValue)"
        meta.type = .generic
        meta.supportsContinuationOnTV = true
        return meta
    }
}
