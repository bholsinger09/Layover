import SwiftUI

// MARK: - Now Playing Extension

extension AppleMusicView {
    
    func nowPlayingBar(_ content: MediaContent) -> some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Artwork thumbnail
                if let artworkURL = content.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, height: 50)
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Title and Artist
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let artist = content.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    Button {
                        Task {
                            await viewModel.skipToPrevious()
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    
                    Button {
                        Task {
                            await viewModel.togglePlayPause()
                        }
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    
                    Button {
                        Task {
                            await viewModel.skipToNext()
                        }
                    } label: {
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
