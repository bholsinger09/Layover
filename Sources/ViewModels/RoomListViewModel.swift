import Foundation
import Observation

/// ViewModel for managing rooms and room list
@MainActor
@Observable
final class RoomListViewModel: LayoverViewModel {
    private let roomService: RoomServiceProtocol
    private let sharePlayService: SharePlayServiceProtocol
    
    private(set) var rooms: [Room] = []
    private(set) var isLoading = false
    var errorMessage: String?
    
    nonisolated init(
        roomService: RoomServiceProtocol,
        sharePlayService: SharePlayServiceProtocol
    ) {
        self.roomService = roomService
        self.sharePlayService = sharePlayService
    }
    
    func loadRooms() async {
        isLoading = true
        errorMessage = nil
        
        do {
            rooms = try await roomService.fetchRooms()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createRoom(name: String, hostID: UUID, activityType: RoomActivityType) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let room = try await roomService.createRoom(
                name: name,
                hostID: hostID,
                activityType: activityType
            )
            rooms.append(room)
            
            // Start SharePlay activity
            let activity = LayoverActivity(
                roomID: room.id,
                activityType: activityType,
                customMetadata: ["roomName": name]
            )
            try await sharePlayService.startActivity(activity)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func joinRoom(_ room: Room, userID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await roomService.joinRoom(roomID: room.id, userID: userID)
            await loadRooms()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func leaveRoom(_ room: Room, userID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await roomService.leaveRoom(roomID: room.id, userID: userID)
            await sharePlayService.leaveSession()
            await loadRooms()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteRoom(_ room: Room) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await roomService.deleteRoom(roomID: room.id)
            rooms.removeAll { $0.id == room.id }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
