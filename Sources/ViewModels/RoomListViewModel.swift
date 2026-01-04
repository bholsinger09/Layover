import Foundation
import OSLog
import Observation

/// ViewModel for managing rooms and room list
@MainActor
@Observable
public final class RoomListViewModel: LayoverViewModel {
    private let logger = Logger(
        subsystem: "com.bholsinger.LayoverLounge", category: "RoomListViewModel")
    private let roomService: RoomServiceProtocol
    public let sharePlayService: SharePlayServiceProtocol

    public private(set) var rooms: [Room] = []
    public private(set) var isLoading = false
    public var errorMessage: String?
    public var onRoomReceivedForNavigation: ((Room) -> Void)?
    public private(set) var isSharePlayActive = false

    public nonisolated init(
        roomService: RoomServiceProtocol,
        sharePlayService: SharePlayServiceProtocol
    ) {
        self.roomService = roomService
        self.sharePlayService = sharePlayService

        print("🎯 ========== ROOMLISTVIEWMODEL INIT ==========")
        print("🎯 SharePlayService instance created")
        print("🎯 Setting up SharePlay callbacks...")
        print("🎯 ============================================")
        
        // Setup SharePlay callbacks asynchronously
        Task { @MainActor [sharePlayService] in
            sharePlayService.onRoomReceived = { [weak self] room in
                guard let self = self else { return }
                print("📥 ========== SHAREPLAY ROOM RECEIVED ==========")
                print("📥 Room: \(room.name)")
                print("📥 Room ID: \(room.id)")
                print("📥 Activity: \(room.activityType)")
                print("📥 Participants: \(room.participants.count)")
                print("📥 This should appear on both iPhone & Apple TV Simulator")
                print("📥 ============================================")
                self.logger.info("📥 SharePlay: Received room '\(room.name)' from participant")
                // Add room from SharePlay participant if not already in list
                if !self.rooms.contains(where: { $0.id == room.id }) {
                    self.rooms.append(room)
                    self.logger.info("✅ Room added to list. Total rooms: \(self.rooms.count)")
                    print("✅ Room added! Total rooms now: \(self.rooms.count)")
                    // Trigger navigation callback
                    self.onRoomReceivedForNavigation?(room)
                } else {
                    self.logger.debug("⚠️ Room already exists in list")
                    print("⚠️ Room already in list, not adding duplicate")
                }
            }

            sharePlayService.onParticipantJoined = { [weak self] user, roomID in
                guard let self = self else { return }
                self.logger.info("👤 SharePlay: User '\(user.username)' joined room")
                // Add participant to room
                if let index = self.rooms.firstIndex(where: { $0.id == roomID }) {
                    var room = self.rooms[index]
                    if !room.participants.contains(where: { $0.id == user.id }) {
                        room.participants.append(user)
                        room.participantIDs.insert(user.id)
                        self.rooms[index] = room
                        self.logger.info(
                            "✅ Participant added. Total in room: \(room.participants.count)")
                    } else {
                        self.logger.debug("⚠️ Participant already in room")
                    }
                }
            }

            // Setup SharePlay session state change observer
            sharePlayService.addSessionStateObserver { [weak self] isActive in
                // Callback already runs on MainActor from SharePlayService
                guard let self = self else { return }
                print("🔄 ========== SHAREPLAY SESSION STATE CHANGED ==========")
                print("🔄 Active: \(isActive)")
                print("🔄 Device Info:")
                #if targetEnvironment(simulator)
                print("   📱 Running on: SIMULATOR")
                #else
                print("   📱 Running on: PHYSICAL DEVICE")
                #endif
                #if os(tvOS)
                print("   📺 Platform: tvOS")
                #elseif os(iOS)
                print("   📱 Platform: iOS")
                #elseif os(macOS)
                print("   💻 Platform: macOS")
                #endif
                print("🔄 Current Apple ID should match FaceTime participant")
                print("🔄 ====================================================")
                self.logger.info("🔄 RoomListViewModel: SharePlay session state changed to \(isActive)")
                self.isSharePlayActive = isActive
            }
        }
    }

    public func loadRooms() async {
        isLoading = true
        errorMessage = nil

        do {
            rooms = try await roomService.fetchRooms()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func createRoom(name: String, host: User, activityType: RoomActivityType) async {
        isLoading = true
        errorMessage = nil

        do {
            let room = try await roomService.createRoom(
                name: name,
                host: host,
                activityType: activityType
            )
            rooms.append(room)

            logger.info("📤 SharePlay: Sharing room '\(name)' with participants")
            // Share room with SharePlay participants
            await sharePlayService.shareRoom(room)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func updateRoom(_ room: Room, name: String, isPrivate: Bool, maxParticipants: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            try await roomService.updateRoom(
                roomID: room.id,
                name: name,
                isPrivate: isPrivate,
                maxParticipants: maxParticipants
            )
            await loadRooms()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func joinRoom(_ room: Room, user: User) async {
        isLoading = true
        errorMessage = nil

        do {
            try await roomService.joinRoom(roomID: room.id, user: user)

            // Share user joined with SharePlay participants
            await sharePlayService.shareUserJoined(user, roomID: room.id)

            await loadRooms()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func leaveRoom(_ room: Room, userID: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            try await roomService.leaveRoom(roomID: room.id, userID: userID)
            await sharePlayService.leaveSession()
            await loadRooms()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func deleteRoom(_ room: Room) async {
        isLoading = true
        errorMessage = nil

        do {
            try await roomService.deleteRoom(roomID: room.id)
            rooms.removeAll { $0.id == room.id }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public func startSharePlayForRoom(_ room: Room) async {
        do {
            logger.info("🎬 SharePlay: Starting activity for room '\(room.name)'")
            let activity = LayoverActivity(
                roomID: room.id,
                activityType: room.activityType,
                customMetadata: ["roomName": room.name]
            )
            try await sharePlayService.startActivity(activity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
