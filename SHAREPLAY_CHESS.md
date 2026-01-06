# Chess SharePlay Implementation

This document explains how Chess game synchronization works using SharePlay in the Layover app.

## Overview

The Chess feature enables two players to play a synchronized chess game over SharePlay. The game state is synchronized in real-time across all participants' devices.

## Core Components

### 1. **ChessActivity** ([ChessActivity.swift](Sources/Models/ChessActivity.swift))

- Conforms to `GroupActivity` protocol
- Unique identifier: `com.bholsinger.LayoverLounge.chess`
- Provides metadata for SharePlay UI

### 2. **ChessSharePlayService** ([ChessSharePlayService.swift](Sources/Services/ChessSharePlayService.swift))

Manages SharePlay session lifecycle:
- Session activation and monitoring
- Message passing between participants
- Participant tracking
- Automatic cleanup on session end

Key callbacks:
- `onSessionStarted`: Triggered when SharePlay session begins
- `onGameStateUpdate`: Receives full game state updates
- `onPlayerMove`: Receives individual move updates
- `onPlayerResign`: Notified when a player resigns

### 3. **Message Types** ([ChessActivity.swift](Sources/Models/ChessActivity.swift))

```swift
enum ChessMessage: Codable {
    case gameStarted(roomID: UUID, gameID: UUID, playerIDs: [UUID])
    case gameStateUpdate(ChessGameState)
    case playerMove(Move)
    case playerResign(playerID: UUID)
    case gameEnded(winnerID: UUID?, reason: String)
}
```

### 4. **Game State Synchronization** ([ChessGameState](Sources/Models/ChessActivity.swift))

The game state includes:
- Board configuration (8x8 grid of pieces)
- Current turn (white or black)
- Game state (active, check, checkmate, etc.)
- Captured pieces
- Move history

## SharePlay Flow

### Starting SharePlay

1. User taps "Start SharePlay" button in [ChessView](Sources/Views/ChessView.swift)
2. `ChessActivity` is activated via SharePlay API
3. System prompts user to share with FaceTime participants
4. Session is established and all participants join

### Game Synchronization

1. Host creates game and broadcasts initial state
2. All participants receive `gameStateUpdate` message
3. When a player makes a move:
   - Move is validated locally
   - Move is sent via `playerMove` message
   - All participants apply the move
   - Game state is updated on all devices

### Message Flow

```
Player 1 (White)                     Player 2 (Black)
     |                                     |
     |------- selectSquare(e2) ---------->|
     |                                     |
     |------- selectSquare(e4) ---------->|
     |                                     |
     |--- playerMove(e2->e4) ------------->|
     |                                     |
     |                                     |--- applies move locally
     |                                     |
     |<------ playerMove(e7->e5) ----------|
     |                                     |
     |--- applies move locally             |
```

## Integration

#### ViewModel Integration ([ChessViewModel.swift](Sources/ViewModels/ChessViewModel.swift))

```swift
let sharePlayService: ChessSharePlayService

// Setup callbacks
sharePlayService.onPlayerMove = { [weak self] move in
    await self?.handlePlayerMove(move)
}

// Send move to all participants
await sharePlayService.sendMessage(.playerMove(move))
```

#### View Integration ([ChessView.swift](Sources/Views/ChessView.swift))

```swift
// Start SharePlay button
Button("Start SharePlay") {
    Task {
        await viewModel.startSharePlay(room: room)
    }
}

// Board automatically updates when game state changes
// through @Observable property wrapper
```

## Game Rules

### Current Implementation

- Standard chess piece movement:
  - Pawns: Forward 1 square (2 on first move), diagonal capture
  - Knights: L-shape movement
  - Bishops: Diagonal movement
  - Rooks: Horizontal/vertical movement
  - Queens: Horizontal/vertical/diagonal movement
  - Kings: One square in any direction

### Future Enhancements

- En passant capture
- Castling
- Pawn promotion
- Stalemate detection
- Draw by repetition
- Chess notation export

## AI Opponent

The chess game includes a basic AI opponent ([ChessAIService.swift](Sources/Services/ChessAIService.swift)) that:
- Finds all valid moves for its color
- Selects a random valid move
- Can be enhanced with minimax or other algorithms

## Testing

### Testing SharePlay

SharePlay requires:
1. Two physical devices (simulator not supported for SharePlay)
2. Active FaceTime call between devices
3. Same app version on both devices
4. Both users in the same room

### Testing Without SharePlay

The game can be tested locally:
- Start a game without SharePlay
- Play against AI opponent
- Test move validation and game logic

## Error Handling

Common errors and handling:

| Error | Cause | Resolution |
|-------|-------|------------|
| `sharePlayDisabled` | SharePlay not available | Enable in Settings |
| `userCancelled` | User cancelled SharePlay prompt | Re-attempt activation |
| `noActiveSession` | No SharePlay session | Start SharePlay first |
| `invalidMove` | Illegal chess move | Validate before sending |
| `notYourTurn` | Move out of turn | Wait for opponent |

## Performance Considerations

- Game state is lightweight (< 5KB per message)
- Move validation is performed locally before sending
- Board updates are efficient using SwiftUI's diffing
- Session monitoring runs on background queue

## Security

- No sensitive data transmitted
- All moves validated locally and remotely
- Session is end-to-end encrypted by FaceTime
- No persistent storage of game data

## Debugging

Enable verbose logging:
```swift
// ChessSharePlayService logs all messages
print("📨 Message received: \(message)")
print("🎯 Player move: from (\(move.fromRow),\(move.fromCol)) to (\(move.toRow),\(move.toCol))")
```

Check SharePlay status:
```swift
print("Session active: \(sharePlayService.isActive)")
print("Participants: \(sharePlayService.participants.count)")
```

## Best Practices

1. **Always validate moves locally** before sending to prevent cheating
2. **Handle disconnections gracefully** - save game state
3. **Provide visual feedback** for opponent's moves
4. **Test thoroughly** with two physical devices
5. **Log all SharePlay events** for debugging

## Known Limitations

1. SharePlay requires FaceTime - no standalone multiplayer
2. Limited to 2 players per game
3. No game save/resume functionality yet
4. No spectator mode
5. No replay functionality

## Future Roadmap

- [ ] Advanced chess rules (castling, en passant)
- [ ] Game save/resume
- [ ] Move timer
- [ ] Chess notation display
- [ ] Game replay
- [ ] Spectator mode
- [ ] Multiple simultaneous games
- [ ] Chess engine integration for stronger AI
