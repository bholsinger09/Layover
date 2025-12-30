import Foundation
import GroupActivities
import OSLog

/// Service for managing SharePlay sessions specifically for Texas Hold'em
@MainActor
@Observable
final class TexasHoldemSharePlayService {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "TexasHoldemSharePlay")
    
    private(set) var currentSession: GroupSession<TexasHoldemActivity>?
    private var messenger: GroupSessionMessenger?
    private var sessionTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?
    private var participantsTask: Task<Void, Never>?
    
    private(set) var participantCount: Int = 0
    private(set) var isSessionActive: Bool = false
    
    var isHost: Bool = false {
        didSet {
            print("🔄 isHost changed from \(oldValue) to \(isHost)")
            print("   Stack trace:")
            Thread.callStackSymbols.prefix(5).forEach { print("      \($0)") }
        }
    }
    
    // Unique identifier for this device
    private let deviceID = UUID()
    
    // Callbacks
    var onSessionActivated: (() -> Void)?
    var onGameStarted: ((UUID, UUID, [UUID]) -> Void)?
    var onGameStateUpdate: ((TexasHoldemGameState) -> Void)?
    var onPlayerAction: ((TexasHoldemMessage.PlayerAction) -> Void)?
    var onPhaseAdvanced: ((TexasHoldemMessage.GamePhase) -> Void)?
    var onGameEnded: ((UUID?) -> Void)?
    var onParticipantJoined: (() -> Void)?
    var onParticipantCountChanged: ((Int) -> Void)?
    var onTestPingReceived: ((String, String, UUID) -> Void)?
    var onTestPongReceived: ((String, String, UUID) -> Void)?
    
    init() {
        // Don't start observer here - will be started when callbacks are configured
        logger.info("🎯 TexasHoldemSharePlayService initialized")
    }
    
    func startObserving() {
        logger.info("🔍 Starting SharePlay session observer...")
        print("🔍 ===== STARTING SHAREPLAY OBSERVER =====")
        print("🔍 startObserving() called")
        setupSessionObserver()
        
        // Also check for existing sessions immediately
        Task {
            await checkForExistingSessions()
        }
    }
    
    private func checkForExistingSessions() async {
        print("🔎 Checking for existing SharePlay sessions...")
        
        // Get all active sessions
        let sessions = TexasHoldemActivity.sessions()
        
        // Check if there's already an active session
        var sessionCount = 0
        for await session in sessions {
            sessionCount += 1
            print("✨ Found existing SharePlay session #\(sessionCount)")
            print("   Session state: \(session.state)")
            await handleSession(session)
            // Only handle the first session
            break
        }
        
        if sessionCount == 0 {
            print("   No existing sessions found")
        }
        
        print("✅ Finished checking for existing sessions")
    }
    
    nonisolated deinit {
        // Tasks will be automatically cancelled when the actor is deallocated
    }
    
    private func setupSessionObserver() {
        print("👁️ ===== SETTING UP SESSION OBSERVER =====")
        sessionTask = Task {
            print("👁️ Session observer loop started - waiting for sessions...")
            var iterationCount = 0
            for await session in TexasHoldemActivity.sessions() {
                iterationCount += 1
                print("🔔 Session observer detected session #\(iterationCount)!")
                print("   Session ID: \(session.id)")
                print("   Session state: \(session.state)")
                await handleSession(session)
            }
            print("⚠️ Session observer loop ended")
        }
        print("✅ Session observer task created")
    }
    
    private func handleSession(_ session: GroupSession<TexasHoldemActivity>) async {
        logger.info("🃏 Texas Hold'em SharePlay: Session received")
        print("🎉 SHAREPLAY SESSION RECEIVED!")
        print("   Session ID: \(session.id)")
        print("   Session state: \(session.state)")
        print("   Active participants: \(session.activeParticipants.count)")
        print("   ⚠️ BEFORE ROLE CHECK - Current isHost value: \(isHost)")
        print("   ⚠️ BEFORE ROLE CHECK - Current session nil?: \(currentSession == nil)")
        
        // Determine host/guest role:
        // If we INITIATED the session (called startSharePlay), isHost will already be true
        // Otherwise, we're joining an existing session as a guest
        if isHost {
            logger.info("   Session was INITIATED by this device - confirming HOST role")
            print("   🏠 Session INITIATED by this device - Confirming HOST role (isHost stays true)")
        } else {
            logger.info("   Joining EXISTING session created by another device - setting GUEST role")
            print("   👥 Joining EXISTING session - Setting GUEST role (isHost = false)")
            isHost = false
        }
        
        currentSession = session
        isSessionActive = true
        messenger = GroupSessionMessenger(session: session)
        
        // Notify that session is now active
        print("📢 Calling onSessionActivated callback")
        onSessionActivated?()
        
        // Join the session
        print("🚪 Joining SharePlay session...")
        session.join()
        logger.info("✅ Texas Hold'em SharePlay: Joined session")
        print("✅ Successfully joined SharePlay session!")
        print("   Session is now active with \(session.activeParticipants.count) participants")
        
        // Start listening for messages
        print("👂 Setting up message listener...")
        setupMessageListener()
        
        // Monitor participant changes to re-broadcast state when new participants join
        setupParticipantMonitoring(session: session)
    }
    
    private func setupParticipantMonitoring(session: GroupSession<TexasHoldemActivity>) {
        participantsTask?.cancel()
        participantsTask = Task {
            var previousCount = session.activeParticipants.count
            print("👥 Monitoring participants - initial count: \(previousCount)")
            
            // Update stored count
            self.participantCount = previousCount
            
            // Notify initial count
            onParticipantCountChanged?(previousCount)
            
            for await participants in session.$activeParticipants.values {
                let currentCount = participants.count
                print("👥 Participant count changed: \(previousCount) -> \(currentCount)")
                
                // Update stored count
                self.participantCount = currentCount
                print("👥 SharePlay participant count changed to: \(self.participantCount)")
                
                // Notify of count change
                onParticipantCountChanged?(currentCount)
                
                // If a new participant joined (count increased), notify host to re-broadcast
                if currentCount > previousCount && isHost {
                    print("🆕 New participant joined - notifying host to re-broadcast state")
                    onParticipantJoined?()
                }
                
                previousCount = currentCount
            }
        }
    }
    
    private func setupMessageListener() {
        guard let messenger = messenger else {
            logger.warning("⚠️ Cannot setup message listener - messenger is nil")
            return
        }
        
        logger.info("👂 Setting up message listener for Texas Hold'em messages...")
        messageTask?.cancel()
        messageTask = Task {
            logger.info("🎧 Message listener task started - waiting for messages...")
            for await (message, _) in messenger.messages(of: TexasHoldemMessage.self) {
                logger.info("📬 Message received in listener!")
                await handleMessage(message)
            }
            logger.info("🛑 Message listener task ended")
        }
    }
    
    private func handleMessage(_ message: TexasHoldemMessage) async {
        logger.info("📨 Received Texas Hold'em message: \(String(describing: message))")
        print("📨 RECEIVED MESSAGE: \(String(describing: message))")
        print("   Is host: \(isHost)")
        print("   Session active: \(isSessionActive)")
        
        switch message {
        case .gameStarted(let roomID, let gameID, let playerIDs):
            print("   -> Calling onGameStarted callback")
            onGameStarted?(roomID, gameID, playerIDs)
            
        case .gameStateUpdate(let state):
            print("   -> Calling onGameStateUpdate callback")
            print("      Pot: $\(state.pot), CurrentBet: $\(state.currentBet)")
            print("      PlayerIndex: \(state.currentPlayerIndex)")
            print("      Players: \(state.playerStates.count)")
            for (i, player) in state.playerStates.enumerated() {
                print("      Player \(i): chips=$\(player.chips), bet=$\(player.currentBet)")
            }
            onGameStateUpdate?(state)
            
        case .playerAction(let action):
            print("   -> Calling onPlayerAction callback")
            onPlayerAction?(action)
            
        case .phaseAdvanced(let phase):
            print("   -> Calling onPhaseAdvanced callback")
            onPhaseAdvanced?(phase)
            
        case .gameEnded(let winnerID):
            print("   -> Calling onGameEnded callback")
            onGameEnded?(winnerID)
            
        case .testPing(let from, let message, let senderID):
            print("   -> Received testPing from \(from), senderID: \(senderID)")
            print("      My deviceID: \(deviceID)")
            
            // Ignore messages from ourselves
            if senderID == deviceID {
                print("      ⚠️ Ignoring own message")
                return
            }
            
            print("      ✅ Calling onTestPingReceived callback")
            print("      Message: \(message)")
            onTestPingReceived?(from, message, senderID)
            
        case .testPong(let from, let message, let senderID):
            print("   -> Received testPong from \(from), senderID: \(senderID)")
            print("      My deviceID: \(deviceID)")
            
            // Ignore messages from ourselves
            if senderID == deviceID {
                print("      ⚠️ Ignoring own message")
                return
            }
            
            print("      ✅ Calling onTestPongReceived callback")
            print("      Message: \(message)")
            onTestPongReceived?(from, message, senderID)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start a new Texas Hold'em SharePlay session
    func startActivity(roomID: UUID, gameID: UUID, roomName: String?) async throws {
        logger.info("🎬 Starting Texas Hold'em SharePlay activity")
        print("🎬 ===== STARTING SHAREPLAY ACTIVITY =====")
        print("   Room ID: \(roomID)")
        print("   Game ID: \(gameID)")
        print("   Room Name: \(roomName ?? "nil")")
        
        let activity = TexasHoldemActivity(
            roomID: roomID,
            gameID: gameID,
            roomName: roomName
        )
        
        isHost = true
        print("   🏠 Marked as host")
        
        print("📋 Preparing activity for activation...")
        let preparationResult = await activity.prepareForActivation()
        print("📋 Preparation result: \(preparationResult)")
        
        switch preparationResult {
        case .activationPreferred:
            print("✅ Activation preferred - proceeding to activate...")
            do {
                let result = try await activity.activate()
                logger.info("✅ Texas Hold'em activity activated successfully")
                print("🎉 Activity activated! Result: \(result)")
                print("   Waiting for session to be established...")
            } catch {
                logger.error("❌ Failed to activate Texas Hold'em activity: \(error.localizedDescription)")
                print("❌ Activation failed: \(error)")
                throw error
            }
            
        case .activationDisabled:
            logger.warning("⚠️ SharePlay is disabled")
            print("⚠️ SharePlay is DISABLED - not in FaceTime call?")
            throw TexasHoldemSharePlayError.sharePlayDisabled
            
        case .cancelled:
            logger.info("ℹ️ User cancelled SharePlay activation")
            print("ℹ️ User CANCELLED SharePlay activation")
            throw TexasHoldemSharePlayError.userCancelled
            
        @unknown default:
            logger.warning("⚠️ Unknown activation result")
            throw TexasHoldemSharePlayError.unknown
        }
    }
    
    /// Send a message to all participants
    func sendMessage(_ message: TexasHoldemMessage) async {
        guard let messenger = messenger else {
            logger.warning("⚠️ Cannot send message: no messenger available")
            print("⚠️ Cannot send message: no messenger available")
            print("   isSessionActive: \(isSessionActive)")
            print("   currentSession: \(currentSession != nil)")
            return
        }
        
        print("📤 SENDING MESSAGE: \(String(describing: message))")
        print("   Session active: \(isSessionActive)")
        print("   Is host: \(isHost)")
        print("   Participant count: \(participantCount)")
        
        do {
            try await messenger.send(message)
            logger.info("📤 Sent Texas Hold'em message: \(String(describing: message))")
            print("✅ Message sent successfully")
        } catch {
            logger.error("❌ Failed to send message: \(error.localizedDescription)")
            print("❌ Failed to send message: \(error.localizedDescription)")
        }
    }
    
    /// Leave the current SharePlay session
    func leaveSession() async {
        logger.info("👋 Leaving Texas Hold'em SharePlay session")
        
        messageTask?.cancel()
        messageTask = nil
        
        participantsTask?.cancel()
        participantsTask = nil
        
        currentSession?.leave()
        currentSession = nil
        messenger = nil
        isHost = false
    }
    
    /// Send a test ping message to verify connectivity
    func sendTestPing(from: String, message: String) async {
        print("📤 sendTestPing called - from: \(from), message: \(message), deviceID: \(deviceID)")
        await sendMessage(.testPing(from: from, message: message, senderID: deviceID))
        print("📤 sendTestPing message sent")
    }
    
    /// Send a test pong response message
    func sendTestPong(from: String, message: String) async {
        print("📤 sendTestPong called - from: \(from), message: \(message), deviceID: \(deviceID)")
        await sendMessage(.testPong(from: from, message: message, senderID: deviceID))
        print("📤 sendTestPong message sent")
    }
    
    /// Get detailed diagnostic information about the SharePlay session
    func getDiagnostics() -> [String: Any] {
        var diagnostics: [String: Any] = [:]
        
        diagnostics["deviceID"] = deviceID.uuidString
        diagnostics["isSessionActive"] = isSessionActive
        diagnostics["isHost"] = isHost
        diagnostics["participantCount"] = participantCount
        
        if let session = currentSession {
            diagnostics["sessionID"] = session.id.uuidString
            diagnostics["sessionState"] = "\(session.state)"
            diagnostics["activeParticipantCount"] = session.activeParticipants.count
            
            var participants: [[String: String]] = []
            for (index, participant) in session.activeParticipants.enumerated() {
                participants.append([
                    "index": "\(index)",
                    "id": "\(participant.id)"
                ])
            }
            diagnostics["activeParticipants"] = participants
        } else {
            diagnostics["sessionID"] = "nil"
            diagnostics["sessionState"] = "nil"
        }
        
        diagnostics["hasMessenger"] = messenger != nil
        diagnostics["hasSessionTask"] = sessionTask != nil
        diagnostics["hasMessageTask"] = messageTask != nil
        diagnostics["hasParticipantsTask"] = participantsTask != nil
        
        return diagnostics
    }
}

enum TexasHoldemSharePlayError: LocalizedError {
    case sharePlayDisabled
    case userCancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .sharePlayDisabled:
            return "SharePlay is disabled. Please enable it in Settings."
        case .userCancelled:
            return "SharePlay activation was cancelled."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
