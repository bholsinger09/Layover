import SwiftUI

/// View for Apple Music listening rooms
struct AppleMusicView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel = AppleMusicViewModel(musicService: AppleMusicService())
    @State private var showingContentPicker = false
    @State private var sharePlayService = SharePlayService()
    @State private var sharePlayStarted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // SharePlay prompt banner
            if !sharePlayStarted && !sharePlayService.isSessionActive {
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
            
            Spacer()
            
            if let content = viewModel.currentContent {
                currentContentView(content)
            } else {
                ContentUnavailableView(
                    "No Music Selected",
                    systemImage: "music.note",
                    description: Text("Select music to listen together")
                )
            }
            
            Spacer()
            
            controlBar
        }
        .navigationTitle(room.name)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingContentPicker = true
                } label: {
                    Label("Select Music", systemImage: "music.note.list")
                }
            }
        }
        .sheet(isPresented: $showingContentPicker) {
            MusicPickerView(onSelect: { content in
                Task {
                    await viewModel.loadContent(content)
                    showingContentPicker = false
                }
            })
        }
        .task {
            if !viewModel.isAuthorized {
                await viewModel.requestAuthorization()
            }
        }
    }
    
    private func currentContentView(_ content: MediaContent) -> some View {
        VStack(spacing: 16) {
            if let artworkURL = content.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                }
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 10)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 100))
                    .foregroundStyle(.secondary)
                    .frame(width: 300, height: 300)
            }
            
            Text(content.title)
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    private var controlBar: some View {
        HStack(spacing: 30) {
            Button {
                // Previous track
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
            }
            
            Button {
                Task {
                    await viewModel.togglePlayPause()
                }
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
            }
            .disabled(viewModel.currentContent == nil)
            
            Button {
                // Next track
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
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
            sharePlayStarted = true
            print("✅ SharePlay started successfully")
        } catch {
            print("❌ Failed to start SharePlay: \(error)")
        }
    }
}

/// Music picker placeholder
struct MusicPickerView: View {
    let onSelect: (MediaContent) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Button("Sample Song") {
                    onSelect(MediaContent(
                        title: "Sample Song",
                        contentID: "sample-song",
                        duration: 240,
                        contentType: .song
                    ))
                }
                
                Button("Sample Album") {
                    onSelect(MediaContent(
                        title: "Sample Album",
                        contentID: "sample-album",
                        duration: 3600,
                        contentType: .album
                    ))
                }
            }
            .navigationTitle("Select Music")
        }
    }
}

#Preview {
    NavigationStack {
        AppleMusicView(
            room: Room(name: "Music Session", hostID: UUID(), activityType: .appleMusic),
            currentUser: User(username: "Test User")
        )
    }
}
