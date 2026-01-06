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
    private var tasks = Set<Task<Void, Never>>()
    
    @Published public private(set) var isActive = false
    @Published public private(set) var isEligibleForGroupSession = false
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
            logger.info("🎯 ChessSharePlayService initialized")
            
            print("🎯 ===== CHESS SHAREPLAY SERVICE INIT =====")
            
            await startSessionMonitoring()
        }
    }
    
    deinit {
        print("🧹 ChessSharePlayService deinitialized")
        tasks.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
    
    private func startSessionMonitoring() async {
        logger.info("📡 Starting session monitoring...")
        
        let sessions = ChessActivity.sessions()
        
        print("📡 Chess sessions stream created")
        
        let task = Task { @MainActor in
            print("🔄 Starting to iterate over Chess sessions...")
            var sessionCount = 0
            for await session in sessions {
                sessionCount += 1
                logger.info("🎮 New Chess session received (count: \(sessionCount))")
                print("🎮 ===== NEW CHESS SESSION RECEIVED =====")
                print("   Session count: \(sessionCount)")
                print("   Session ID: \(session.id)")
                print("   Session state: \(String(describing: session.state))")
                
                await handleSession(session)
            }
            print("⚠️ Chess sessions loop ended unexpectedly")
        }
        
        tasks.insert(task)
        print("✅ Session monitoring task started")
    }
    
    private func handleSession(_ session: GroupSession<ChessActivity>) async {
        logger.info("🎮 Handling new Chess session: \(session.id)")
        print("🎮 ===== HANDLING SESSION =====")
        print("   ID: \(session.id)")
        print("   State: \(String(describing: session.state))")
        print("   Activity: \(session.activity.roomID)")
        
        currentSession = session
        isActive = true
        
        // Join the session
        print("🚪 Joining session...")
        session.join()
        logger.info("✅ Joined Chess session")
        print("✅ Session joined successfully")
        
        // Create messenger for this session
        print("📮 Creating messenger...")
        let newMessenger = GroupSessionMessenger(session: session)
        messenger = newMessenger
        logger.info("📮 Messenger created for Chess session")
        print("✅ Messenger created")
        
        // Monitor session state changes
        print("👁️ Setting up state monitoring...")
        session.$state
            .sink { [weak self] state in
                guard let self = self else { return }
                Task { @MainActor in
                    self.logger.info("📊 Session state changed to: \(String(describing: state))")
                    print("📊 Session state: \(state)")
                    
                    switch state {
                    case .waiting:
                        print("⏳ Session waiting...")
                    case .joined:
                        print("✅ Session joined - calling onSessionStarted callback")
                        self.onSessionStarted?()
                    case .invalidated(let reason):
                        print("❌ Session invalidated: \(reason)")
                        await self.cleanup()
                        self.onSessionEnded?()
                    @unknown default:
                        print("❓ Unknown session state")
                    }
                }
            }
            .store(in: &subscriptions)
        
        // Setup participant monitoring
        setupParticipantMonitoring(session: session)
        
        // Start listening for messages
        print("👂 Starting message listener...")
        await startMessageListener(messenger: newMessenger)
        print("✅ Setup complete for session \(session.id)")
    }
    
    private func setupParticipantMonitoring(session: GroupSession<ChessActivity>) {
        logger.info("👥 Setting up participant monitoring")
        print("👥 Setting up participant monitoring...")
        
        session.$activeParticipants
            .sink { [weak self] participants in
                guard let self = self else { return }
                Task { @MainActor in
                    self.logger.info("👥 Active participants changed: \(participants.count)")
                    print("👥 Participants updated: \(participants.count)")
                    
                    self.participants = participants.map { participant in
                        Participant(
                            id: participant.id,
                            name: nil
                        )
                    }
                    
                    for (index, participant) in participants.enumerated() {
                        print("   [\(index)] ID: \(participant.id)")
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func startMessageListener(messenger: GroupSessionMessenger) async {
        logger.info("📬 Starting message listener...")
        print("📬 Starting message listener...")
        
        let task = Task { @MainActor in
            print("🔄 Starting message iteration loop...")
            var messageCount = 0
            for await (message, _) in messenger.messages(of: ChessMessage.self) {
                messageCount += 1
                logger.info("📨 Received Chess message #\(messageCount)")
                print("📨 Message #\(messageCount) received")
                await handleMessage(message)
            }
            print("⚠️ Message listener loop ended")
        }
        
        tasks.insert(task)
        print("✅ Message listener task started")
    }
    
    private func handleMessage(_ message: ChessMessage) async {
        logger.info("📨 Handling Chess message: \(String(describing: message))")
        print("📨 Handling message type: \(String(describing: message))")
        
        switch message {
        case .gameStarted(let roomID, let gameID, let playerIDs):
            logger.info("🎮 Game started - Room: \(roomID), Game: \(gameID), Players: \(playerIDs.count)")
            print("🎮 Game started notification")
            
        case .gameStateUpdate(let state):
            logger.info("🔄 Game state update received for game: \(state.gameID)")
            print("🔄 Game state update")
            onGameStateUpdate?(state)
            
        case .playerMove(let move):
            logger.info("🎯 Player move: \(move.playerID) from (\(move.fromRow),\(move.fromCol)) to (\(move.toRow),\(move.toCol))")
            print("🎯 Player move received")
            onPlayerMove?(move)
            
        case .playerResign(let playerID):
            logger.info("🏳️ Player resigned: \(playerID)")
            print("🏳️ Player resigned")
            onPlayerResign?(playerID)
            
        case .gameEnded(let winnerID, let reason):
            logger.info("🏁 Game ended - Winner: \(String(describing: winnerID)), Reason: \(reason)")
            print("🏁 Game ended")
            
        case .testPing(let from, let message, let senderID):
            logger.info("🏓 Received ping from \(from): \(message) (ID: \(senderID))")
            print("🏓 PING: \(message)")
            
        case .testPong(let from, let message, let senderID):
            logger.info("🏓 Received pong from \(from): \(message) (ID: \(senderID))")
            print("🏓 PONG: \(message)")
        }
    }
    
    public func startSharePlay(roomID: UUID, gameID: UUID, roomName: String?) async throws {
        logger.info("🚀 Starting Chess SharePlay - Room: \(roomID), Game: \(gameID)")
        print("🚀 ===== STARTING CHESS SHAREPLAY =====")
        print("   Room ID: \(roomID)")
        print("   Game ID: \(gameID)")
        print("   Room name: \(roomName ?? "nil")")
        
        let activity = ChessActivity(
            roomID: roomID,
            gameID: gameID,
            roomName: roomName
        )
        
        print("📦 Chess activity created")
        print("   Activity ID: \(ChessActivity.activityIdentifier)")
        
        switch await activity.prepareForActivation() {
        case .activationPreferred:
            logger.info("✅ Activation preferred - activating...")
            print("✅ Activation preferred")
            
            do {
                _ = try await activity.activate()
                logger.info("🎉 Chess activity activated successfully")
                print("🎉 Activity activated!")
            } catch {
                logger.error("❌ Failed to activate: \(error.localizedDescription)")
                print("❌ Activation failed: \(error)")
                throw error
            }
            
        case .activationDisabled:
            logger.warning("⚠️ SharePlay is disabled")
            print("⚠️ SharePlay disabled")
            throw ChessSharePlayError.sharePlayDisabled
            
        case .cancelled:
            logger.warning("⚠️ User cancelled")
            print("⚠️ User cancelled")
            throw ChessSharePlayError.userCancelled
            
        @unknown default:
            logger.error("❌ Unknown activation result")
            print("❌ Unknown activation result")
            throw ChessSharePlayError.unknown
        }
    }
    
    public func sendMessage(_ message: ChessMessage) async {
        guard let messenger = messenger else {
            logger.warning("⚠️ No messenger available to send message")
            print("⚠️ Cannot send message - no messenger")
            return
        }
        
        do {
            logger.info("📤 Sending Chess message: \(String(describing: message))")
            print("📤 Sending message...")
            try await messenger.send(message)
            logger.info("✅ Message sent successfully")
            print("✅ Message sent")
        } catch {
            logger.error("❌ Failed to send message: \(error.localizedDescription)")
            print("❌ Send failed: \(error)")
        }
    }
    
    public func endSession() async {
        logger.info("🛑 Ending Chess SharePlay session")
        print("🛑 Ending session...")
        
        currentSession?.end()
        await cleanup()
        
        logger.info("✅ Session ended")
        print("✅ Session ended")
    }
    
    private func cleanup() async {
        logger.info("🧹 Cleaning up Chess SharePlay service")
        print("🧹 Cleaning up...")
        
        currentSession = nil
        messenger = nil
        isActive = false
        participants = []
        
        subscriptions.removeAll()
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        
        logger.info("✅ Cleanup complete")
        print("✅ Cleanup complete")
    }
}

public enum ChessSharePlayError: LocalizedError {
    case sharePlayDisabled
    case userCancelled
    case noActiveSession
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .sharePlayDisabled:
            return "SharePlay is disabled. Please enable it in Settings."
        case .userCancelled:
            return "SharePlay activation was cancelled."
        case .noActiveSession:
            return "No active SharePlay session."
        case .unknown:
            return "An unknown error occurred with SharePlay."
        }
    }
}
