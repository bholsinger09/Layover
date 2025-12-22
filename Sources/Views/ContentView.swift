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
    
    public init() {}
    
    public var body: some View {
        Group {
            if isAuthenticated {
                mainAppView
            } else {
                LoginView {
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
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let room = viewModel.rooms[index]
                    Task {
                        await viewModel.deleteRoom(room)
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
