# SharePlay Usage Guide for Texas Hold'em

## Overview
SharePlay allows multiple players to sync their Texas Hold'em game state in real-time during a FaceTime call, even if they're using different Apple IDs.

## How to Use SharePlay

### Prerequisites
1. Both players must be in an active FaceTime call
2. Both devices must have the LayoverLounge app installed
3. Both players must join the same room

### Step-by-Step Instructions

#### On the Host Device (iPhone or Mac):
1. **Start a FaceTime call** with the other player
2. **Open LayoverLounge** and navigate to a Texas Hold'em room
3. **Tap "Start SharePlay"** button (purple button with SharePlay icon)
4. **Approve the SharePlay request** when iOS/macOS prompts you
5. Wait for "SharePlay Active" indicator to appear
6. **Tap "Start Game"** to begin the chess game

#### On the Participant Device (iPhone or Mac):
1. **Stay in the FaceTime call**
2. **Watch for SharePlay banner** in FaceTime saying "[Name] started Texas Hold'em"
3. **Tap "Join"** on the SharePlay banner in FaceTime
4. **Open LayoverLounge** (if not already open)
5. **Navigate to the same room** as the host
6. Game will automatically sync when host starts it

### Key Features

- **Cross Apple ID Support**: Works with different Apple IDs via SharePlay
- **Real-time Sync**: All game actions sync instantly between devices
- **Automatic Game Start**: Participants automatically receive game state when host starts
- **Turn-based Play**: Shows whose turn it is on both devices
- **Community Cards**: All cards sync across devices

### Troubleshooting

**SharePlay banner not appearing?**
- Make sure you're in an active FaceTime call (video must be connected)
- Check that GroupActivities permission is enabled in Settings
- Try ending and restarting the FaceTime call

**Game not syncing?**
- Verify "SharePlay Active" indicator is showing on both devices
- Make sure both players are in the same room
- Check that the host tapped "Start SharePlay" before starting the game

**Only seeing 1 player?**
- This is normal - SharePlay participant count may not update immediately
- The game will still work correctly with 2 players
- Tap "Detect Players" if needed to manually refresh

### Technical Details

**SharePlay Session Flow:**
1. Host activates `ChessActivity` via `GroupActivitySharingController`
2. FaceTime displays join banner to all call participants
3. Participants tap "Join" to join the GroupSession
4. Host starts game, broadcasts `gameStarted` message
5. All participants receive game state updates in real-time
6. Player actions are broadcast via SharePlay messages

**Messages Sent:**
- `gameStarted`: Initial game setup with player IDs
- `gameStateUpdate`: Full game state after each action
- `playerAction`: Individual player actions (bet, fold, call)
- `phaseAdvanced`: When game moves to next phase (flop, turn, river)

### Why Not iCloud?
iCloud Key-Value Store only syncs between devices with the **same Apple ID**, making it unsuitable for multiplayer with different users. SharePlay solves this by syncing via the FaceTime GroupSession.

