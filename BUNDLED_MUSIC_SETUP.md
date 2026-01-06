# How to Add Music Files to Your App

Follow these steps to bundle music files directly into your Layover app:

## Step 1: Copy Music Files to Resources/Music

1. Copy some of your downloaded Apple Music files (from `~/Music/Music/Media.localized/Apple Music`)
2. Paste them into `/Users/benh/Documents/Layover/Resources/Music/`

You can organize them however you like:
```
Resources/Music/
  ├── Gabriela Bee/
  │   └── Ob-La-Di, Ob-La-Da - Single/
  │       └── 01 Ob-La-Di, Ob-La-Da.m4p
  ├── Christina Aguilera/
  │   └── Christina Aguilera/
  │       └── 01 Genie in a Bottle.m4p
  └── ...
```

Or just flat:
```
Resources/Music/
  ├── Song1.m4p
  ├── Song2.m4a
  └── Song3.mp3
```

## Step 2: Add Files to Xcode

1. Open `Layover.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), find the `Resources` folder
3. Right-click on `Resources` → **"Add Files to Layover..."**
4. Navigate to `/Users/benh/Documents/Layover/Resources/Music`
5. Select all your music files
6. **Important**: Check these options:
   - ✅ "Copy items if needed"
   - ✅ "Create groups" (not folder references)
   - ✅ Add to targets: LayoverKit, Layover, LayoverAppleTv, LayoverMac, LayoverTV
7. Click **Add**

## Step 3: Verify in Xcode

1. In Xcode, expand the `Resources` folder
2. You should see a `Music` folder with your files
3. Click on your project name at the top of the navigator
4. Select the `LayoverKit` target
5. Go to **Build Phases** → **Copy Bundle Resources**
6. Verify your music files are listed there

## Step 4: Test in App

1. Build and run the app (on any platform including Apple TV!)
2. Go to **My Library** → **Music** tab
3. Tap **Local Music Library**
4. Tap the **"Scan Bundled Music"** button
5. Your songs will be imported into the SQLite database

## Supported File Formats

- `.m4p` - Apple Music Protected AAC
- `.m4a` - AAC Audio
- `.mp3` - MP3 Audio
- `.aac` - AAC Audio
- `.wav` - WAV Audio
- `.flac` - FLAC Audio

## Tips

- **File Size**: Be mindful of app size. Each song is typically 3-10 MB
- **Copyright**: Only bundle music you have the rights to distribute
- **Testing**: Start with 5-10 songs to test, then add more
- **Performance**: The scanner can handle hundreds of songs efficiently

## Quick Terminal Command

To copy a few test songs:
```bash
# Copy first 10 songs from Apple Music downloads
find ~/Music/Music/Media.localized/Apple\ Music -name "*.m4p" -o -name "*.m4a" | head -10 | while read file; do cp "$file" ~/Documents/Layover/Resources/Music/; done
```

Then add them to Xcode as described in Step 2.
