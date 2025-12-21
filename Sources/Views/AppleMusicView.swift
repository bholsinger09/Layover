import SwiftUI

/// View for Apple Music listening rooms
struct AppleMusicView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel = AppleMusicViewModel(musicService: AppleMusicService())
    @State private var showingContentPicker = false
    
    var body: some View {
        VStack {
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
                        mediaType: .song
                    ))
                }
                
                Button("Sample Album") {
                    onSelect(MediaContent(
                        title: "Sample Album",
                        contentID: "sample-album",
                        duration: 3600,
                        mediaType: .album
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
