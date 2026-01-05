import SwiftUI
import AVFoundation

/// Standalone music player view with genre filtering
public struct MusicPlayerView: View {
    @State private var viewModel = MusicPlayerViewModel()
    @State private var selectedGenre: MusicGenre = .all
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Genre filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MusicGenre.allCases, id: \.self) { genre in
                        GenreButton(
                            genre: genre,
                            isSelected: selectedGenre == genre
                        ) {
                            selectedGenre = genre
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
            
            // Song list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredSongs) { song in
                        SongRow(
                            song: song,
                            isPlaying: viewModel.currentSong?.id == song.id && viewModel.isPlaying
                        ) {
                            viewModel.playSong(song)
                        }
                    }
                }
                .padding()
            }
            
            // Now playing bar
            if let currentSong = viewModel.currentSong {
                NowPlayingBar(
                    song: currentSong,
                    isPlaying: viewModel.isPlaying,
                    onPlayPause: { viewModel.togglePlayPause() },
                    onNext: { viewModel.playNext() },
                    onPrevious: { viewModel.playPrevious() }
                )
            }
        }
        .navigationTitle("Music Player")
    }
    
    private var filteredSongs: [SampleSong] {
        viewModel.songs.filter { song in
            selectedGenre == .all || song.genre == selectedGenre
        }
    }
}

struct GenreButton: View {
    let genre: MusicGenre
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(genre.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SongRow: View {
    let song: SampleSong
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Album art placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: song.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(song.genre.displayName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Text(song.duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(isPlaying ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct NowPlayingBar: View {
    let song: SampleSong
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Album art
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: song.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                // Song info
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: onPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    
                    Button(action: onNext) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    NavigationStack {
        MusicPlayerView()
    }
}
