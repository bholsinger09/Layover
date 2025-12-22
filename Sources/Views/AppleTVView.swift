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

/// Content picker with real Apple TV+ shows and option to open TV app
struct ContentPickerView: View {
    let onSelect: (MediaContent) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Popular Movies") {
                    appleTVButton(
                        title: "Ted Lasso",
                        contentID: "umc.cmc.vtoh0mn0xn7t3c643xqonfzy",
                        type: .tvShow
                    )
                    
                    appleTVButton(
                        title: "Foundation",
                        contentID: "umc.cmc.5983fipzqbicvrve6jdfep4x3",
                        type: .tvShow
                    )
                    
                    appleTVButton(
                        title: "Severance",
                        contentID: "umc.cmc.1srk2goyh2q2zdxcx605w8vtx",
                        type: .tvShow
                    )
                }
                
                Section("Open in Apple TV App") {
                    Button {
                        // Open TV app directly
                        openTVApp()
                    } label: {
                        Label("Browse Apple TV+", systemImage: "tv")
                    }
                }
            }
            .navigationTitle("Select Content")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func appleTVButton(title: String, contentID: String, type: MediaContent.ContentType) -> some View {
        Button {
            onSelect(MediaContent(
                title: title,
                contentID: contentID,
                duration: type == .movie ? 7200 : 3600,
                contentType: type
            ))
        } label: {
            HStack {
                Image(systemName: type == .movie ? "film" : "tv")
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.forward.square")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func openTVApp() {
        #if canImport(UIKit)
        if let url = URL(string: "videos://") {
            UIApplication.shared.open(url)
        }
        #endif
        dismiss()
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
