# Testing Guide

## Running Tests

### All Tests
```bash
swift test
```

### Specific Test Suite
```bash
swift test --filter UserTests
swift test --filter RoomTests
swift test --filter RoomServiceTests
```

### With Verbose Output
```bash
swift test --verbose
```

## Test Structure

### Model Tests (`Tests/Models/`)
- `UserTests.swift` - User model validation
- `RoomTests.swift` - Room management and roles
- `TexasHoldemTests.swift` - Game models and cards

### Service Tests (`Tests/Services/`)
- `RoomServiceTests.swift` - Room CRUD operations
- `TexasHoldemServiceTests.swift` - Game logic and state

### ViewModel Tests (`Tests/ViewModels/`)
- `RoomListViewModelTests.swift` - Room list management
- `TexasHoldemViewModelTests.swift` - Game UI logic

## Test Coverage

Current coverage areas:

✅ **Models**
- User initialization and properties
- Room participant management
- Room host/sub-host functionality
- Playing cards and game state
- Codable conformance

✅ **Services**
- Room creation and deletion
- Join/leave room functionality
- Host/sub-host promotion
- Game initialization
- Betting and game actions
- Phase progression

✅ **ViewModels**
- Room list loading
- Room creation from UI
- Game state management
- Error handling

## Writing New Tests

### Example Test
```swift
import Testing
@testable import Layover

@Suite("My Feature Tests")
struct MyFeatureTests {
    
    @Test("Test description")
    func testSomething() async throws {
        // Arrange
        let service = MyService()
        
        // Act
        let result = try await service.doSomething()
        
        // Assert
        #expect(result.isValid)
    }
}
```

### Testing Async Code
```swift
@Test("Async operation")
func testAsync() async throws {
    let viewModel = MyViewModel()
    await viewModel.loadData()
    #expect(viewModel.data.isEmpty == false)
}
```

### Testing Errors
```swift
@Test("Error handling")
func testError() async {
    let service = MyService()
    await #expect(throws: MyError.self) {
        try await service.failingOperation()
    }
}
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: swift test
```

### Xcode Cloud
Configure in App Store Connect with:
- Scheme: Layover
- Action: Test
- Platform: iOS, macOS, tvOS, visionOS

## Best Practices

1. **Test Isolation** - Each test should be independent
2. **Arrange-Act-Assert** - Clear test structure
3. **Meaningful Names** - Descriptive test function names
4. **Fast Tests** - Mock external dependencies
5. **Comprehensive Coverage** - Test edge cases
6. **@MainActor** - Use for ViewModels and Services that need it

## Mocking

### Example Mock Service
```swift
final class MockRoomService: RoomServiceProtocol {
    var rooms: [Room] = []
    var createRoomCalled = false
    
    func createRoom(name: String, hostID: UUID, activityType: RoomActivityType) async throws -> Room {
        createRoomCalled = true
        let room = Room(name: name, hostID: hostID, activityType: activityType)
        rooms.append(room)
        return room
    }
    
    // Implement other protocol methods...
}
```

### Using Mocks in Tests
```swift
@Test("ViewModel uses service")
func testViewModelWithMock() async {
    let mockService = MockRoomService()
    let viewModel = RoomListViewModel(roomService: mockService)
    
    await viewModel.createRoom(name: "Test", hostID: UUID(), activityType: .appleTVPlus)
    
    #expect(mockService.createRoomCalled)
}
```

## Performance Testing

### Example
```swift
@Test("Performance test")
func testPerformance() async throws {
    let service = TexasHoldemService()
    let roomID = UUID()
    let players = Array(repeating: UUID(), count: 10)
    
    // Measure time
    let start = Date()
    _ = try await service.startGame(roomID: roomID, players: players)
    let duration = Date().timeIntervalSince(start)
    
    #expect(duration < 1.0) // Should complete in under 1 second
}
```

## Debug Tips

### Print Test Output
```swift
@Test("Debug test")
func testWithDebug() {
    let value = calculateSomething()
    print("Debug value: \(value)")
    #expect(value > 0)
}
```

### Conditional Tests
```swift
@Test("iOS only test")
@available(iOS 17.0, *)
func testIOSFeature() {
    // iOS-specific test
}
```

## Test Data Helpers

### Example Factory
```swift
extension Room {
    static func testRoom(activityType: RoomActivityType = .appleTVPlus) -> Room {
        Room(
            name: "Test Room",
            hostID: UUID(),
            activityType: activityType
        )
    }
}

// Usage in tests
@Test("Using test factory")
func testWithFactory() {
    let room = Room.testRoom(activityType: .texasHoldem)
    #expect(room.activityType == .texasHoldem)
}
```

## Continuous Improvement

Regular test maintenance:
- Review test coverage weekly
- Add tests for new features
- Update tests when fixing bugs
- Remove obsolete tests
- Refactor duplicated test code
