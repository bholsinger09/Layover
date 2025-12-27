# Texas Hold'em SharePlay Implementation

## Overview
This implementation provides a dedicated SharePlay GroupActivity specifically for Texas Hold'em poker to ensure proper game state synchronization across all devices in a FaceTime call.

## Architecture

### 1. **TexasHoldemActivity** ([TexasHoldemActivity.swift](Sources/Models/TexasHoldemActivity.swift))
- Custom `GroupActivity` conforming to Apple's SharePlay protocol
- Unique identifier: `com.bholsinger.LayoverLounge.texasholdem`
- Contains room and game metadata for session identification

### 2. **TexasHoldemSharePlayService** ([TexasHoldemSharePlayService.swift](Sources/Services/TexasHoldemSharePlayService.swift))
- Manages SharePlay sessions specifically for Texas Hold'em
- Handles message passing between participants
- Provides callbacks for game events:
  - `onGameStarted`: When a game begins
  - `onGameStateUpdate`: Full game state synchronization
  - `onPlayerAction`: Individual player actions (bet, fold, call, etc.)
  - `onPhaseAdvanced`: Game phase transitions (flop, turn, river, showdown)
  - `onGameEnded`: When game concludes

### 3. **Message Types** ([TexasHoldemActivity.swift](Sources/Models/TexasHoldemActivity.swift))
```swift
enum TexasHoldemMessage: Codable {
    case gameStarted(gameID: UUID, playerIDs: [UUID])
    case gameStateUpdate(TexasHoldemGameState)
    case playerAction(PlayerAction)
    case phaseAdvanced(GamePhase)
    case gameEnded(winnerID: UUID?)
}
```

### 4. **Game State Synchronization** ([TexasHoldemGameState](Sources/Models/TexasHoldemActivity.swift))
Broadcasts complete game state including:
- Current player index
- Pot and current bet amounts
- Community cards
- All player states (chips, bets, folded status)
- Player hands (hidden until showdown for privacy)

## How It Works

### Starting a SharePlay Session
1. User taps "Start SharePlay" button in [TexasHoldemView](Sources/Views/TexasHoldemView.swift)
2. `TexasHoldemActivity` is activated via SharePlay API
3. FaceTime participants receive join prompt
4. All devices join the same SharePlay session

### Game Synchronization Flow
1. **Host starts game**: `startGame()` called on one device
2. **Broadcast game start**: Message sent to all participants with player IDs
3. **All devices join**: Each device receives message and enters game view
4. **Action synchronization**: Every player action broadcasts to all devices:
   - Bet/raise/call/check/fold
   - Phase transitions (flop, turn, river, showdown)
5. **State updates**: Full game state broadcast after each action

### Implementation Details

#### ViewModel Integration ([TexasHoldemViewModel.swift](Sources/ViewModels/TexasHoldemViewModel.swift))
```swift
// Integrated SharePlay service
let sharePlayService: TexasHoldemSharePlayService

// Setup callbacks in view lifecycle
func setupSharePlayCallbacks() {
    sharePlayService.onGameStarted = { ... }
    sharePlayService.onGameStateUpdate = { ... }
    sharePlayService.onPlayerAction = { ... }
}

// Broadcast actions to all participants
func bet(playerID: UUID, amount: Int) async {
    try await gameService.bet(playerID: playerID, amount: amount)
    
    // Sync with SharePlay participants
    await sharePlayService.sendMessage(.playerAction(.bet(...)))
    await broadcastGameState()
}
```

#### View Integration ([TexasHoldemView.swift](Sources/Views/TexasHoldemView.swift))
```swift
.task {
    // Setup SharePlay callbacks when view appears
    viewModel.setupSharePlayCallbacks()
}

// Start SharePlay button
Button {
    await viewModel.startSharePlay(roomID: room.id, roomName: room.name)
}
```

## Privacy Features
- **Card Privacy**: Opponent cards are hidden (card backs shown) until showdown phase
- **Selective Broadcasting**: Only reveals cards when appropriate (showdown)
- **Per-Device Perspective**: Each player sees their own cards clearly

## Testing Instructions

### Multi-Device Testing
1. **Setup**: Two devices (iPhone + Mac) on same Apple ID, connected via FaceTime
2. **Join Room**: Both devices navigate to same gaming room
3. **Start SharePlay**: Either device taps "Start SharePlay" button
4. **Join Prompt**: Other device receives FaceTime SharePlay join notification
5. **Auto-Start**: Game auto-starts when 2+ participants detected
6. **Play Together**: All actions sync in real-time across devices

### Expected Behavior
- ✅ Both devices show identical game state
- ✅ Turn indicators show current player
- ✅ Actions on one device immediately appear on other
- ✅ Phase transitions sync (flop, turn, river, showdown)
- ✅ Pot and chip counts update simultaneously
- ✅ Opponent cards hidden until showdown

## Benefits Over Generic SharePlay

### Before (Generic LayoverActivity):
- ❌ Used same activity for all room types
- ❌ No game-specific state synchronization
- ❌ Manual participant tracking required
- ❌ Race conditions when starting game

### After (Dedicated TexasHoldemActivity):
- ✅ Dedicated activity identifier for poker
- ✅ Automatic game state broadcasting
- ✅ Reliable message passing for all actions
- ✅ Coordinated game start across devices
- ✅ Turn-based synchronization
- ✅ Privacy-preserving card visibility

## Files Modified/Created

### Created:
- `Sources/Models/TexasHoldemActivity.swift` - SharePlay activity and messages
- `Sources/Services/TexasHoldemSharePlayService.swift` - SharePlay session management
- `SHAREPLAY_TEXAS_HOLDEM.md` - This documentation

### Modified:
- `Sources/ViewModels/TexasHoldemViewModel.swift` - Added SharePlay integration
- `Sources/Views/TexasHoldemView.swift` - Updated to use dedicated SharePlay service

## Troubleshooting

### Issue: Devices not syncing
**Solution**: Ensure both devices:
- Are signed into same Apple ID
- Have active FaceTime call
- Both joined SharePlay session (check for join prompt)

### Issue: Game not auto-starting on second device
**Solution**: 
- Verify SharePlay session is active (`isSessionActive == true`)
- Check participant count is 2+
- Review console logs for message delivery

### Issue: Card state not updating
**Solution**:
- Verify `broadcastGameState()` called after each action
- Check message delivery in console logs
- Ensure `applyGameState()` updates all properties

## Next Steps
- Add reconnection handling for dropped connections
- Implement game state persistence across sessions
- Add spectator mode for additional FaceTime participants
- Improve error handling for network issues
