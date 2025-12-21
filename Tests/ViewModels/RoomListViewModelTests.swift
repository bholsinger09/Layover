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
        let hostID = UUID()
        
        await viewModel.createRoom(
            name: "Test Room",
            hostID: hostID,
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
        let hostID = UUID()
        
        _ = try? await roomService.createRoom(
            name: "Room 1",
            hostID: hostID,
            activityType: .texasHoldem
        )
        
        await viewModel.loadRooms()
        
        #expect(viewModel.rooms.count == 1)
        #expect(viewModel.isLoading == false)
    }
    
    @Test("Join room")
    func testJoinRoom() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let hostID = UUID()
        let userID = UUID()
        
        let room = try! await roomService.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleMusic
        )
        
        await viewModel.joinRoom(room, userID: userID)
        await viewModel.loadRooms()
        
        let updatedRoom = viewModel.rooms.first!
        #expect(updatedRoom.participantIDs.contains(userID))
    }
    
    @Test("Leave room")
    func testLeaveRoom() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let hostID = UUID()
        let userID = UUID()
        
        let room = try! await roomService.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .chess
        )
        
        try! await roomService.joinRoom(roomID: room.id, userID: userID)
        await viewModel.leaveRoom(room, userID: userID)
        await viewModel.loadRooms()
        
        let updatedRoom = viewModel.rooms.first!
        #expect(!updatedRoom.participantIDs.contains(userID))
    }
    
    @Test("Delete room")
    func testDeleteRoom() async {
        let roomService = RoomService()
        let viewModel = RoomListViewModel(
            roomService: roomService,
            sharePlayService: SharePlayService()
        )
        let hostID = UUID()
        
        let room = try! await roomService.createRoom(
            name: "Test Room",
            hostID: hostID,
            activityType: .appleTVPlus
        )
        
        await viewModel.deleteRoom(room)
        
        #expect(viewModel.rooms.isEmpty)
    }
}
