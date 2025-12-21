import SwiftUI

/// Main app view with navigation
struct ContentView: View {
    @State private var viewModel = RoomListViewModel(
        roomService: RoomService(),
        sharePlayService: SharePlayService()
    )
    @State private var currentUser = User(username: "Guest", isHost: false)
    @State private var showingCreateRoom = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading rooms...")
                } else {
                    roomsList
                }
            }
            .navigationTitle("Layover")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateRoom = true
                    } label: {
                        Label("Create Room", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomView(
                    currentUser: currentUser,
                    onCreate: { name, activityType in
                        await viewModel.createRoom(
                            name: name,
                            hostID: currentUser.id,
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
