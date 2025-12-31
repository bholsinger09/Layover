# SharePlay Host/Guest Role Fix

## Problem Identified

Both devices (Mac and iPhone) were showing as "Host" when one should be "Guest". This happened because the role detection logic was flawed.

### Previous Logic (Broken)
```swift
// In handleSession():
if isHost {
    // Keep as host
} else {
    isHost = false  // Already false, redundant
}
```

This didn't properly distinguish between:
- Device that **initiated** the SharePlay session (Host)
- Device that **joined** the SharePlay session (Guest)

## Solution Implemented

Added a new flag `didInitiateActivity` to track which device actually called `startActivity()`:

### New Logic (Fixed)
```swift
// Track if WE called startActivity()
private var didInitiateActivity: Bool = false

// In startActivity():
didInitiateActivity = true  // Mark that we initiated

// In handleSession():
if didInitiateActivity {
    isHost = true   // We started it, we're the host
} else {
    isHost = false  // We're joining, we're a guest
}
```

## How It Works Now

### Host Device (iPhone in your case):
1. User taps "Start SharePlay" button
2. Calls `startActivity()` which sets `didInitiateActivity = true`
3. iOS activates SharePlay and creates a session
4. Session observer triggers `handleSession()`
5. Checks `didInitiateActivity` → true → sets `isHost = true`
6. Shows "🏠 Host" in blue

### Guest Device (Mac in your case):
1. Receives SharePlay notification via FaceTime
2. User taps "Join" on the notification
3. Session observer triggers `handleSession()`
4. Checks `didInitiateActivity` → false (never called startActivity)
5. Sets `isHost = false`
6. Shows "👤 Guest" in purple

## Testing Steps

### Fresh Test (Recommended)

1. **Close the app completely on BOTH devices**
   - Double-click Home button (iPhone) or swipe up (newer iPhones)
   - Swipe up to close the app
   - On Mac: Cmd+Q to quit completely

2. **Restart FaceTime call**
   - Start fresh FaceTime call between Mac and iPhone
   - Wait for call to fully connect

3. **iPhone (becomes Host):**
   - Open Layover app
   - Navigate to Texas Hold'em room
   - Tap "Start SharePlay"
   - Confirm SharePlay in the dialog
   - Should see: "SharePlay Active • Host" in blue
   - Should see: "🏠 Host" indicator

4. **Mac (becomes Guest):**
   - Should see SharePlay notification pop up
   - Tap "Join" on the notification
   - App should open to Texas Hold'em view
   - Should see: "SharePlay Active • Guest" in purple
   - Should see: "👤 Guest" indicator

5. **Test Ping:**
   - iPhone: Tap "Ping Guest" → should send "Hello guest"
   - Mac: Should receive message and auto-respond "Hello host"
   - Mac: Tap "Ping Host" → should send "Hello host"
   - iPhone: Should receive message and auto-respond "Hello guest"

## What Changed

### Files Modified:
- [TexasHoldemSharePlayService.swift](Sources/Services/TexasHoldemSharePlayService.swift)

### Key Changes:
1. Added `didInitiateActivity: Bool` flag to track who initiated
2. Set `didInitiateActivity = true` in `startActivity()`
3. Updated `handleSession()` to check `didInitiateActivity` instead of `isHost`
4. Reset `didInitiateActivity = false` in `leaveSession()`

## Troubleshooting

### If Both Still Show as Host:
- Make sure you completely closed and reopened the apps
- The old session might still be active
- Try: Settings > FaceTime > SharePlay > Clear All Sessions (if available)
- Restart both devices if needed

### If Neither Shows Correct Role:
- Check Console logs for "didInitiateActivity" messages
- Verify the device that tapped "Start SharePlay" logs: "🏠 Marked as activity initiator"
- Verify the other device logs: "👥 This device is JOINING - Setting GUEST role"

### If Roles Seem Random:
- Only ONE device should tap "Start SharePlay"
- The other device should ONLY tap "Join" on the notification
- Don't tap "Start SharePlay" on both devices

## Expected Console Output

### Host Device (initiated SharePlay):
```
🎬 ===== STARTING SHAREPLAY ACTIVITY =====
   🏠 Marked as activity initiator (will become host)
📋 Preparation result: activationPreferred
✅ Activity activated!
🎉 SHAREPLAY SESSION RECEIVED!
   ⚠️ Did we initiate activity?: true
   ✅ This device INITIATED the activity - setting HOST role
   🏠 This device INITIATED the activity - Setting HOST role
```

### Guest Device (joined SharePlay):
```
🎉 SHAREPLAY SESSION RECEIVED!
   ⚠️ Did we initiate activity?: false
   ✅ This device is JOINING an existing session - setting GUEST role
   👥 This device is JOINING - Setting GUEST role
```

## Notes

- The participant count showing "3 connected" in your screenshot is suspicious
- This might indicate multiple sessions or duplicate participants
- After applying this fix, you should see correct participant counts
- Each real device should count as 1 participant
- With 2 devices (Mac + iPhone), you should see "2 connected"

If you still see "3 connected" after the fix, there may be:
1. An extra duplicate participant being added
2. Multiple SharePlay sessions running simultaneously
3. An issue with how participants are being counted

Let me know if the roles are correct after testing with this fix!
