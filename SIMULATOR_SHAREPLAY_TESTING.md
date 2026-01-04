# SharePlay Testing with Simulator & Physical Device

## Overview
While you cannot launch FaceTime from the Apple TV simulator, you CAN test SharePlay functionality by combining the simulator with a physical iPhone/iPad.

## Setup Requirements

### 1. Same Apple ID
- Both your Mac (running simulator) and iPhone must be signed in with the **same Apple ID**
- Ensure iCloud is enabled on both devices

### 2. Network Configuration
- Connect both devices to the **same WiFi network**
- Ensure network allows Bonjour/mDNS traffic (for peer discovery)

### 3. App Installation
- **Simulator**: Run Layover in tvOS simulator
- **iPhone**: Install Layover on your physical iPhone (or use another SharePlay-enabled app)

## Testing Steps

### Method 1: Cross-Device SharePlay Testing

1. **Start FaceTime on iPhone**
   ```
   - Open FaceTime on your physical iPhone
   - Call another iPhone/Mac (can be a second device you own)
   - Establish active FaceTime call
   ```

2. **Launch Layover on Both Devices**
   ```
   - Keep FaceTime call active on iPhone
   - Open Layover app on iPhone
   - Open Layover app in tvOS Simulator
   - Both should be signed in with same Apple ID
   ```

3. **Initiate SharePlay**
   ```
   - On iPhone: Create or join a room
   - Tap "Start SharePlay" or select content
   - SharePlay banner should appear in FaceTime
   - Accept SharePlay on the other device in the call
   ```

4. **Observe Simulator**
   ```
   - The simulator should detect the SharePlay session
   - Shared rooms should appear automatically
   - SharePlay status banner should show "SharePlay Active"
   ```

### Method 2: Multi-Simulator Testing (Advanced)

1. **Run Multiple Simulators**
   ```bash
   # Terminal 1: Launch iPhone Simulator
   xcrun simctl boot "iPhone 15 Pro"
   
   # Terminal 2: Launch Apple TV Simulator
   xcrun simctl boot "Apple TV 4K (3rd generation)"
   ```

2. **Same Apple ID on Both**
   - Sign in with same Apple ID on both simulators
   - Note: This requires separate Xcode instances or using Simulator.app directly

3. **Test SharePlay Between Simulators**
   - Limited functionality (FaceTime still unavailable)
   - But can test GroupActivities framework behavior

## Debugging SharePlay Sessions

### Check GroupActivities Logs
```swift
// In your app, watch for these logs:
print("🔄 GroupSession state: \(session.state)")
print("📱 Active participants: \(session.activeParticipants.count)")
print("🎯 Session ID: \(session.id)")
```

### Verify Network Connectivity
```bash
# On Mac, check for Bonjour services
dns-sd -B _companion-link._tcp

# Verify devices on same network
arp -a
```

### Common Issues

**SharePlay Not Appearing:**
- ✅ Both devices on same Apple ID?
- ✅ Both on same WiFi network?
- ✅ FaceTime call is active?
- ✅ GroupActivities entitlement enabled?

**Session Not Syncing:**
- Check `com.apple.developer.group-session` entitlement
- Verify `NSGroupActivitiesUsageDescription` in Info.plist
- Ensure app is running in foreground on both devices

**Simulator Limitations:**
- FaceTime app: ❌ Not available
- GroupActivities framework: ✅ Available
- SharePlay detection: ✅ Works if FaceTime active on iPhone
- Peer discovery: ⚠️ May be limited

## Production Testing Recommendation

For full feature testing, deploy to:
- **Apple TV 4K (2nd gen or later)** running tvOS 17+
- **iPhone/iPad** running iOS 17+
- Ensure both devices have FaceTime enabled

## Code Example: Handling Simulator vs Device

```swift
#if targetEnvironment(simulator)
print("⚠️ Running in simulator - FaceTime won't launch directly")
print("💡 Start FaceTime on physical iPhone to test SharePlay")
#else
print("✅ Running on physical device - full FaceTime support")
#endif
```

## Additional Resources

- [Apple GroupActivities Documentation](https://developer.apple.com/documentation/groupactivities)
- [SharePlay Best Practices](https://developer.apple.com/documentation/avfoundation/media_playback/supporting_coordinated_media_playback)
- [Testing SharePlay in Development](https://developer.apple.com/videos/play/wwdc2021/10183/)

## Quick Start Command

```bash
# Build and run on both simulator and device
xcodebuild -scheme Layover -destination 'platform=tvOS Simulator,name=Apple TV 4K' &
xcodebuild -scheme Layover -destination 'platform=iOS,name=Your iPhone' &
```
