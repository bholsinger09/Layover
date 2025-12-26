import AVKit
import OSLog
import SwiftUI

#if canImport(AppKit)
    import AppKit
#endif

/// Constants for AppleTVView UI timing
private enum UITiming {
    static let messageDisplayDuration: UInt64 = 3_000_000_000  // 3 seconds
    static let sessionCheckInterval: UInt64 = 2_000_000_000  // 2 seconds
}

/// View for Apple TV+ watching rooms
struct AppleTVView: View {
    let room: Room
    let currentUser: User
    let sharePlayService: SharePlayServiceProtocol
    let libraryService: LibraryServiceProtocol

    @State private var viewModel: AppleTVViewModel
    @State private var showingContentPicker = false
    
    init(room: Room, currentUser: User, sharePlayService: SharePlayServiceProtocol, libraryService: LibraryServiceProtocol) {
        self.room = room
        self.currentUser = currentUser
        self.sharePlayService = sharePlayService
        self.libraryService = libraryService
        self._viewModel = State(initialValue: AppleTVViewModel(
            tvService: AppleTVService(),
            sharePlayService: sharePlayService
        ))
    }
    @State private var sharePlayStarted = false
    @State private var sharePlayError: String?
    @State private var isSharePlayActive = false
    @State private var showJoinedMessage = false
    @State private var tvAppWindowOpened = false

    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "AppleTVView")

    var body: some View {
        VStack(spacing: 0) {
            // SharePlay status banner
            if isSharePlayActive {
                HStack {
                    Image(systemName: viewModel.sharePlayService.isSessionHost ? "crown.fill" : "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                    if viewModel.sharePlayService.isSessionHost {
                        Text("SharePlay Active - You're the host")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("SharePlay Active - Connected as participant")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
            }

            // SharePlay prompt banner - hide when:
            // 1. Content has been selected OR
            // 2. SharePlay has been started (even if session state changes) OR
            // 3. TV app window has been opened
            if viewModel.currentContent == nil && !sharePlayStarted && !tvAppWindowOpened {
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
                        logger.debug("🔵 Button tapped!")
                        Task {
                            logger.debug("🔵 Starting task...")
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
            
            // DEBUG: Test SharePlay messaging button - only for host
            if isSharePlayActive && viewModel.sharePlayService.isSessionHost {
                Button {
                    Task {
                        await viewModel.testShareContent()
                    }
                } label: {
                    Label("🧪 TEST: Share Test Content", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Show current content or instructions
            if viewModel.sharePlayService.isSessionActive {
                if let content = viewModel.currentContent {
                    ContentUnavailableView {
                        Label("Ready to Watch", systemImage: "popcorn.fill")
                    } description: {
                        VStack(spacing: 16) {
                            Text(content.title)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Sit back, relax, and enjoy!")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Open the Apple TV app to start watching together")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await libraryService.toggleFavorite(content)
                                    }
                                } label: {
                                    Label(
                                        libraryService.isFavorite(content) ? "Favorited" : "Add to Favorites",
                                        systemImage: libraryService.isFavorite(content) ? "heart.fill" : "heart"
                                    )
                                    .foregroundStyle(libraryService.isFavorite(content) ? .red : .blue)
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    Task {
                                        await viewModel.openContentInTVApp(content)
                                        // Track in watch history when opening
                                        await libraryService.addToWatchHistory(content, duration: 0, completed: false)
                                    }
                                } label: {
                                    Label("Open Apple TV App", systemImage: "tv.fill")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Content Selected",
                        systemImage: "tv",
                        description: Text("Select content to watch together with SharePlay")
                    )
                }
            } else {
                ContentUnavailableView(
                    "Enjoy Watching",
                    systemImage: "popcorn.fill",
                    description: Text(
                        "Sit back, relax, and enjoy your content together"
                    )
                )
            }

        }
        .navigationTitle(room.name)
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            logger.info("🎬 ═══════════════════════════════════")
            logger.info("🎬 AppleTVView appeared for room: \(room.name)")
            logger.info("   ViewModel callback is set: \(viewModel.sharePlayService.onContentReceived != nil)")
            logger.info("   SharePlay session active: \(viewModel.sharePlayService.isSessionActive)")
            logger.info("   Current content: \(viewModel.currentContent?.title ?? "none")")
            logger.info("🎬 ═══════════════════════════════════")

            // Listen for session state changes BEFORE checking initial state
            viewModel.sharePlayService.addSessionStateObserver { isActive in
                // Callback already runs on MainActor from SharePlayService
                logger.info("🔄 SharePlay state changed callback received: \(isActive)")
                logger.info("   Is session host: \(viewModel.sharePlayService.isSessionHost)")
                isSharePlayActive = isActive
                // Once SharePlay becomes active, mark as started and never reset
                if isActive {
                    sharePlayStarted = true
                    logger.info("✅ Updating UI to show SharePlay is active")
                } else {
                    logger.info("❌ Updating UI to show SharePlay is inactive")
                }
            }

            // Now check initial state after setting up callback
            isSharePlayActive = viewModel.sharePlayService.isSessionActive
            sharePlayStarted = isSharePlayActive
            logger.info("🎬 Initial SharePlay state on appear: \(isSharePlayActive)")
            logger.info("   Is session host: \(viewModel.sharePlayService.isSessionHost)")

            // Set up callback to detect when TV app opens
            viewModel.onTVAppOpened = {
                logger.info("📺 TV App opened - hiding SharePlay button")
                tvAppWindowOpened = true
            }
            
            // Content received callback is set up in ViewModel init
            // Just show notification when content is received
            if viewModel.currentContent != nil {
                logger.info("📺 Content is loaded: \(viewModel.currentContent?.title ?? "unknown")")
                // If content is already loaded, TV app may have already opened
                tvAppWindowOpened = true
            }

            // Periodically check session state in case callback was missed
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)  // Check every 1 second
                    let currentState = viewModel.sharePlayService.isSessionActive
                    logger.debug("🔍 Polling - Session Active: \(currentState), UI State: \(isSharePlayActive), Host: \(viewModel.sharePlayService.isSessionHost)")
                    if currentState != isSharePlayActive {
                        logger.warning(
                            "⚠️ Session state mismatch detected! Updating isSharePlayActive from \(isSharePlayActive) to: \(currentState)")
                        logger.warning("   Is session host: \(viewModel.sharePlayService.isSessionHost)")
                        await MainActor.run {
                            isSharePlayActive = currentState
                            // Don't reset sharePlayStarted to false - once started, keep it true
                            if currentState {
                                sharePlayStarted = true
                            }
                        }
                    }
                }
            }
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
            ContentPickerView(
                sharePlayActive: isSharePlayActive,
                libraryService: libraryService,
                onSelect: { content in
                    Task {
                        await viewModel.loadContent(content)
                        showingContentPicker = false
                    }
                }
            )
        }
    }

    private func startSharePlay() async {
        sharePlayError = nil
        logger.info("🎬 Starting SharePlay for Apple TV room: \(room.name)")

        // Include content metadata if available for better TV app coordination
        var metadata: [String: String] = ["roomName": room.name]
        if let content = viewModel.currentContent {
            metadata["contentID"] = content.contentID
            metadata["contentType"] = content.contentType == .movie ? "movie" : "show"
            metadata["title"] = content.title
        }

        let activity = LayoverActivity(
            roomID: room.id,
            activityType: .appleTVPlus,
            customMetadata: metadata
        )

        do {
            try await viewModel.sharePlayService.startActivity(activity)

            // Update state on main actor to trigger UI updates
            await MainActor.run {
                sharePlayStarted = true
                sharePlayError = nil
                isSharePlayActive = viewModel.sharePlayService.isSessionActive
                logger.info(
                    "✅ SharePlay started successfully, session active: \(isSharePlayActive)")
            }

            // Share the room data with other participants
            logger.info("📤 Sending room data to SharePlay participants...")
            await viewModel.sharePlayService.shareRoom(room)

            // If content is already selected, reload it with SharePlay coordination
            if let content = viewModel.currentContent {
                logger.info("🔄 Reloading content with SharePlay coordination...")
                await viewModel.loadContent(content)
            }
        } catch let error as SharePlayError {
            logger.error("❌ Failed to start SharePlay: \(error.localizedDescription)")
            await MainActor.run {
                sharePlayError = error.localizedDescription
                if let suggestion = error.recoverySuggestion {
                    sharePlayError = "\(error.localizedDescription)\n\(suggestion)"
                }
            }
        } catch {
            logger.error("❌ Failed to start SharePlay: \(error.localizedDescription)")
            await MainActor.run {
                sharePlayError = "Failed to start SharePlay: \(error.localizedDescription)"
            }
        }
    }
}

/// Content picker with real Apple TV+ shows
struct ContentPickerView: View {
    let sharePlayActive: Bool
    let libraryService: LibraryServiceProtocol
    let onSelect: (MediaContent) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        openAppleTVApp()
                    } label: {
                        HStack {
                            Image(systemName: "tv.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Open Apple TV App")
                                    .font(.headline)
                                Text("Browse and play any content")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Quick Access") {
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

                    appleTVButton(
                        title: "The Morning Show",
                        contentID: "umc.cmc.25tn3v8ku4b39tr6ccgb8nl6m",
                        type: .tvShow
                    )
                }
            }
            #if os(macOS)
                .frame(minWidth: 400, minHeight: 400)
            #endif
            .navigationTitle("Select Content")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
            .frame(minWidth: 500, minHeight: 500)
        #endif
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
        .disabled(!sharePlayActive)
    }

    private func openAppleTVApp() {
        #if canImport(UIKit)
            // Open Apple TV app on iOS
            if let url = URL(string: "videos://") {
                UIApplication.shared.open(url)
            }
        #elseif canImport(AppKit)
            // On macOS, open TV app by bundle identifier
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TV") {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        #endif
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AppleTVView(
            room: Room(name: "Movie Night", hostID: UUID(), activityType: .appleTVPlus),
            currentUser: User(username: "Test User"),
            sharePlayService: SharePlayService(),
            libraryService: LibraryService()
        )
    }
}
