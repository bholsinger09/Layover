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
    @State private var navigationPath = NavigationPath()
    @State private var sharePlayReceivedRoom: Room?
    @State private var libraryService = LibraryService()
    @State private var showingLibrary = false
    @State private var showingProfile = false

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
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // SharePlay status banner
                if viewModel.isSharePlayActive {
                    HStack {
                        Image(systemName: "shareplay")
                            .foregroundStyle(.green)
                        Text("SharePlay Active - Sharing with FaceTime participants")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                }

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading rooms...")
                    } else {
                        roomsList
                    }
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
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLibrary = true
                    } label: {
                        Label("My Library", systemImage: "books.vertical")
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
                    Button {
                        showingProfile = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.blue)
                            Text(currentUsername)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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
            .sheet(isPresented: $showingLibrary) {
                LibraryView(libraryService: libraryService)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(currentUsername: $currentUsername, isAuthenticated: $isAuthenticated)
            }
            .task {
                await viewModel.loadRooms()

                // Setup navigation when SharePlay room is received
                viewModel.onRoomReceivedForNavigation = { room in
                    print("🚀 Auto-navigating to SharePlay room: \(room.name)")
                    sharePlayReceivedRoom = room
                    navigationPath.append(room)
                }
            }
            .navigationDestination(for: Room.self) { room in
                roomDetailView(for: room)
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
            if viewModel.rooms.isEmpty {
                ContentUnavailableView(
                    "No Rooms Yet",
                    systemImage: "rectangle.3.group",
                    description: Text("Create a room or join a FaceTime call to see shared rooms")
                )
            } else {
                ForEach(viewModel.rooms) { room in
                    NavigationLink(value: room) {
                        RoomRowView(room: room)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
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
        }
        .refreshable {
            await viewModel.loadRooms()
        }
    }

    @ViewBuilder
    private func roomDetailView(for room: Room) -> some View {
        let currentUser = User(id: UUID(), username: currentUsername)
        let _ = print("🏠 Navigating to room: \(room.name), type: \(room.activityType)")

        switch room.activityType {
        case .appleTVPlus:
            AppleTVView(room: room, currentUser: currentUser, sharePlayService: viewModel.sharePlayService, libraryService: libraryService)
        case .appleMusic:
            AppleMusicView(room: room, currentUser: currentUser, sharePlayService: viewModel.sharePlayService)
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
