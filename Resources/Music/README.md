# Bundled Music Files

This directory contains DRM-free music files that will be bundled with the app.

## Current Files

- **Ob-La-Di-Ob-La-Da.mp3** - The Beatles (3:20, 143KB)
  - Source: https://archive.org/details/680715b-ob-la-di-ob-la-da

## How to Add Music Files

1. Copy your DRM-free music files (.mp3, .m4a, etc.) into this directory
2. In Xcode, right-click on the `Resources/Music` folder
3. Select "Add Files to Layover..."
4. Choose your music files
5. Make sure "Copy items if needed" is checked
6. Select all targets that should include the music
7. Update SampleSong.swift to reference the new file

## Supported Formats

- MP3
- M4A (Apple Music AAC - DRM-free only)
- AAC
- WAV
- FLAC

**Note:** DRM-protected .m4p files are NOT supported for bundled content

## Organization

You can organize files in subdirectories:
- `Resources/Music/Artist Name/Album Name/01 Track.m4a`
- Or just place them flat in this directory

The scanner will find all music files recursively.
