import SwiftUI

// MARK: - Music Item Card

struct MusicItemCard: View {
    let content: MediaContent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let artworkURL = content.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderView
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    placeholderView
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(content.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 150)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundStyle(.white)
        }
    }
    
    private var iconName: String {
        switch content.contentType {
        case .playlist:
            return "music.note.list"
        case .album:
            return "square.stack"
        case .song:
            return "music.note"
        default:
            return "music.note"
        }
    }
    
    private var gradientColors: [Color] {
        switch content.contentType {
        case .playlist:
            return [.purple, .pink]
        case .album:
            return [.blue, .cyan]
        case .song:
            return [.orange, .red]
        default:
            return [.gray, .gray.opacity(0.5)]
        }
    }
}

// MARK: - Music List Row

struct MusicListRow: View {
    let content: MediaContent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, height: 50)
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let artist = content.artist, content.contentType == .song {
                        Text(artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(content.contentType.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Playlist View

struct MusicCreatePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playlistName = ""
    let onCreate: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Playlist Name", text: $playlistName)
            }
            .navigationTitle("New Playlist")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(playlistName)
                    }
                    .disabled(playlistName.isEmpty)
                }
            }
        }
    }
}
