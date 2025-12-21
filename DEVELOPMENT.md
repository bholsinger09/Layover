# Layover Development Guide

## Project Structure

```
Layover/
├── Sources/
│   ├── Models/              # Data models (User, Room, etc.)
│   ├── ViewModels/          # MVVM ViewModels
│   ├── Views/               # SwiftUI Views
│   ├── Services/            # Business logic services
│   └── LayoverApp.swift     # App entry point
├── Tests/
│   ├── Models/              # Model unit tests
│   ├── ViewModels/          # ViewModel unit tests
│   └── Services/            # Service unit tests
├── Resources/
│   ├── Info.plist
│   └── Layover.entitlements
└── Package.swift
```

## Architecture

### MVVM Pattern
- **Models**: Pure data structures (User, Room, MediaContent, TexasHoldemGame)
- **ViewModels**: Observable objects that manage business logic and state
- **Views**: SwiftUI views that observe ViewModels
- **Services**: Protocol-based services for SharePlay, rooms, media, and games

### Key Components

#### SharePlay Integration
- `SharePlayService`: Manages GroupSessions and AVPlaybackCoordinator
- `LayoverActivity`: GroupActivity for synchronized experiences
- Automatic coordination for video and audio playback

#### Room Management
- `RoomService`: Create, join, leave, and manage rooms
- Support for host and sub-host roles
- Multiple concurrent rooms with different activities

#### Activity Types
1. **Apple TV+**: Synchronized video playback with AVPlayerPlaybackCoordinator
2. **Apple Music**: Synchronized music playback with MusicKit
3. **Texas Hold'em**: Full poker game with betting, folding, and phases
4. **Chess**: Coming soon

## Testing

### Running Tests
```bash
swift test
```

### Test Coverage
- Model tests: User, Room, TexasHoldemGame, PlayingCard
- Service tests: RoomService, TexasHoldemService
- ViewModel tests: RoomListViewModel, TexasHoldemViewModel

## Platform Support

### iOS (17.0+)
- Full feature set
- Portrait and landscape orientations
- SharePlay support

### macOS (14.0+)
- Native Mac Catalyst app
- Full feature parity with iOS

### tvOS (17.0+)
- Optimized for Apple TV
- Focus-based navigation
- SharePlay for group viewing

### visionOS (1.0+)
- Spatial computing support
- Immersive SharePlay experiences
- 3D poker table (future enhancement)

## Configuration

### Entitlements Required
- `com.apple.developer.group-session`: SharePlay support
- `com.apple.developer.playable-content`: Media playback
- `com.apple.developer.music-kit`: Apple Music integration
- `com.apple.security.application-groups`: Shared data

### Info.plist Keys
- `NSGroupActivitiesUsageDescription`: SharePlay permission
- `NSAppleMusicUsageDescription`: Music access permission
- `NSCameraUsageDescription`: Video chat (future)
- `NSMicrophoneUsageDescription`: Voice chat (future)

## Building for Production

### 1. Configure Bundle Identifier
Update in Xcode project settings or Package.swift

### 2. Add Signing & Capabilities
- Enable App Groups
- Enable Group Activities
- Enable MusicKit

### 3. Test SharePlay
SharePlay requires:
- Two physical devices (simulator not supported)
- FaceTime call active
- Same Apple ID signed in

### 4. Submit to App Store
- Configure App Store Connect
- Add screenshots for all platforms
- Complete metadata and privacy information

## API Integration Notes

### Apple TV+ (Future)
- Currently uses placeholder URLs
- Integrate with Apple TV+ API when available
- Requires content licensing agreements

### Apple Music
- Uses MusicKit framework
- Requires user authorization
- Respects subscription status

### SharePlay
- Automatic session management
- AVPlaybackCoordinator for media sync
- Custom message passing for game state

## Future Enhancements

1. **Chess Implementation**: Complete chess game logic
2. **Video Chat**: Integrate AVKit for video calls
3. **Cloud Sync**: iCloud integration for cross-device state
4. **Notifications**: Push notifications for room invites
5. **Analytics**: Track usage and engagement
6. **Social Features**: Friend lists, achievements, leaderboards
7. **More Games**: Checkers, Blackjack, Trivia
8. **Content Discovery**: Browse Apple TV+ and Music catalog

## Troubleshooting

### SharePlay Not Working
- Verify entitlements are configured
- Check FaceTime call is active
- Ensure devices are on same network
- Test with physical devices (not simulator)

### Music Authorization Failed
- Check Info.plist has NSAppleMusicUsageDescription
- Verify Apple Music subscription is active
- Request authorization before playing

### Build Errors
- Clean build folder: Product > Clean Build Folder
- Update dependencies: File > Packages > Update to Latest Package Versions
- Verify Xcode version is 15.0+

## Contributing

This is a reference implementation. For production use:
1. Add proper error handling
2. Implement real backend services
3. Add comprehensive logging
4. Enhance UI/UX for each platform
5. Add accessibility features
6. Implement proper state persistence

## License

Copyright © 2025 - All Rights Reserved
