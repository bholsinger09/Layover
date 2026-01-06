# SharePlay Connection Guide - Texas Hold'em

## Overview
This guide explains how two users with different Apple IDs can connect via SharePlay in the Texas Hold'em view and test their connection by pinging each other.

## Prerequisites
1. **Two iOS devices** with different Apple IDs
2. **Active FaceTime call** between the two devices
3. **Layover app** installed on both devices
4. **SharePlay enabled** in FaceTime settings

## Setup Instructions

### Step 1: Start FaceTime Call
1. Device A calls Device B via FaceTime
2. Wait for the call to connect
3. Ensure both users can see and hear each other

### Step 2: Open Texas Hold'em Room
1. On both devices, open the Layover app
2. Navigate to a Texas Hold'em room (or create one)
3. Both users should enter the same room

### Step 3: Activate SharePlay

#### On the HOST Device (initiator):
1. In the Texas Hold'em view, tap the **"Start SharePlay"** button
2. iOS will show a SharePlay confirmation dialog
3. Tap **"SharePlay"** to confirm
4. You'll see a green indicator showing **"SharePlay Active • Host"**

#### On the GUEST Device (joiner):
1. An automatic notification will appear when the host starts SharePlay
2. Tap **"Join"** on the SharePlay notification
3. The app should automatically open to the Texas Hold'em view
4. You'll see a green indicator showing **"SharePlay Active • Guest"**

## Testing Connection

### Simple Ping Test

Once SharePlay is active on both devices, each user can ping the other:

#### As the Host:
1. Look for the **"Your Role: 🏠 Host"** indicator
2. Tap the **"Ping Guest"** button
3. The host will send a message: **"Hello guest"**
4. Wait for the guest's automatic response
5. You'll see:
   - 📤 Sent: Hello guest
   - 📥 Guest says: Hello host

#### As the Guest:
1. Look for the **"Your Role: 👤 Guest"** indicator
2. Tap the **"Ping Host"** button
3. The guest will send a message: **"Hello host"**
4. Wait for the host's automatic response
5. You'll see:
   - 📤 Sent: Hello host
   - 📥 Host says: Hello guest

### Advanced Diagnostics

For troubleshooting connection issues:

1. Tap **"Advanced Diagnostics"** button
2. This will show detailed information:
   - Device ID
   - Session ID and state
   - Participant count
   - Messenger status
   - Message listener status
   - Callback registration status

## Understanding the UI

### Status Indicators

| Indicator | Meaning |
|-----------|---------|
| 🟢 SharePlay Active | Connected via SharePlay |
| 🏠 Host | You initiated the SharePlay session |
| 👤 Guest | You joined someone else's SharePlay session |
| Participants: 2 | Number of connected devices (including you) |

### Ping Button States

| State | Meaning |
|-------|---------|
| Blue "Ping Guest" | You're the host, tap to ping guest |
| Purple "Ping Host" | You're the guest, tap to ping host |
| Gray/Disabled | Waiting for another participant |
| "Sending..." | Ping in progress |

### Response Messages

| Message | Meaning |
|---------|---------|
| 📤 Sent: Hello guest | You sent a ping to the guest |
| 📥 Host says: Hello guest | Host is greeting you |
| 📤 Replied: Hello host | You auto-replied to a ping |
| ✅ Guest responded! | Connection successful |
| ⏱️ No response | Other user didn't respond (check their connection) |

## Troubleshooting

### SharePlay Won't Activate

**Problem:** "SharePlay is disabled" message

**Solutions:**
- Ensure you're in an active FaceTime call
- Check Settings > FaceTime > SharePlay is enabled
- Try ending and restarting the FaceTime call
- Restart both devices

### Can't See Other Participant

**Problem:** "Waiting for another participant to join..."

**Solutions:**
- Guest needs to tap "Join" on the SharePlay notification
- Host should check if SharePlay invitation was sent
- Try re-starting SharePlay from the host device
- Both users should be on the same WiFi network if possible

### Ping Gets No Response

**Problem:** "No response" after pinging

**Solutions:**
1. Check both devices show "SharePlay Active"
2. Verify participant count shows "2" on both devices
3. Tap "Advanced Diagnostics" to check:
   - ✅ Message listener running
   - ✅ Messenger exists
   - Session State: joined
4. Try the other user pinging first
5. Restart SharePlay on both devices

### Different Session IDs

**Problem:** Devices show different Session IDs in diagnostics

**Solutions:**
- This means you're not in the same SharePlay session
- Guest should leave and rejoin
- Host should restart SharePlay
- Check that both are in the same FaceTime call

## Technical Details

### How It Works

1. **Host Initiates:** Creates a `ChessActivity` GroupActivity
2. **Session Creation:** iOS creates a GroupSession and shares it via FaceTime
3. **Guest Joins:** Receives notification and joins the same session
4. **Messaging:** Uses `GroupSessionMessenger` to send messages
5. **Ping/Pong Protocol:**
   - User A sends `testPing` with their role (host/guest) and greeting
   - User B receives `testPing` and auto-responds with `testPong`
   - User A receives `testPong` confirming connection

### Message Flow

```
Host Device                          Guest Device
    |                                      |
    |  1. User taps "Ping Guest"          |
    |  📤 testPing(from: "host",          |
    |     message: "Hello guest")         |
    |------------------------------------->|
    |                                      |  2. Receives ping
    |                                      |  📥 "Host says: Hello guest"
    |                                      |
    |                                      |  3. Auto-respond
    |  4. Receives pong                    |  📤 testPong(from: "guest",
    |  📥 "Guest says: Hello host"         |     message: "Hello host")
    |<-------------------------------------|
    |                                      |
    |  5. ✅ "Guest responded!"            |  6. ✅ "Connected to Host"
    |                                      |
```

### Key Classes

- **ChessActivity**: GroupActivity conformance for SharePlay
- **ChessSharePlayService**: Manages SharePlay session and messaging
- **ChessMessage**: Codable message types including `testPing` and `testPong`
- **ChessViewModel**: Handles UI callbacks and business logic

## Best Practices

1. **Start SharePlay First:** Always activate SharePlay before starting a game
2. **Test Connection:** Use the ping feature to verify connectivity before playing
3. **Same Room:** Ensure both users are in the same Texas Hold'em room
4. **Stable Connection:** Use WiFi instead of cellular when possible
5. **Up-to-Date iOS:** Keep both devices on the latest iOS version

## Playing Texas Hold'em After Connecting

Once you've verified the connection with a successful ping:

1. The host can tap **"Start Game"**
2. The game will automatically sync to the guest's device
3. Both players will see:
   - Their own cards (face up)
   - Opponent's cards (face down)
   - Community cards as they're dealt
   - Current pot and bets

4. Actions (bet, fold, call, check) sync automatically via SharePlay
5. The host controls dealing community cards
6. All game state updates broadcast to all participants

## Support

If you continue to have issues:
1. Check Console app for detailed logs (filter by "SharePlay" or "Chess")
2. Verify both devices are signed in with different Apple IDs
3. Test with a simpler SharePlay app first to verify FaceTime SharePlay works
4. File an issue with:
   - iOS version on both devices
   - Console logs from both devices
   - Screenshot of "Advanced Diagnostics" output
