# Layover API Reference

## Authentication

### AuthenticationService
Handles Sign in with Apple authentication.

```swift
protocol AuthenticationServiceProtocol: Sendable {
    var currentUser: User? { get async }
    var isAuthenticated: Bool { get async }
    
    func signInWithApple() async throws -> User
    func signOut() async throws
}
```

**Methods:**
- `signInWithApple()`: Initiates Sign in with Apple flow
- `signOut()`: Signs out the current user
- `checkCredentialState(for:)`: Validates user credentials

**Errors:**
- `AuthenticationError.invalidCredential`: Invalid credential from Apple
- `AuthenticationError.userCanceled`: User canceled sign in
- `AuthenticationError.authorizationFailed`: Authorization failed
- `AuthenticationError.invalidResponse`: Invalid response from Apple

### AuthenticationViewModel
ViewModel for authentication UI.

```swift
@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var isLoading: Bool
    @Published private(set) var errorMessage: String?
    
    func signInWithApple() async
    func signOut() async
    func checkCredentialState() async
}
```

---

## Models

### User
Represents a user in the Layover app.

```swift
struct User: LayoverModel {
    let id: UUID
    var appleUserID: String?
    var username: String
    var email: String?
    var avatarURL: URL?
    var isHost: Bool
    var isSubHost: Bool
}
```

**Properties:**
- `id`: Unique identifier
- `appleUserID`: Apple user identifier from Sign in with Apple
- `username`: Display name
- `email`: Optional email address
- `avatarURL`: Optional avatar image URL
- `isHost`: Whether user is a room host
- `isSubHost`: Whether user is a sub-host

---

### Room
Represents a room where users participate in activities.

```swift
struct Room: LayoverModel {
    let id: UUID
    var name: String
    var hostID: UUID
    var subHostIDs: Set<UUID>
    var participantIDs: Set<UUID>
    var activityType: RoomActivityType
    var maxParticipants: Int
    var isPrivate: Bool
    var createdAt: Date
    var metadata: [String: String]
}
```

**Methods:**
- `addParticipant(_:)`: Add user to room
- `removeParticipant(_:)`: Remove user from room
- `promoteToSubHost(_:)`: Promote user to sub-host
- `demoteSubHost(_:)`: Demote sub-host to regular participant
- `isSubHost(userID:)`: Check if user is sub-host

---

### RoomActivityType
Types of activities available in rooms.

```swift
enum RoomActivityType: String, Codable, Sendable {
    case appleTVPlus = "tv_plus"
    case appleMusic = "music"
    case texasHoldem = "texas_holdem"
    case chess = "chess"
}
```

---

### MediaContent
Represents media content (movies, shows, songs).

```swift
struct MediaContent: LayoverModel {
    let id: UUID
    var title: String
    var contentID: String
    var artworkURL: URL?
    var duration: TimeInterval
    var mediaType: MediaType
}
```

**MediaType:**
```swift
enum MediaType: String, Codable, Sendable {
    case movie
    case tvShow
    case song
    case album
    case playlist
}
```

---

### TexasHoldemGame
Represents a Texas Hold'em poker game.

```swift
struct TexasHoldemGame: LayoverModel {
    let id: UUID
    var roomID: UUID
    var players: [TexasHoldemPlayer]
    var dealerIndex: Int
    var currentBet: Int
    var pot: Int
    var communityCards: [PlayingCard]
    var gamePhase: GamePhase
    var currentPlayerIndex: Int
}
```

**GamePhase:**
```swift
enum GamePhase: String, Codable, Sendable {
    case preFlop
    case flop
    case turn
    case river
    case showdown
    case ended
}
```

---

### PlayingCard
Represents a playing card.

```swift
struct PlayingCard: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let rank: Rank
    let suit: Suit
}
```

**Rank:**
```swift
enum Rank: String, Codable, CaseIterable {
    case two = "2", three = "3", four = "4", five = "5"
    case six = "6", seven = "7", eight = "8", nine = "9"
    case ten = "10", jack = "J", queen = "Q", king = "K", ace = "A"
    
    var value: Int { /* 2-11 */ }
}
```

**Suit:**
```swift
enum Suit: String, Codable, CaseIterable {
    case hearts = "♥️"
    case diamonds = "♦️"
    case clubs = "♣️"
    case spades = "♠️"
}
```

---

## Services

### SharePlayService
Manages SharePlay sessions and coordination.

```swift
@MainActor
protocol SharePlayServiceProtocol: LayoverService {
    var currentSession: GroupSession<LayoverActivity>? { get }
    var isSessionActive: Bool { get }
    
    func startActivity(_ activity: LayoverActivity) async throws
    func leaveSession() async
    func setupPlaybackCoordinator(player: AVPlayer) async throws
}
```

**Usage:**
```swift
let service = SharePlayService()

// Start SharePlay
let activity = LayoverActivity(
    roomID: roomID,
    activityType: .appleTVPlus,
    customMetadata: ["roomName": "Movie Night"]
)
try await service.startActivity(activity)

// Setup playback coordination
try await service.setupPlaybackCoordinator(player: avPlayer)

// Leave session
await service.leaveSession()
```

---

### RoomService
Manages room operations.

```swift
@MainActor
protocol RoomServiceProtocol: LayoverService {
    var rooms: [Room] { get }
    
    func createRoom(name: String, hostID: UUID, activityType: RoomActivityType) async throws -> Room
    func joinRoom(roomID: UUID, userID: UUID) async throws
    func leaveRoom(roomID: UUID, userID: UUID) async throws
    func promoteToSubHost(roomID: UUID, userID: UUID) async throws
    func demoteSubHost(roomID: UUID, userID: UUID) async throws
    func deleteRoom(roomID: UUID) async throws
    func fetchRooms() async throws -> [Room]
}
```

**Usage:**
```swift
let service = RoomService()

// Create room
let room = try await service.createRoom(
    name: "Game Night",
    hostID: userID,
    activityType: .texasHoldem
)

// Join room
try await service.joinRoom(roomID: room.id, userID: friendID)

// Promote to sub-host
try await service.promoteToSubHost(roomID: room.id, userID: friendID)
```

---

### AppleTVService
Manages Apple TV+ content playback.

```swift
@MainActor
protocol AppleTVServiceProtocol: LayoverService {
    var currentContent: MediaContent? { get }
    var player: AVPlayer? { get }
    
    func loadContent(_ content: MediaContent) async throws
    func play() async
    func pause() async
    func seek(to time: TimeInterval) async
}
```

**Usage:**
```swift
let service = AppleTVService()

// Load content
let content = MediaContent(
    title: "Sample Movie",
    contentID: "movie-123",
    duration: 7200,
    mediaType: .movie
)
try await service.loadContent(content)

// Control playback
await service.play()
await service.pause()
await service.seek(to: 600) // 10 minutes
```

---

### AppleMusicService
Manages Apple Music playback.

```swift
@MainActor
protocol AppleMusicServiceProtocol: LayoverService {
    var currentContent: MediaContent? { get }
    var isAuthorized: Bool { get async }
    
    func requestAuthorization() async throws
    func loadContent(_ content: MediaContent) async throws
    func play() async
    func pause() async
}
```

**Usage:**
```swift
let service = AppleMusicService()

// Request authorization
if !await service.isAuthorized {
    try await service.requestAuthorization()
}

// Load and play music
let song = MediaContent(
    title: "Sample Song",
    contentID: "song-456",
    duration: 240,
    mediaType: .song
)
try await service.loadContent(song)
await service.play()
```

---

### TexasHoldemService
Manages Texas Hold'em game logic.

```swift
@MainActor
protocol TexasHoldemServiceProtocol: LayoverService {
    var currentGame: TexasHoldemGame? { get }
    
    func startGame(roomID: UUID, players: [UUID]) async throws -> TexasHoldemGame
    func dealCards() async throws
    func bet(playerID: UUID, amount: Int) async throws
    func fold(playerID: UUID) async throws
    func call(playerID: UUID) async throws
    func raise(playerID: UUID, amount: Int) async throws
    func nextPhase() async throws
    func endGame() async
}
```

**Usage:**
```swift
let service = TexasHoldemService()

// Start game
let game = try await service.startGame(
    roomID: roomID,
    players: [player1ID, player2ID, player3ID]
)

// Deal cards
try await service.dealCards()

// Player actions
try await service.bet(playerID: player1ID, amount: 50)
try await service.call(playerID: player2ID)
try await service.raise(playerID: player3ID, amount: 50)
try await service.fold(playerID: player1ID)

// Progress game
try await service.nextPhase() // Pre-flop -> Flop
try await service.nextPhase() // Flop -> Turn
try await service.nextPhase() // Turn -> River
try await service.nextPhase() // River -> Showdown
```

---

## ViewModels

### RoomListViewModel
Manages room list and operations.

```swift
@MainActor
@Observable
final class RoomListViewModel: LayoverViewModel {
    private(set) var rooms: [Room]
    private(set) var isLoading: Bool
    private(set) var errorMessage: String?
    
    func loadRooms() async
    func createRoom(name: String, hostID: UUID, activityType: RoomActivityType) async
    func joinRoom(_ room: Room, userID: UUID) async
    func leaveRoom(_ room: Room, userID: UUID) async
    func deleteRoom(_ room: Room) async
}
```

**Usage in SwiftUI:**
```swift
struct MyView: View {
    @State private var viewModel = RoomListViewModel()
    
    var body: some View {
        List(viewModel.rooms) { room in
            Text(room.name)
        }
        .task {
            await viewModel.loadRooms()
        }
    }
}
```

---

### AppleTVViewModel
Manages Apple TV+ viewing experience.

```swift
@MainActor
@Observable
final class AppleTVViewModel: LayoverViewModel {
    private(set) var currentContent: MediaContent?
    private(set) var isPlaying: Bool
    private(set) var isLoading: Bool
    var player: AVPlayer?
    
    func loadContent(_ content: MediaContent) async
    func play() async
    func pause() async
    func seek(to time: TimeInterval) async
    func togglePlayPause() async
}
```

---

### AppleMusicViewModel
Manages Apple Music listening experience.

```swift
@MainActor
@Observable
final class AppleMusicViewModel: LayoverViewModel {
    private(set) var currentContent: MediaContent?
    private(set) var isPlaying: Bool
    private(set) var isAuthorized: Bool
    
    func requestAuthorization() async
    func loadContent(_ content: MediaContent) async
    func play() async
    func pause() async
    func togglePlayPause() async
}
```

---

### TexasHoldemViewModel
Manages Texas Hold'em game UI.

```swift
@MainActor
@Observable
final class TexasHoldemViewModel: LayoverViewModel {
    private(set) var currentGame: TexasHoldemGame?
    private(set) var isLoading: Bool
    var currentPhase: TexasHoldemGame.GamePhase { get }
    var pot: Int { get }
    var communityCards: [PlayingCard] { get }
    
    func startGame(roomID: UUID, players: [UUID]) async
    func bet(playerID: UUID, amount: Int) async
    func fold(playerID: UUID) async
    func call(playerID: UUID) async
    func raise(playerID: UUID, amount: Int) async
    func nextPhase() async
    func endGame() async
    func getPlayer(for userID: UUID) -> TexasHoldemPlayer?
}
```

---

## Error Types

### SharePlayError
```swift
enum SharePlayError: LocalizedError {
    case activationDisabled
    case cancelled
    case noActiveSession
    case unknown
}
```

### RoomError
```swift
enum RoomError: LocalizedError {
    case roomNotFound
    case roomFull
    case notAuthorized
}
```

### MediaError
```swift
enum MediaError: LocalizedError {
    case invalidURL
    case loadFailed
}
```

### MusicError
```swift
enum MusicError: LocalizedError {
    case notAuthorized
    case authorizationDenied
    case loadFailed
}
```

### GameError
```swift
enum GameError: LocalizedError {
    case noActiveGame
    case invalidPlayerCount
    case playerNotFound
    case insufficientChips
    case invalidMove
}
```

---

## Views

### ContentView
Main app navigation view.

```swift
struct ContentView: View
```

### RoomRowView
Displays a room in a list.

```swift
struct RoomRowView: View {
    let room: Room
}
```

### CreateRoomView
Sheet for creating new rooms.

```swift
struct CreateRoomView: View {
    let currentUser: User
    let onCreate: (String, RoomActivityType) async -> Void
}
```

### AppleTVView
Apple TV+ viewing interface.

```swift
struct AppleTVView: View {
    let room: Room
    let currentUser: User
}
```

### AppleMusicView
Apple Music listening interface.

```swift
struct AppleMusicView: View {
    let room: Room
    let currentUser: User
}
```

### TexasHoldemView
Texas Hold'em game interface.

```swift
struct TexasHoldemView: View {
    let room: Room
    let currentUser: User
}
```

### CardView
Playing card display component.

```swift
struct CardView: View {
    let card: PlayingCard
}
```

---

## Platform-Specific Features

### iOS
- All features supported
- SharePlay via FaceTime
- Portrait and landscape modes

### macOS
- All features supported
- Native Mac Catalyst
- Window management

### tvOS
- Optimized for Apple TV
- Focus-based navigation
- Remote control support

### visionOS
- Spatial computing support
- Immersive experiences
- Hand gesture controls

---

## Best Practices

### Service Injection
```swift
// In production, inject services
let viewModel = RoomListViewModel(
    roomService: productionRoomService,
    sharePlayService: productionSharePlayService
)

// In tests, inject mocks
let viewModel = RoomListViewModel(
    roomService: mockRoomService,
    sharePlayService: mockSharePlayService
)
```

### Error Handling
```swift
// Always handle errors
do {
    try await service.performAction()
} catch let error as RoomError {
    // Handle room-specific errors
    handleRoomError(error)
} catch {
    // Handle general errors
    handleGeneralError(error)
}
```

### Async/Await
```swift
// Use Task for async operations in sync contexts
Button("Create Room") {
    Task {
        await viewModel.createRoom(name: name, hostID: hostID, activityType: type)
    }
}
```

### @MainActor
```swift
// Services and ViewModels are @MainActor
@MainActor
func updateUI() {
    // Safe to update UI here
    viewModel.loadRooms()
}
```

---

## Extension Points

### Custom Activities
Extend with new activity types:

1. Add to `RoomActivityType`
2. Create service protocol
3. Implement service
4. Create ViewModel
5. Build View
6. Update ContentView routing

### Custom Game Logic
Add new games:

1. Create game model
2. Implement game service
3. Write comprehensive tests
4. Create game ViewModel
5. Build game View

### Backend Integration
Replace in-memory storage:

1. Implement network layer
2. Add persistence
3. Update services
4. Handle synchronization
5. Add offline support
