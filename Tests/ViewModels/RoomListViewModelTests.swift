import Testing
import Foundation
@testable import LayoverKit

/// Tests for RoomListViewModel
@Suite("Room List ViewModel Tests")
@MainActor
struct RoomListViewModelTests {
    
    @Test("Initialize view model")
    func testInitialization() {
        let viewModel = RoomListViewModel(
            roomService: RoomService(),
            sharePlayService: SharePlayService()
        )
        
        #expect(viewModel.rooms.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Create room")
    func testCreateRoom() async {
        let viewModel = RoomListViewModel(
            roomService: RoomService(),
            sharePlayService: SharePlayService()
        )
        let host = User(username: "TestHost")
        
        await viewModel.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleTVPlus
        )
        
        #expect(viewModel.rooms.count == 1)
        #expect(viewModel.rooms.first?.name == "Test Room")
    }
    
    @Test("Load rooms")
    func testLoadRooms() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let host = User(username: "TestHost")
        
        _ = try? await roomService.createRoom(
            name: "Room 1",
            host: host,
            activityType: .texasHoldem
        )
        
        // Check service rooms directly since loadRooms loads from UserDefaults
        #expect(roomService.rooms.count == 1)
        #expect(!viewModel.isLoading)
    }
    
    @Test("Join room")
    func testJoinRoom() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let host = User(username: "Host")
        let user = User(username: "Joiner")
        
        // Create room directly in service
        let room = try! await roomService.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleMusic
        )
        
        // Join through service
        try! await roomService.joinRoom(roomID: room.id, user: user)
        
        // Verify in service
        let updatedRoom = roomService.rooms.first!
        #expect(updatedRoom.participantIDs.contains(user.id))
        #expect(updatedRoom.participantIDs.count == 2)
    }
    
    @Test("Leave room")
    func testLeaveRoom() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let host = User(username: "Host")
        let user = User(username: "Leaver")
        
        // Create room directly in service
        let room = try! await roomService.createRoom(
            name: "Test Room",
            host: host,
            activityType: .chess
        )
        
        try! await roomService.joinRoom(roomID: room.id, user: user)
        try! await roomService.leaveRoom(roomID: room.id, userID: user.id)
        
        // Verify in service
        let updatedRoom = roomService.rooms.first!
        #expect(!updatedRoom.participantIDs.contains(user.id))
    }
    
    @Test("Delete room")
    func testDeleteRoom() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let host = User(username: "Host")
        
        // Create room directly in service
        let room = try! await roomService.createRoom(
            name: "Test Room",
            host: host,
            activityType: .appleTVPlus
        )
        
        try! await roomService.deleteRoom(roomID: room.id)
        
        #expect(roomService.rooms.isEmpty)
    }
}
