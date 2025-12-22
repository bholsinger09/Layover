import AVKit
import SwiftUI

/// View for Apple TV+ watching rooms
struct AppleTVView: View {
    let room: Room
    let currentUser: User

    @State private var viewModel = AppleTVViewModel(
        tvService: AppleTVService(),
        sharePlayService: SharePlayService()
    )
    @State private var showingContentPicker = false
    @State private var sharePlayStarted = false
    @State private var sharePlayError: String?

    var body: some View {
        VStack(spacing: 0) {
            // SharePlay prompt banner
            if !sharePlayStarted && !viewModel.sharePlayService.isSessionActive {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "shareplay")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start SharePlay Session")
                                .font(.headline)
                            Text("Make sure you're in a FaceTime call first")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    Button {
                        print("🔵 Button tapped!")
                        Task {
                            print("🔵 Starting task...")
                            await startSharePlay()
                        }
                    } label: {
                        Label("Start SharePlay", systemImage: "shareplay")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }

                    if let error = sharePlayError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
            }

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
        .onAppear {
            print("🎬 AppleTVView appeared for room: \(room.name)")
            print("🎬 SharePlay active: \(viewModel.sharePlayService.isSessionActive)")
        }
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

    private func startSharePlay() async {
        sharePlayError = nil
        print("🎬 Starting SharePlay for Apple TV room: \(room.name)")
        let activity = LayoverActivity(
            roomID: room.id,
            activityType: .appleTVPlus,
            customMetadata: ["roomName": room.name]
        )

        do {
            try await viewModel.sharePlayService.startActivity(activity)
            sharePlayStarted = true
            sharePlayError = nil
            print("✅ SharePlay started successfully")
        } catch let error as SharePlayError {
            print("❌ Failed to start SharePlay: \(error.localizedDescription)")
            sharePlayError = error.localizedDescription
            if let suggestion = error.recoverySuggestion {
                sharePlayError = "\(error.localizedDescription)\n\(suggestion)"
            }
        } catch {
            print("❌ Failed to start SharePlay: \(error)")
            sharePlayError = "Failed to start SharePlay: \(error.localizedDescription)"
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

    private func appleTVButton(title: String, contentID: String, type: MediaContent.ContentType)
        -> some View
    {
        Button {
            onSelect(
                MediaContent(
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
