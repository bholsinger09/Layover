import SwiftUI

/// Main app view with navigation
struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel(authService: AuthenticationService())
    @State private var viewModel = RoomListViewModel(
        roomService: RoomService(),
        sharePlayService: SharePlayService()
    )
    @State private var showingCreateRoom = false
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated, let currentUser = authViewModel.currentUser {
                mainAppView(currentUser: currentUser)
            } else {
                SignInView(viewModel: authViewModel)
            }
        }
        .task {
            await authViewModel.checkCredentialState()
        }
    }
    
    @ViewBuilder
    private func mainAppView(currentUser: User) -> some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading rooms...")
                } else {
                    roomsList(currentUser: currentUser)
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
                
                ToolbarItem(placement: .navigation) {
                    Menu {
                        Label(currentUser.username, systemImage: "person.circle.fill")
                        
                        if let email = currentUser.email {
                            Text(email)
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            Task {
                                await authViewModel.signOut()
                            }
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
    
    private func roomsList(currentUser: User) -> some View {
        List {
            ForEach(viewModel.rooms) { room in
                NavigationLink(destination: roomDetailView(for: room, currentUser: currentUser)) {
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
    private func roomDetailView(for room: Room, currentUser: User) -> some View {
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
