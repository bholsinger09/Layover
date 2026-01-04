# Apple TV Simulator Limitations

## For Apple Reviewers and Testers

This document outlines the known limitations when testing Layover on the Apple TV Simulator versus physical Apple TV hardware.

## Critical Simulator Limitations

### 1. Apple ID Sign-In
**Limitation**: Apple ID sign-in does not persist properly in tvOS Simulator
- Users cannot stay signed into their Apple ID
- iCloud services are unavailable
- Causes "Default User" fallback in the app

**Impact**: 
- ❌ Cannot test SharePlay cross-device synchronization
- ❌ Cannot test Apple Music integration
- ❌ User preferences don't sync

**Workaround**: App falls back to "Default User" mode for simulator testing

### 2. SharePlay / GroupActivities
**Limitation**: SharePlay sessions cannot sync between Simulator and physical devices
- Requires both devices to be signed into the same Apple ID
- Simulator's Apple ID issues prevent session detection
- Cross-device GroupActivities is not supported in simulator

**Impact**:
- ❌ Cannot test SharePlay synchronization between devices
- ❌ Sessions started on physical iPhone won't appear in tvOS Simulator
- ✅ Can test SharePlay UI and single-device flow

**Workaround**: SharePlay features display appropriate messaging for simulator limitations

### 3. FaceTime
**Limitation**: FaceTime app is not available in tvOS/iOS Simulator
- Cannot launch FaceTime from simulator
- URL schemes (facetime://) return error -10814
- SharePlay requires active FaceTime call

**Impact**:
- ❌ Cannot start SharePlay sessions (requires FaceTime call)
- ❌ "Join FaceTime" button shows simulator-specific instructions
- ✅ UI gracefully handles unavailability

**Workaround**: App provides clear error messages and alternative instructions

## What CAN Be Tested in Simulator

### ✅ Fully Functional in Simulator:
1. **UI/UX Design**
   - All layouts and navigation
   - Platform-specific adaptations (iOS, macOS, tvOS)
   - Responsive design elements

2. **Room Management**
   - Creating rooms
   - Joining rooms
   - Viewing room lists
   - Editing room settings

3. **Content Browsing**
   - Library views
   - Content selection
   - Media metadata display

4. **Single-Device Features**
   - Texas Hold'em poker game
   - Local gameplay
   - User interface flows

5. **Error Handling**
   - Simulator-aware error messages
   - Graceful degradation
   - Clear user communication

## What REQUIRES Physical Devices

### ❌ Requires Physical Hardware:

1. **SharePlay Cross-Device Sync**
   - **Requirement**: Two physical devices (iPhone + Apple TV, or two iPhones)
   - **Setup**: Both in active FaceTime call
   - **Result**: Real-time session synchronization

2. **FaceTime Integration**
   - **Requirement**: Physical Apple TV 4K (2nd gen or later) or iPhone
   - **Setup**: tvOS 17+ or iOS 17+
   - **Result**: Launch FaceTime, start SharePlay

3. **Apple Music Integration**
   - **Requirement**: Valid Apple ID signed in
   - **Setup**: Apple Music subscription
   - **Result**: Real music playback with SharePlay

4. **iCloud Services**
   - **Requirement**: Persistent Apple ID sign-in
   - **Setup**: Physical device only
   - **Result**: Cross-device sync, preferences

## Recommended Testing Configuration

### For Complete Feature Testing:

#### Minimum Setup:
```
Device 1: iPhone (iOS 17+) with Apple ID A
Device 2: iPhone/iPad (iOS 17+) with Apple ID B
Connection: FaceTime call between devices
Test: SharePlay synchronization
```

#### Ideal Setup for Apple TV:
```
Device 1: iPhone (iOS 17+) with Apple ID A
Device 2: Apple TV 4K 2nd gen+ (tvOS 17+) with Apple ID B
Connection: FaceTime call active on iPhone
           Apple TV accesses SharePlay via same room
Test: Full Apple TV+ SharePlay experience
```

### For Simulator Testing:

#### What to Focus On:
```
✅ UI/UX polish and design
✅ Navigation flows
✅ Error message clarity
✅ Platform adaptations
✅ Room management
✅ Single-device gameplay
✅ Graceful degradation
```

## In-App Messaging

The app includes built-in messaging for simulator limitations:

### tvOS Simulator:
- Orange warning banner explaining limitations
- Bullet-pointed list of what won't work
- Guidance on physical device requirements
- Alternative testing instructions

### iOS Simulator:
- FaceTime launch failure messages
- Clear explanation of simulator constraints
- "Try Again" options for physical devices

## Apple Reviewer Guidance

When reviewing this app:

1. **Simulator Review**: Focus on UI, navigation, error handling
2. **Physical Device Review**: Test SharePlay between two devices
3. **Expected Behavior**: 
   - Simulator shows limitation warnings ✅
   - Physical devices enable full functionality ✅
   - App degrades gracefully ✅

## Technical Details

### Why These Limitations Exist:

**Apple ID Persistence**:
- Simulators use sandboxed environment
- No secure enclave for credentials
- iCloud services require device-specific keys

**SharePlay/GroupActivities**:
- Requires FaceTime infrastructure
- Depends on iCloud for session coordination
- Needs persistent Apple ID for participant identification

**FaceTime**:
- System app not included in simulator bundle
- Camera/microphone simulation limited
- Network stack doesn't support FaceTime protocols

## Version Compatibility

- **Layover**: v1.0
- **Minimum iOS**: 17.0
- **Minimum tvOS**: 17.0
- **Minimum macOS**: 14.0 (Sonoma)
- **Tested On**: 
  - Xcode 15+
  - iOS Simulator 17.0+
  - tvOS Simulator 17.0+
  - Physical iPhone 15 Pro
  - Physical Apple TV 4K (3rd gen)

## Contact

For questions about simulator testing or physical device requirements:
- Development Team: [Your Contact]
- Documentation: See SHAREPLAY_CONNECTION_GUIDE.md
- Testing Guide: See SIMULATOR_SHAREPLAY_TESTING.md

---

**Last Updated**: January 4, 2026  
**Document Version**: 1.0
