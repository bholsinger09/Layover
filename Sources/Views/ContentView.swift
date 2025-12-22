import SwiftUI

/// Main app view with navigation
public struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var viewModel = RoomListViewModel(
        roomService: RoomService(),
        sharePlayService: SharePlayService()
    )
    @State private var showingCreateRoom = false
    @State private var currentUsername = "User"
    @State private var editingRoom: Room?
    
    public init() {}
    
    public var body: some View {
        Group {
            if isAuthenticated {
                mainAppView
            } else {
                LoginView { username in
                    currentUsername = username
                    isAuthenticated = true
                }
            }
        }
    }
    
    private var mainAppView: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading rooms...")
                } else {
                    roomsList
                }
            }
            .navigationTitle("LayoverLounge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateRoom = true
                    } label: {
                        Label("Create Room", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    if viewModel.isSharePlayActive {
                        Label("SharePlay Active", systemImage: "shareplay")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            await viewModel.loadRooms()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Label(currentUsername, systemImage: "person.circle.fill")
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            isAuthenticated = false
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomView(
                    currentUser: User(id: UUID(), username: currentUsername),
                    onCreate: { name, activityType in
                        let host = User(id: UUID(), username: currentUsername)
                        await viewModel.createRoom(
                            name: name,
                            host: host,
                            activityType: activityType
                        )
                        showingCreateRoom = false
                    }
                )
            }
            .sheet(item: $editingRoom) { room in
                EditRoomView(room: room) { name, isPrivate, maxParticipants in
                    await viewModel.updateRoom(
                        room,
                        name: name,
                        isPrivate: isPrivate,
                        maxParticipants: maxParticipants
                    )
                }
            }
            .task {
                await viewModel.loadRooms()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var roomsList: some View {
        List {
            ForEach(viewModel.rooms) { room in
                NavigationLink(destination: roomDetailView(for: room)) {
                    RoomRowView(room: room)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteRoom(room)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        editingRoom = room
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    Button {
                        Task {
                            let currentUser = User(id: UUID(), username: currentUsername)
                            await viewModel.leaveRoom(room, userID: currentUser.id)
                        }
                    } label: {
                        Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .leading) {
                    if !room.participantIDs.contains(where: { _ in true }) {
                        Button {
                            Task {
                                let currentUser = User(id: UUID(), username: currentUsername)
                                await viewModel.joinRoom(room, user: currentUser)
                            }
                        } label: {
                            Label("Join", systemImage: "person.badge.plus")
                        }
                        .tint(.green)
                    }
                }
                .contextMenu {
                    Button {
                        Task {
                            let currentUser = User(id: UUID(), username: currentUsername)
                            await viewModel.joinRoom(room, user: currentUser)
                        }
                    } label: {
                        Label("Join Room", systemImage: "person.badge.plus")
                    }
                    
                    Button {
                        editingRoom = room
                    } label: {
                        Label("Edit Room", systemImage: "pencil")
                    }
                    
                    Button {
                        Task {
                            let currentUser = User(id: UUID(), username: currentUsername)
                            await viewModel.leaveRoom(room, userID: currentUser.id)
                        }
                    } label: {
                        Label("Leave Room", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteRoom(room)
                        }
                    } label: {
                        Label("Delete Room", systemImage: "trash")
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadRooms()
        }
    }
    
    @ViewBuilder
    private func roomDetailView(for room: Room) -> some View {
        let currentUser = User(id: UUID(), username: currentUsername)
        
        switch room.activityType {
        case .appleTVPlus:
            AppleTVView(room: room, currentUser: currentUser)
        case .appleMusic:
            AppleMusicView(room: room, currentUser: currentUser)
        case .texasHoldem:
            TexasHoldemView(room: room, currentUser: currentUser)
        case .chess:
            Text("Chess - Coming Soon")
        }
    }
}

#Preview {
    ContentView()
}
