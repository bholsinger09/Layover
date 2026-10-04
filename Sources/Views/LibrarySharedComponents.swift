import SwiftUI

// MARK: - Stats Card View

struct StatsCardView: View {
    let stats: LibraryStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Library Stats")
                .font(.headline)
                .foregroundStyle(.white)
            
            VStack(spacing: 12) {
                StatItemView(label: "Total Movies", value: "\(stats.totalMovies)")
                StatItemView(label: "Total Shows", value: "\(stats.totalTVShows)")
                StatItemView(label: "Favorites", value: "\(stats.totalFavorites)")
                StatItemView(label: "Streak", value: "\(stats.recentStreak) days")
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Stat Item View

struct StatItemView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Content Card View

struct ContentCardView: View {
    let content: MediaContent
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                )
                .frame(height: 120)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Spacer()
                    
                    Text(content.contentType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .frame(width: 140)
    }
}

// MARK: - Favorites List View

struct FavoritesListView: View {
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.favorites) { content in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(content.title)
                                .font(.headline)
                            Text(content.contentType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await viewModel.toggleFavorite(content)
                            }
                        }) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Watch History View

struct WatchHistoryView: View {
    let viewModel: LibraryViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.recentlyWatched) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.content.title)
                                .font(.headline)
                            Text(item.watchedAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        let progress = calculateWatchProgress(item)
                        Text("\(Int(progress))%")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Watch History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    let item: WatchHistoryItem
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content.title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text(item.watchedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            let progress = calculateWatchProgress(item)
            ProgressView(value: progress, total: 100)
                .frame(width: 60)
                .tint(.orange)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Helper Functions

private func calculateWatchProgress(_ item: WatchHistoryItem) -> Double {
    guard item.content.duration > 0 else { return 0 }
    let progress = (item.watchDuration / item.content.duration) * 100
    return min(progress, 100)
}
