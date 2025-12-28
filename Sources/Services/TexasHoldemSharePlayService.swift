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
    
    var isHost: Bool = false
    
    // Callbacks
    var onGameStarted: ((UUID, UUID, [UUID]) -> Void)?
    var onGameStateUpdate: ((TexasHoldemGameState) -> Void)?
    var onPlayerAction: ((TexasHoldemMessage.PlayerAction) -> Void)?
    var onPhaseAdvanced: ((TexasHoldemMessage.GamePhase) -> Void)?
    var onGameEnded: ((UUID?) -> Void)?
    var onParticipantJoined: (() -> Void)?
    var onParticipantCountChanged: ((Int) -> Void)?
    
    init() {
        // Don't start observer here - will be started when callbacks are configured
        logger.info("🎯 TexasHoldemSharePlayService initialized")
    }
    
    func startObserving() {
        logger.info("🔍 Starting SharePlay session observer...")
        setupSessionObserver()
        
        // Also check for existing sessions immediately
        Task {
            await checkForExistingSessions()
        }
    }
    
    private func checkForExistingSessions() async {
        logger.info("🔎 Checking for existing SharePlay sessions...")
        
        // Get all active sessions
        let sessions = TexasHoldemActivity.sessions()
        
        // Check if there's already an active session
        for await session in sessions {
            logger.info("✨ Found existing SharePlay session!")
            await handleSession(session)
            // Only handle the first session
            break
        }
        
        logger.info("✅ Finished checking for existing sessions")
    }
    
    nonisolated deinit {
        // Tasks will be automatically cancelled when the actor is deallocated
    }
    
    private func setupSessionObserver() {
        sessionTask = Task {
            for await session in TexasHoldemActivity.sessions() {
                await handleSession(session)
            }
        }
    }
    
    private func handleSession(_ session: GroupSession<TexasHoldemActivity>) async {
        logger.info("🃏 Texas Hold'em SharePlay: Session received")
        
        // Only mark as participant if we didn't initiate the session
        // If isHost is already true, we started this session, so keep it true
        if currentSession == nil && !isHost {
            logger.info("   Joining existing Texas Hold'em session as participant")
        } else if isHost {
            logger.info("   Confirming host role for session we initiated")
        }
        
        currentSession = session
        isSessionActive = true
        messenger = GroupSessionMessenger(session: session)
        
        // Join the session
        session.join()
        logger.info("✅ Texas Hold'em SharePlay: Joined session")
        
        // Start listening for messages
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
        
        switch message {
        case .gameStarted(let roomID, let gameID, let playerIDs):
            onGameStarted?(roomID, gameID, playerIDs)
            
        case .gameStateUpdate(let state):
            onGameStateUpdate?(state)
            
        case .playerAction(let action):
            onPlayerAction?(action)
            
        case .phaseAdvanced(let phase):
            onPhaseAdvanced?(phase)
            
        case .gameEnded(let winnerID):
            onGameEnded?(winnerID)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start a new Texas Hold'em SharePlay session
    func startActivity(roomID: UUID, gameID: UUID, roomName: String?) async throws {
        logger.info("🎬 Starting Texas Hold'em SharePlay activity")
        
        let activity = TexasHoldemActivity(
            roomID: roomID,
            gameID: gameID,
            roomName: roomName
        )
        
        isHost = true
        
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            do {
                _ = try await activity.activate()
                logger.info("✅ Texas Hold'em activity activated successfully")
            } catch {
                logger.error("❌ Failed to activate Texas Hold'em activity: \(error.localizedDescription)")
                throw error
            }
            
        case .activationDisabled:
            logger.warning("⚠️ SharePlay is disabled")
            throw TexasHoldemSharePlayError.sharePlayDisabled
            
        case .cancelled:
            logger.info("ℹ️ User cancelled SharePlay activation")
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
            return
        }
        
        do {
            try await messenger.send(message)
            logger.info("📤 Sent Texas Hold'em message: \(String(describing: message))")
        } catch {
            logger.error("❌ Failed to send message: \(error.localizedDescription)")
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
