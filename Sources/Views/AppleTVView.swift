import SwiftUI
import AVKit

/// View for Apple TV+ watching rooms
struct AppleTVView: View {
    let room: Room
    let currentUser: User
    
    @State private var viewModel = AppleTVViewModel(
        tvService: AppleTVService(),
        sharePlayService: SharePlayService()
    )
    @State private var showingContentPicker = false
    
    var body: some View {
        VStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No Content Selected",
                    systemImage: "tv",
                    description: Text("Select content to watch together")
                )
            }
            
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
                    Label("Select Content", systemImage: "rectangle.stack.badge.play")
                }
            }
        }
        .sheet(isPresented: $showingContentPicker) {
            ContentPickerView(onSelect: { content in
                Task {
                    await viewModel.loadContent(content)
                    showingContentPicker = false
                }
            })
        }
    }
    
    private var controlBar: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await viewModel.togglePlayPause()
                }
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
            }
            .disabled(viewModel.player == nil)
            
            if let content = viewModel.currentContent {
                VStack(alignment: .leading) {
                    Text(content.title)
                        .font(.headline)
                    
                    Text(formatDuration(content.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Content picker placeholder
struct ContentPickerView: View {
    let onSelect: (MediaContent) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Button("Sample Movie") {
                    onSelect(MediaContent(
                        title: "Sample Movie",
                        contentID: "sample-movie",
                        duration: 7200,
                        mediaType: .movie
                    ))
                }
                
                Button("Sample TV Show") {
                    onSelect(MediaContent(
                        title: "Sample TV Show",
                        contentID: "sample-show",
                        duration: 3600,
                        mediaType: .tvShow
                    ))
                }
            }
            .navigationTitle("Select Content")
        }
    }
}

#Preview {
    NavigationStack {
        AppleTVView(
            room: Room(name: "Movie Night", hostID: UUID(), activityType: .appleTVPlus),
            currentUser: User(username: "Test User")
        )
    }
}
