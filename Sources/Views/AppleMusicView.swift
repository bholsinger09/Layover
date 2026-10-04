import SwiftUI

// MARK: - Apple Music View

/// View for Apple Music listening rooms
public struct AppleMusicView: View {
    public let room: Room
    public let currentUser: User
    public let sharePlayService: SharePlayServiceProtocol

    @State var viewModel: AppleMusicViewModel
    @State var showingContentPicker = false
    @State var showingCreatePlaylist = false
    @State var sharePlayStarted = false
    @State var isSharePlayActive = false
    @State var showingSearch = false
    
    public init(room: Room, currentUser: User, sharePlayService: SharePlayServiceProtocol) {
        self.room = room
        self.currentUser = currentUser
        self.sharePlayService = sharePlayService
        self._viewModel = State(initialValue: AppleMusicViewModel(musicService: AppleMusicService()))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // SharePlay prompt banner
            if !isSharePlayActive {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await startSharePlay()
                        }
                    } label: {
                        Label("Start SharePlay to listen together", systemImage: "shareplay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.pink.opacity(0.1))
            }

            // Main content
            if viewModel.isAuthorized {
                if showingSearch {
                    searchView
                } else {
                    libraryBrowseView
                }
            } else {
                authorizationView
            }
            
            // Now Playing Bar
            if let content = viewModel.currentContent {
                nowPlayingBar(content)
            }
        }
        .navigationTitle(room.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSearch.toggle()
                } label: {
                    Label(showingSearch ? "Browse" : "Search", systemImage: showingSearch ? "music.note.list" : "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingCreatePlaylist) {
            MusicCreatePlaylistView { name in
                Task {
                    await viewModel.createPlaylist(name: name)
                    showingCreatePlaylist = false
                }
            }
        }
        .onAppear {
            sharePlayService.addSessionStateObserver { isActive in
                isSharePlayActive = isActive
                sharePlayStarted = isActive
            }
        }
        .task {
            if !viewModel.isAuthorized {
                await viewModel.requestAuthorization()
            }
            if viewModel.isAuthorized {
                await viewModel.loadLibraryContent()
            }
        }
    }

    private func startSharePlay() async {
        print("🎵 Starting SharePlay for Apple Music room: \(room.name)")
        let activity = LayoverActivity(
            roomID: room.id,
            activityType: .appleMusic,
            customMetadata: ["roomName": room.name]
        )

        do {
            try await sharePlayService.startActivity(activity)

            await MainActor.run {
                sharePlayStarted = true
                isSharePlayActive = sharePlayService.isSessionActive
                print("✅ SharePlay started successfully, session active: \(isSharePlayActive)")
            }

            print("📤 Sending room data to SharePlay participants...")
            await sharePlayService.shareRoom(room)
        } catch {
            print("❌ Failed to start SharePlay: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AppleMusicView(
            room: Room(name: "Music Session", hostID: UUID(), activityType: .appleMusic),
            currentUser: User(username: "Test User"),
            sharePlayService: SharePlayService()
        )
    }
}

