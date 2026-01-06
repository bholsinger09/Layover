# Layover - Quick Start Guide

## What is Layover?

Layover is a multi-platform SwiftUI app that enables synchronized group experiences across:
- 📺 Apple TV+ (watching shows and movies together)
- 🎵 Apple Music (listening to music together)
- ♟️ Games (Chess)

Built with SharePlay API and AVPlaybackCoordinator for seamless synchronization.

## Quick Start

### 1. Sign In with Apple
When you launch the app:
- Tap the **Sign in with Apple** button
- Authenticate with Face ID, Touch ID, or password
- Review and confirm the information being shared
- Your session will be securely stored

### 2. Open in Xcode
```bash
cd /Users/benh/Documents/Layover
open Package.swift
```

### 3. Select Your Platform
- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- visionOS 1.0+

### 4. Run Tests
Press `⌘U` or run:
```bash
swift test
```

### 4. Build and Run
Press `⌘R` or run:
```bash
swift build
```

## Key Features

### ✅ Room Management
- Create rooms with different activity types
- Host and sub-host roles
- Multiple concurrent rooms
- Join/leave functionality

### ✅ SharePlay Integration
- Automatic session management
- AVPlaybackCoordinator for media sync
- Group activity coordination

### ✅ Apple TV+ Integration
- Synchronized video playback
- Play/pause/seek controls
- Content selection

### ✅ Apple Music Integration
- Synchronized music playback
- MusicKit authorization
- Song/album/playlist support

### ✅ Chess
- 2 player turn-based game
- All standard chess piece movements
- AI opponent support
- SharePlay multiplayer

### ✅ Test Coverage
- 50+ unit tests
- Model, Service, and ViewModel tests
- Test-driven development approach

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│                   Views                      │
│  (SwiftUI - ContentView, RoomViews, etc.)   │
└──────────────────┬──────────────────────────┘
                   │ observes
┌──────────────────▼──────────────────────────┐
│              ViewModels                      │
│   (@Observable - RoomListVM, GameVM, etc.)  │
└──────────────────┬──────────────────────────┘
                   │ uses
┌──────────────────▼──────────────────────────┐
│               Services                       │
│  (SharePlay, Room, Media, Game Services)    │
└──────────────────┬──────────────────────────┘
                   │ operates on
┌──────────────────▼──────────────────────────┐
│                Models                        │
│    (User, Room, MediaContent, Game)         │
└─────────────────────────────────────────────┘
```

## Testing SharePlay

SharePlay requires specific setup:

1. **Two Physical Devices** (simulator not supported)
2. **Active FaceTime Call** between devices
3. **Same Apple ID** (for testing)
4. **Same Network** (Wi-Fi)

### Test Flow:
1. Start FaceTime call between devices
2. Open Layover on both devices
3. Create a room on device 1
4. Join room on device 2
5. SharePlay session starts automatically
6. Actions sync across devices

## Customization

### Adding New Activity Types

1. **Add to RoomActivityType enum:**
```swift
enum RoomActivityType: String, Codable, Sendable {
    case myNewActivity = "my_activity"
}
```

2. **Create Service:**
```swift
protocol MyActivityServiceProtocol: LayoverService {
    // Define methods
}
```

3. **Create ViewModel:**
```swift
@Observable
final class MyActivityViewModel: LayoverViewModel {
    // Implement logic
}
```

4. **Create View:**
```swift
struct MyActivityView: View {
    // Build UI
}
```

### Adding New Game Logic

1. Create model in `Sources/Models/`
2. Create service in `Sources/Services/`
3. Write tests in `Tests/`
4. Create ViewModel and View
5. Add to ContentView routing

## Project Structure

```
Layover/
├── Package.swift              # Swift Package definition
├── README.md                  # Project overview
├── DEVELOPMENT.md            # Detailed developer guide
├── QUICKSTART.md             # This file
├── setup.sh                  # Setup script
│
├── Sources/
│   ├── LayoverApp.swift      # App entry point
│   │
│   ├── Models/               # Data models
│   │   ├── User.swift
│   │   ├── Room.swift
│   │   ├── MediaContent.swift
│   │   ├── ChessGame.swift
│   │   └── LayoverActivity.swift
│   │
│   ├── Services/             # Business logic
│   │   ├── SharePlayService.swift
│   │   ├── RoomService.swift
│   │   ├── AppleTVService.swift
│   │   ├── AppleMusicService.swift
│   │   └── ChessService.swift
│   │
│   ├── ViewModels/           # MVVM ViewModels
│   │   ├── RoomListViewModel.swift
│   │   ├── AppleTVViewModel.swift
│   │   ├── AppleMusicViewModel.swift
│   │   └── ChessViewModel.swift
│   │
│   └── Views/                # SwiftUI Views
│       ├── ContentView.swift
│       ├── RoomRowView.swift
│       ├── CreateRoomView.swift
│       ├── AppleTVView.swift
│       ├── AppleMusicView.swift
│       └── ChessView.swift
│
├── Tests/                    # Unit tests
│   ├── Models/
│   ├── Services/
│   └── ViewModels/
│
└── Resources/                # Configuration
    ├── Info.plist
    └── Layover.entitlements
```

## Common Commands

### Build
```bash
swift build
```

### Test
```bash
swift test
```

### Clean
```bash
swift package clean
```

### Update Dependencies
```bash
swift package update
```

### Generate Xcode Project (if needed)
```bash
swift package generate-xcodeproj
```

## Documentation

- 📖 [API Reference](API.md) - Complete API documentation
- 🛠 [Development Guide](DEVELOPMENT.md) - Detailed developer information
- ✅ [Testing Guide](TESTING.md) - Testing practices and examples
- 🧹 [Clean Code Standards](CLEAN_CODE.md) - Code quality guidelines
- 📋 [Setup Guide](XCODE_SETUP.md) - Xcode-specific setup

## Troubleshooting

### "No such module 'GroupActivities'"
- Ensure you're building for iOS 17+, macOS 14+, tvOS 17+, or visionOS 1+
- Check target deployment settings

### "SharePlay not available"
- SharePlay only works on physical devices
- Requires active FaceTime call
- Check entitlements are configured

### "Music authorization failed"
- Check Info.plist has NSAppleMusicUsageDescription
- Ensure user has Apple Music subscription
- Request authorization before playing

### Build errors
- Clean build: `swift package clean`
- Check Xcode version is 15.0+
- Verify all dependencies are resolved

## Next Steps

1. ✅ Explore the codebase
2. ✅ Run the tests (`swift test`)
3. ✅ Build the app (`swift build`)
4. ✅ Try creating a room
5. ✅ Test SharePlay with two devices
6. ✅ Customize for your needs

## Resources

- [SharePlay Documentation](https://developer.apple.com/documentation/groupactivities)
- [AVPlaybackCoordinator](https://developer.apple.com/documentation/avfoundation/avplaybackcoordinator)
- [MusicKit](https://developer.apple.com/documentation/musickit)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)

## Support

For issues or questions:
1. Check DEVELOPMENT.md for detailed documentation
2. Review test files for usage examples
3. Consult Apple's official documentation

---

**Built with ❤️ using SwiftUI, SharePlay, and MVVM**
