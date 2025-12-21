# Running Layover in Xcode Simulator

Since Swift Packages are libraries and don't have app targets by default, you need to create an iOS app project to run on the simulator.

## Method 1: Create iOS App Project (Recommended)

1. **Open Xcode**

2. **Create New Project**
   - File → New → Project (⇧⌘N)
   - Select **iOS** tab → **App**
   - Click **Next**

3. **Configure Project**
   - Product Name: `LayoverApp`
   - Team: Select your team
   - Organization Identifier: `com.yourname.layover`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Click **Next**

4. **Save Location**
   - Choose `/Users/benh/Documents/LayoverApp` (different from Layover package)
   - Click **Create**

5. **Add LayoverKit Package**
   - File → Add Package Dependencies
   - Click **Add Local...**
   - Navigate to `/Users/benh/Documents/Layover`
   - Click **Add Package**
   - Select **LayoverKit** library
   - Click **Add Package**

6. **Update App Code**
   - Open `LayoverAppApp.swift` (the @main file)
   - Add `import LayoverKit` at the top
   - The ContentView will automatically use LayoverKit's ContentView

7. **Update Info.plist** (if needed)
   - Add required capabilities in Signing & Capabilities:
     - Sign in with Apple
     - Group Activities (SharePlay)

8. **Run**
   - Select iPhone simulator (e.g., iPhone 15 Pro)
   - Press ⌘R to run
   - You should see the Sign in with Apple screen!

## Method 2: Add App Target to Existing Package

Alternatively, you can add an app target directly to the package:

1. In Xcode with Package.swift open
2. File → New → Target
3. Select **iOS** → **App**
4. Add LayoverKit as a dependency

## Testing Sign in with Apple

Note: Sign in with Apple requires:
- A development team configured in Xcode
- The app to be run on a real device OR
- An Apple ID signed in to the simulator

For testing in the simulator:
1. Open **Simulator** app
2. Go to **Settings** → **Apple ID**
3. Sign in with your Apple ID
4. Then run the app

## Preview in Xcode

You can also preview individual views:
1. Open any view file (e.g., `SignInView.swift`)
2. Click **Resume** in the preview canvas (or ⌥⌘P)
3. The preview will show the view without running the full app
