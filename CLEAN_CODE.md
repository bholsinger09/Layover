# Clean Code Standards

This document outlines the clean code principles followed in the Layover project.

## Logging Standards

### Use OSLog Instead of Print
- **Why**: OSLog provides structured logging with levels, categories, and better performance
- **Never use**: `print()` statements in production code
- **Always use**: `Logger` with appropriate subsystems and categories

```swift
// ✅ Good
import OSLog

@MainActor
final class MyService {
    private let logger = Logger(subsystem: "com.bholsinger.LayoverLounge", category: "MyService")
    
    func doSomething() {
        logger.info("Operation started")
        logger.debug("Debug information: \(details)")
        logger.error("Error occurred: \(error.localizedDescription)")
    }
}

// ❌ Bad
func doSomething() {
    print("Operation started")
    print("Error: \(error)")
}
```

### Logging Levels
- `logger.info()` - General information about app flow
- `logger.debug()` - Detailed debugging information
- `logger.warning()` - Potential issues that don't prevent execution
- `logger.error()` - Errors that need attention

## Constants

### Extract Magic Numbers and Strings
- **Why**: Improves readability, maintainability, and reduces duplication
- **Where**: Create dedicated constants enums near their usage

```swift
// ✅ Good
enum RoomConstants {
    static let defaultMaxParticipants = 20
    static let minParticipants = 2
    static let maxPossibleParticipants = 100
}

struct Room {
    var maxParticipants: Int = RoomConstants.defaultMaxParticipants
}

// ❌ Bad
struct Room {
    var maxParticipants: Int = 20  // Magic number
}
```

## Code Organization

### MVVM Architecture
- **Models**: Pure data structures in `Sources/Models/`
- **ViewModels**: Observable objects with `@MainActor` in `Sources/ViewModels/`
- **Views**: SwiftUI views in `Sources/Views/`
- **Services**: Protocol-based business logic in `Sources/Services/`

### Protocol-Oriented Design
```swift
// ✅ Good - Testable with protocol
protocol RoomServiceProtocol: LayoverService {
    func createRoom(name: String, host: User, activityType: RoomActivityType) async throws -> Room
}

final class RoomService: RoomServiceProtocol {
    // Implementation
}

// In tests, inject mock
let viewModel = RoomListViewModel(
    roomService: mockRoomService,
    sharePlayService: mockSharePlayService
)
```

## Naming Conventions

### Clear and Descriptive
- **Functions**: Verb phrases (`createRoom`, `startSharePlay`, `loadContent`)
- **Properties**: Noun phrases (`currentUser`, `isLoading`, `rooms`)
- **Booleans**: Use `is`, `has`, `can` prefixes (`isActive`, `hasPermission`, `canJoin`)

### Avoid Abbreviations
```swift
// ✅ Good
var currentUser: User
var participantCount: Int

// ❌ Bad
var currUsr: User
var pCount: Int
```

## Error Handling

### Use Typed Errors
```swift
// ✅ Good
enum RoomError: LocalizedError {
    case roomNotFound
    case insufficientPermissions
    case maxParticipantsReached
    
    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            return "Room not found"
        case .insufficientPermissions:
            return "Insufficient permissions to perform this action"
        case .maxParticipantsReached:
            return "Room has reached maximum participant capacity"
        }
    }
}
```

### Always Handle Errors Gracefully
```swift
// ✅ Good
do {
    try await service.performAction()
} catch let error as RoomError {
    logger.error("Room error: \(error.localizedDescription)")
    errorMessage = error.localizedDescription
} catch {
    logger.error("Unexpected error: \(error.localizedDescription)")
    errorMessage = "An unexpected error occurred"
}

// ❌ Bad
try? await service.performAction()  // Silently fails
```

## Function Length

### Keep Functions Small and Focused
- **Ideal**: Under 20 lines
- **Maximum**: 50 lines
- **Principle**: Single Responsibility Principle

```swift
// ✅ Good - Single responsibility
func createRoom(name: String, host: User, activityType: RoomActivityType) async {
    isLoading = true
    defer { isLoading = false }
    
    do {
        let room = try await roomService.createRoom(name: name, host: host, activityType: activityType)
        rooms.append(room)
        await shareRoomViaSharePlay(room)
    } catch {
        handleRoomCreationError(error)
    }
}

private func shareRoomViaSharePlay(_ room: Room) async {
    logger.info("📤 SharePlay: Sharing room '\(room.name)' with participants")
    await sharePlayService.shareRoom(room)
}

private func handleRoomCreationError(_ error: Error) {
    logger.error("Failed to create room: \(error.localizedDescription)")
    errorMessage = error.localizedDescription
}
```

## Comments and Documentation

### Document Public APIs
```swift
/// Creates a new room with the specified parameters
/// - Parameters:
///   - name: The name of the room
///   - host: The user who will host the room
///   - activityType: The type of activity for this room
/// - Returns: The newly created room
/// - Throws: `RoomError.invalidName` if the name is empty
func createRoom(name: String, host: User, activityType: RoomActivityType) async throws -> Room
```

### Avoid Obvious Comments
```swift
// ❌ Bad
// Set isLoading to true
isLoading = true

// ✅ Good - Code is self-documenting
isLoading = true
```

## Testing Standards

### Follow Arrange-Act-Assert
```swift
@Test("Create room adds it to the list")
func testCreateRoom() async throws {
    // Arrange
    let service = RoomService()
    let host = User(username: "TestHost")
    
    // Act
    let room = try await service.createRoom(
        name: "Test Room",
        host: host,
        activityType: .appleTVPlus
    )
    
    // Assert
    #expect(room.name == "Test Room")
    #expect(service.rooms.count == 1)
}
```

### Test Names Should Be Descriptive
```swift
// ✅ Good
@Test("Joining full room throws max participants error")
@Test("Host leaving room deletes it")
@Test("SharePlay state synchronizes across platforms")

// ❌ Bad
@Test("Test 1")
@Test("Join room test")
```

## Async/Await Best Practices

### Use Structured Concurrency
```swift
// ✅ Good
func loadData() async {
    async let rooms = roomService.fetchRooms()
    async let users = userService.fetchUsers()
    
    self.rooms = await rooms
    self.users = await users
}

// ❌ Bad
func loadData() async {
    self.rooms = await roomService.fetchRooms()  // Sequential, slower
    self.users = await userService.fetchUsers()
}
```

### Proper MainActor Isolation
```swift
// ✅ Good - Service and ViewModel are MainActor isolated
@MainActor
protocol RoomServiceProtocol: LayoverService { }

@MainActor
final class RoomListViewModel: LayoverViewModel { }
```

## Code Duplication

### DRY Principle (Don't Repeat Yourself)
- Extract common code into helper methods
- Use protocols for shared behavior
- Create extensions for reusable functionality

## Observer Pattern

### Support Multiple Observers
```swift
// ✅ Good - Multiple observers supported
protocol SharePlayServiceProtocol {
    func addSessionStateObserver(_ observer: @escaping (Bool) -> Void)
}

private var sessionStateObservers: [(Bool) -> Void] = []

func addSessionStateObserver(_ observer: @escaping (Bool) -> Void) {
    sessionStateObservers.append(observer)
    observer(isSessionActive)  // Immediate callback with current state
}

// ❌ Bad - Only one observer allowed
var onSessionStateChanged: ((Bool) -> Void)?
```

## Performance Considerations

### Avoid Premature Optimization
- Write clean, readable code first
- Profile before optimizing
- Use Instruments to identify bottlenecks

### Lazy Loading When Appropriate
```swift
// ✅ Good for expensive operations
lazy var expensiveResource: ExpensiveType = {
    return ExpensiveType()
}()
```

## Summary

Following these clean code principles ensures:
- ✅ Maintainable and readable codebase
- ✅ Easy to test and debug
- ✅ Consistent coding style across the project
- ✅ Better collaboration between developers
- ✅ Reduced bugs and issues
- ✅ Professional production-ready code
