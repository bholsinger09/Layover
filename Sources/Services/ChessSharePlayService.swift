import Foundation
import GroupActivities
import Combine
import os

@MainActor
public final class ChessSharePlayService {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "ChessSharePlay")
    
    public private(set) var currentSession: GroupSession<ChessActivity>?
    private var messenger: GroupSessionMessenger?
    private var subscriptions = Set<AnyCancellable>()
    private var sessionMonitoringTask: Task<Void, Never>?  // Persistent session monitor
    private var messageListenerTask: Task<Void, Never>?   // Per-session message listener
    
    // Session persistence for reconnection
    private var lastRoomID: UUID?
    private var lastGameID: UUID?
    private var lastRoomName: String?
    private var shouldAutoReconnect = false
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 3
    
    // Helper to avoid print ambiguity in @MainActor context
    private nonisolated func log(_ message: String) {
        print(message)
    }
    
    @Published public private(set) var isActive = false
    @Published public private(set) var participants: [Participant] = []
    
    public struct Participant: Identifiable, Hashable {
        public let id: UUID
        public let name: String?
        
        public init(id: UUID, name: String?) {
            self.id = id
            self.name = name
        }
    }
    
    // Callbacks for game events
    public var onSessionStarted: (() -> Void)?
    public var onSessionEnded: (() -> Void)?
    public var onGameStateUpdate: ((ChessGameState) -> Void)?
    public var onPlayerMove: ((ChessMessage.Move) -> Void)?
    public var onPlayerResign: ((UUID) -> Void)?
    
    public nonisolated init() {
        Task { @MainActor in
            self.logger.info("🎯 ChessSharePlayService initialized")
            
            self.log("🎯 ===== CHESS SHAREPLAY SERVICE INIT =====")
            
            await startSessionMonitoring()
        }
    }
    
    deinit {
        self.log("🧹 ChessSharePlayService deinitialized")
        sessionMonitoringTask?.cancel()
        messageListenerTask?.cancel()
        subscriptions.removeAll()
    }
    
    private func startSessionMonitoring() async {
        self.logger.info("📡 Starting session monitoring...")
        
        let sessions = ChessActivity.sessions()
        
        self.log("📡 Chess sessions stream created")
        
        sessionMonitoringTask = Task { @MainActor in
            self.log("🔄 Starting to iterate over Chess sessions...")
            var sessionCount = 0
            for await session in sessions {
                sessionCount += 1
                self.logger.info("🎮 New Chess session received (count: \(sessionCount))")
                self.log("🎮 ===== NEW CHESS SESSION RECEIVED =====")
                self.log("   Session count: \(sessionCount)")
                self.log("   Session ID: \(session.id)")
                self.log("   Session state: \(String(describing: session.state))")
                
                await handleSession(session)
            }
            self.log("⚠️ Chess sessions loop ended unexpectedly")
        }
        
        self.log("✅ Session monitoring task started")
    }
    
    private func handleSession(_ session: GroupSession<ChessActivity>) async {
        self.logger.info("🎮 Handling new Chess session: \(session.id)")
        self.log("🎮 ===== HANDLING SESSION =====")
        self.log("   ID: \(session.id)")
        self.log("   State: \(String(describing: session.state))")
        self.log("   Activity: \(session.activity.roomID)")
        
        // Store session and join
        currentSession = session
        isActive = true
        
        // Join the session
        self.log("🚪 Joining session...")
        self.log("🔍 Pre-join session state: \(String(describing: session.state))")
        self.log("🔍 Pre-join participants: \(session.activeParticipants.count)")
        session.join()
        self.logger.info("✅ Join called on Chess session")
        self.log("✅ Session join() called")
        
        // Wait a moment for the join to take effect
        self.log("⏳ Waiting for session to activate...")
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        self.log("🔍 Session state after join: \(String(describing: session.state))")
        self.log("🔍 Active participants: \(session.activeParticipants.count)")
        
        if session.activeParticipants.isEmpty {
            self.log("⚠️ WARNING: No participants after join!")
            self.log("⚠️ This suggests:")
            self.log("   1. Not in an active FaceTime call")
            self.log("   2. Other participant hasn't joined yet")
            self.log("   3. SharePlay permissions not granted")
            self.log("   4. Network/firewall blocking SharePlay")
        }
        
        // Create messenger for this session
        self.log("📮 Creating messenger...")
        let newMessenger = GroupSessionMessenger(session: session)
        messenger = newMessenger
        self.logger.info("📮 Messenger created for Chess session")
        self.log("✅ Messenger created")
        
        // Monitor session state changes
        self.log("👁️ Setting up state monitoring...")
        session.$state
            .sink { [weak self] state in
                guard let self = self else { return }
                Task { @MainActor in
                    self.logger.info("📊 Session state changed to: \(String(describing: state))")
                    self.log("📊 Session state: \(state)")
                    
                    switch state {
                    case .waiting:
                        self.log("⏳ Session waiting for participants...")
                    case .joined:
                        self.log("✅ Session JOINED - starting message listener if not already running")
                        self.onSessionStarted?()
                        
                        // Start message listener when session is actually joined
                        if self.messageListenerTask == nil || self.messageListenerTask?.isCancelled == true {
                            Task {
                                await self.startMessageListener(messenger: newMessenger)
                            }
                        }
                    case .invalidated(let reason):
                        self.log("❌ Session invalidated: \(reason)")
                        self.log("📊 Reason details: \(String(describing: reason))")
                        
                        // Check if it's a connection/network error that might be recoverable
                        let isConnectionError = String(describing: reason).contains("connection") || 
                                               String(describing: reason).contains("network")
                        
                        if isConnectionError {
                            self.log("🔌 Connection error detected")
                            self.log("ℹ️ This may be temporary - will attempt reconnection")
                            
                            // Try to reconnect if auto-reconnect is enabled
                            if self.shouldAutoReconnect {
                                await self.attemptReconnection()
                            } else {
                                await self.cleanup()
                                self.onSessionEnded?()
                            }
                        } else {
                            self.log("🚫 Session ended: \(reason)")
                            self.shouldAutoReconnect = false
                            await self.cleanup()
                            self.onSessionEnded?()
                        }
                    @unknown default:
                        self.log("❓ Unknown session state")
                    }
                }
            }
            .store(in: &subscriptions)
        
        // Setup participant monitoring
        setupParticipantMonitoring(session: session)
        
        // Only start message listener if session is already joined
        if session.state == .joined {
            self.log("👂 Session already joined, starting message listener...")
            await startMessageListener(messenger: newMessenger)
        } else {
            self.log("ℹ️ Session not yet joined (state: \(session.state)), will wait for joined state")
        }
        
        self.log("✅ Setup complete for session \(session.id)")
    }
    
    private func setupParticipantMonitoring(session: GroupSession<ChessActivity>) {
        self.logger.info("👥 Setting up participant monitoring")
        self.log("👥 Setting up participant monitoring...")
        
        session.$activeParticipants
            .sink { [weak self] participants in
                guard let self = self else { return }
                Task { @MainActor in
                    self.logger.info("👥 Active participants changed: \(participants.count)")
                    self.log("👥 Participants updated: \(participants.count)")
                    
                    self.participants = participants.map { participant in
                        Participant(
                            id: participant.id,
                            name: nil
                        )
                    }
                    
                    for (index, participant) in participants.enumerated() {
                        self.log("   [\(index)] ID: \(participant.id)")
                    }
                    
                    // Handle participant count changes
                    if participants.count == 0 {
                        self.log("⚠️ No participants - session likely ending")
                    } else if participants.count == 1 {
                        self.log("ℹ️ Only 1 participant - waiting for others to rejoin...")
                        self.log("ℹ️ Session will stay active for reconnection")
                    } else {
                        self.log("✅ \(participants.count) participants active")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func startMessageListener(messenger: GroupSessionMessenger) async {
        self.logger.info("📬 Starting message listener...")
        self.log("📬 Starting message listener...")
        
        // Cancel any existing message listener before starting a new one
        messageListenerTask?.cancel()
        
        // Capture messenger strongly to prevent deallocation during iteration
        let capturedMessenger = messenger
        
        messageListenerTask = Task { @MainActor in
            self.log("🔄 Starting message iteration loop...")
            self.log("🔍 Session active: \(self.currentSession != nil)")
            self.log("🔍 Session state: \(String(describing: self.currentSession?.state))")
            var messageCount = 0
            var iterationCount = 0
            
            // Keep trying to listen as long as the session is active
            while self.currentSession != nil && !Task.isCancelled {
                iterationCount += 1
                self.log("🔄 Message listener iteration #\(iterationCount)")
                
                // Check if session is in joined state
                if self.currentSession?.state != .joined {
                    self.log("⏳ Session not in joined state yet (\(String(describing: self.currentSession?.state))), waiting...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continue
                }
                
                // Check if we have participants
                if self.participants.isEmpty {
                    self.log("⏳ No participants yet, waiting...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    continue
                }
                
                self.log("📬 Listening for messages (\(self.participants.count) participants)...")
                
                do {
                    for await (message, _) in capturedMessenger.messages(of: ChessMessage.self) {
                        // Check if we're still in an active session
                        guard self.currentSession != nil && !Task.isCancelled else {
                            self.log("⚠️ Session ended or task cancelled, stopping message listener")
                            break
                        }
                        
                        messageCount += 1
                        self.logger.info("📨 Received Chess message #\(messageCount)")
                        self.log("📨 Message #\(messageCount) received")
                        await handleMessage(message)
                    }
                    
                    // If loop completes but session is still active, retry
                    if self.currentSession != nil && !Task.isCancelled {
                        self.log("⚠️ Message iterator completed but session still active")
                        self.log("🔄 Session state: \(String(describing: self.currentSession?.state))")
                        self.log("🔄 Participants: \(self.participants.count)")
                        
                        // Don't retry if we're not in joined state or only participant
                        if self.currentSession?.state != .joined {
                            self.log("ℹ️ Session not joined yet, will retry when joined")
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        } else if self.participants.count <= 1 {
                            self.log("ℹ️ Only \(self.participants.count) participant(s) - pausing message listener")
                            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        } else {
                            self.log("🔄 Retrying message listener...")
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        }
                    } else {
                        break
                    }
                } catch {
                    if self.currentSession != nil && !Task.isCancelled {
                        self.log("❌ Message listener error: \(error)")
                        self.logger.error("❌ Message listener error: \(error.localizedDescription)")
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    } else {
                        break
                    }
                }
            }
            
            self.log("🚦 Message listener stopped")
            self.log("🔍 Final session: \(self.currentSession != nil)")
            self.log("🔍 Total messages: \(messageCount)")
            self.log("🔍 Iterations: \(iterationCount)")
            
            if self.currentSession != nil && self.isActive && !Task.isCancelled {
                self.logger.warning("⚠️ Message listener ended while session still active")
                self.log("⚠️ ===== UNEXPECTED END =====")
                self.log("⚠️ Session: \(self.currentSession?.id.uuidString ?? "none")")
                self.log("⚠️ State: \(String(describing: self.currentSession?.state))")
                self.log("⚠️ ===========================")
            }
        }
        
        self.log("✅ Message listener task started")
    }
    
    private func handleMessage(_ message: ChessMessage) async {
        self.logger.info("📨 Handling Chess message: \(String(describing: message))")
        self.log("📨 Handling message type: \(String(describing: message))")
        
        switch message {
        case .gameStarted(let roomID, let gameID, let playerIDs):
            self.logger.info("🎮 Game started - Room: \(roomID), Game: \(gameID), Players: \(playerIDs.count)")
            self.log("🎮 Game started notification")
            
        case .gameStateUpdate(let state):
            self.logger.info("🔄 Game state update received for game: \(state.gameID)")
            self.log("🔄 Game state update")
            onGameStateUpdate?(state)
            
        case .playerMove(let move):
            self.logger.info("🎯 Player move: \(move.playerID) from (\(move.fromRow),\(move.fromCol)) to (\(move.toRow),\(move.toCol))")
            self.log("🎯 Player move received")
            onPlayerMove?(move)
            
        case .playerResign(let playerID):
            self.logger.info("🏳️ Player resigned: \(playerID)")
            self.log("🏳️ Player resigned")
            onPlayerResign?(playerID)
            
        case .gameEnded(let winnerID, let reason):
            self.logger.info("🏁 Game ended - Winner: \(String(describing: winnerID)), Reason: \(reason)")
            self.log("🏁 Game ended")
            
        case .testPing(let from, let message, let senderID):
            self.logger.info("🏓 Received ping from \(from): \(message) (ID: \(senderID))")
            self.log("🏓 PING: \(message)")
            
        case .testPong(let from, let message, let senderID):
            self.logger.info("🏓 Received pong from \(from): \(message) (ID: \(senderID))")
            self.log("🏓 PONG: \(message)")
        }
    }
    
    public func startSharePlay(roomID: UUID, gameID: UUID, roomName: String?) async throws {
        self.logger.info("🚀 Starting Chess SharePlay - Room: \(roomID), Game: \(gameID)")
        self.log("🚀 ===== STARTING CHESS SHAREPLAY =====")
        self.log("   Room ID: \(roomID)")
        self.log("   Game ID: \(gameID)")
        self.log("   Room name: \(roomName ?? "nil")")
                // Save session details for reconnection
        lastRoomID = roomID
        lastGameID = gameID
        lastRoomName = roomName
        shouldAutoReconnect = true
        reconnectionAttempts = 0
                let activity = ChessActivity(
            roomID: roomID,
            gameID: gameID,
            roomName: roomName
        )
        
        self.log("📦 Chess activity created")
        self.log("   Activity ID: \(ChessActivity.activityIdentifier)")
        
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            self.logger.info("✅ Activation preferred - activating...")
            self.log("✅ Activation preferred")
            
            do {
                _ = try await activity.activate()
                self.logger.info("🎉 Chess activity activated successfully")
                self.log("🎉 Activity activated!")
            } catch {
                self.logger.error("❌ Failed to activate: \(error.localizedDescription)")
                self.log("❌ Activation failed: \(error)")
                throw error
            }
            
        case .activationDisabled:
            self.logger.warning("⚠️ SharePlay is disabled")
            self.log("⚠️ SharePlay disabled")
            throw ChessSharePlayError.sharePlayDisabled
            
        case .cancelled:
            self.logger.warning("⚠️ User cancelled")
            self.log("⚠️ User cancelled")
            throw ChessSharePlayError.userCancelled
            
        @unknown default:
            self.logger.error("❌ Unknown activation result")
            self.log("❌ Unknown activation result")
            throw ChessSharePlayError.activationFailed
        }
    }
    
    public func sendMessage(_ message: ChessMessage) async {
        guard let messenger = messenger else {
            self.logger.warning("⚠️ No messenger available to send message")
            self.log("⚠️ Cannot send message - no messenger")
            return
        }
        
        do {
            self.logger.info("📤 Sending Chess message: \(String(describing: message))")
            self.log("📤 Sending message...")
            try await messenger.send(message)
            self.logger.info("✅ Message sent successfully")
            self.log("✅ Message sent")
        } catch {
            self.logger.error("❌ Failed to send message: \(error.localizedDescription)")
            self.log("❌ Send failed: \(error)")
        }
    }
    
    public func endSession() async {
        self.logger.info("🛑 Ending Chess SharePlay session")
        self.log("🛑 Ending session...")
        
        shouldAutoReconnect = false
        currentSession?.end()
        currentSession = nil  // Only clear here when explicitly ending
        messenger = nil      // Clear messenger when explicitly ending
        await cleanup()
        
        self.logger.info("✅ Session ended")
        self.log("✅ Session ended")
    }
    
    private func attemptReconnection() async {
        guard shouldAutoReconnect,
              self.reconnectionAttempts < self.maxReconnectionAttempts,
              let roomID = lastRoomID,
              let gameID = lastGameID else {
            self.log("⚠️ Cannot reconnect - missing session details or max attempts reached")
            await cleanup()
            onSessionEnded?()
            return
        }
        
        reconnectionAttempts += 1
        self.logger.info("🔄 Attempting reconnection #\(self.reconnectionAttempts)/\(self.maxReconnectionAttempts)")
        self.log("🔄 ===== RECONNECTION ATTEMPT #\(self.reconnectionAttempts) =====")
        
        // Clean up current session first
        await cleanup()
        
        // Wait before reconnecting
        let delay = UInt64(self.reconnectionAttempts) * 1_000_000_000 // 1, 2, 3 seconds
        self.log("⏳ Waiting \(self.reconnectionAttempts) seconds before reconnect...")
        try? await Task.sleep(nanoseconds: delay)
        
        // Attempt to restart SharePlay
        do {
            try await startSharePlay(roomID: roomID, gameID: gameID, roomName: lastRoomName)
            self.log("✅ Reconnection successful!")
            reconnectionAttempts = 0 // Reset on success
        } catch {
            self.log("❌ Reconnection failed: \(error)")
            
            if self.reconnectionAttempts < self.maxReconnectionAttempts {
                self.log("🔄 Will retry...")
                await attemptReconnection()
            } else {
                self.log("⛔ Max reconnection attempts reached")
                shouldAutoReconnect = false
                onSessionEnded?()
            }
        }
    }
    
    private func cleanup() async {
        self.logger.info("🧹 Cleaning up Chess SharePlay service")
        self.log("🧹 Cleaning up...")
        
        // Cancel message listener for this session
        messageListenerTask?.cancel()
        messageListenerTask = nil
        
        // Clear state but keep currentSession and messenger 
        // They will be replaced when a new session starts
        isActive = false
        participants = []
        
        // Clear subscriptions after a brief delay to let any pending events finish
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            subscriptions.removeAll()
            self.logger.info("✅ Cleanup complete")
            self.log("✅ Cleanup complete")
        }
        
        self.logger.info("✅ Cleanup initiated")
        self.log("✅ Cleanup initiated")
    }
}

// MARK: - Errors
public enum ChessSharePlayError: Error {
    case sharePlayDisabled
    case userCancelled
    case noActiveSession
    case activationFailed
}
