# Guest Mode Implementation

## Apple App Review Compliance - Guideline 5.1.1

### Issue
The app previously required users to register or log in before accessing any features, violating Apple's guideline that apps must allow access to features that are not account-based without requiring registration.

### Solution
Implemented a **Guest Mode** that allows users to freely explore and use non-account-based features without signing in.

## Implementation Details

### Features Available Without Sign-In (Guest Mode)

Users can now access the following features without creating an account:

1. **Music Library Browser** - Browse and explore the media library
2. **Music Player** - Play songs from the local library
3. **Music Import** - Upload MP3 files or add YouTube URLs
4. **App Exploration** - View all app features and interface

### Features Requiring Sign-In (Account-Based)

The following features require user authentication as they depend on user identity and sync:

1. **SharePlay Sessions** - Real-time synchronized group experiences (requires user identity for session management)
2. **Profile Management** - User profile and account settings
3. **Cloud Sync** - Syncing playlists and preferences across devices
4. **Saved Playlists** - Creating and saving personal playlists (future feature)

### User Experience Flow

#### Guest Mode Indicators
- **Top Navigation**: Shows "Sign In" button instead of username when in guest mode
- **Guest Banner** (iOS): Compact banner at top informing users they're browsing as guest with quick sign-in option
- **Guest Banner** (tvOS/macOS): Prominent banner explaining guest mode with sign-in button
- **Feature Prompts**: When attempting to access account-based features (SharePlay), user is prompted to sign in

#### Sign-In Triggers
Users are only prompted to sign in when they:
1. Tap the "Sign In" button in the top navigation
2. Attempt to join a SharePlay session
3. Try to access their profile

#### Seamless Transition
- Guest users can explore the app fully before deciding to sign in
- Sign-in is presented as a modal sheet that can be dismissed
- After successful sign-in, users retain their position in the app
- All previously available features remain accessible

## Platform Coverage

This implementation works across all platforms:
- **iOS** (iPhone & iPad)
- **macOS**
- **tvOS** (Apple TV)

## Code Changes

### Main Changes in ContentView.swift
1. Added `guestUser` computed property for default guest access
2. Added `isGuestMode` flag to track authentication state
3. Modified all profile buttons to show "Sign In" for guests
4. Updated SharePlay buttons to prompt for sign-in instead of directly launching
5. Added guest mode banners with sign-in option
6. Changed app flow from requiring authentication to allowing guest access by default
7. Added automatic sheet dismissal when sign-in succeeds

## Compliance Statement

This implementation fully addresses Apple's App Review guideline 5.1.1:
- ✅ Users can access non-account-based features without registration
- ✅ Music playback, browsing, and import work without an account
- ✅ Sign-in is only required for features that genuinely need user identity (SharePlay, Profile)
- ✅ Guest mode is clearly indicated to users
- ✅ Sign-in process is optional and user-initiated

## Testing Recommendations

To verify compliance:
1. Launch the app fresh (not signed in)
2. Verify you can access the Music Library
3. Verify you can browse and play music
4. Verify you can import music files
5. When tapping "Join Live Session", verify sign-in prompt appears
6. Verify sign-in is optional and dismissible
7. After signing in, verify all features work normally
