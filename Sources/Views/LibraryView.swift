import SwiftUI

/// Main library view showing favorites, history, stats, and recommendations
struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var selectedTab = 0
    
    init(libraryService: LibraryServiceProtocol) {
        self._viewModel = State(initialValue: LibraryViewModel(libraryService: libraryService))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Overview Card
                    if let stats = viewModel.stats {
                        StatsCardView(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    // Recommendations Section
                    if !viewModel.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended for You")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.recommendations, id: \.contentID) { content in
                                        ContentCardView(content: content, libraryViewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Favorites Section
                    if !viewModel.favorites.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("My Favorites")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                NavigationLink {
                                    FavoritesListView(viewModel: viewModel)
                                } label: {
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.favorites.prefix(10), id: \.contentID) { content in
                                        ContentCardView(content: content, libraryViewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Recently Watched Section
                    if !viewModel.recentlyWatched.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recently Watched")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                NavigationLink {
                                    WatchHistoryView(viewModel: viewModel)
                                } label: {
                                    Text("See All")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                ForEach(viewModel.recentlyWatched.prefix(5)) { item in
                                    HistoryRowView(item: item, libraryViewModel: viewModel)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    // Empty State
                    if viewModel.favorites.isEmpty && viewModel.recentlyWatched.isEmpty {
                        ContentUnavailableView {
                            Label("Your Library is Empty", systemImage: "books.vertical")
                        } description: {
                            Text("Start watching content and adding favorites to build your personal library")
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("My Library")
            .refreshable {
                viewModel.loadLibraryData()
            }
        }
    }
}

/// Stats overview card
struct StatsCardView: View {
    let stats: LibraryStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItemView(
                    icon: "clock.fill",
                    value: stats.formattedWatchTime,
                    label: "Watch Time"
                )
                
                Divider()
                
                StatItemView(
                    icon: "star.fill",
                    value: "\(stats.totalFavorites)",
                    label: "Favorites"
                )
                
                Divider()
                
                StatItemView(
                    icon: "flame.fill",
                    value: "\(stats.recentStreak)",
                    label: "Day Streak"
                )
            }
            .frame(maxWidth: .infinity)
            
            if !stats.favoriteGenres.isEmpty {
                Divider()
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.secondary)
                    Text("Top Genre:")
                        .foregroundStyle(.secondary)
                    Text(stats.favoriteGenres.first ?? "N/A")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Content card for horizontal scrolling
struct ContentCardView: View {
    let content: MediaContent
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Placeholder image
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 160, height: 240)
                .overlay {
                    VStack {
                        Spacer()
                        Image(systemName: content.contentType == .movie ? "film" : "tv")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        
                        // Favorite button
                        HStack {
                            Spacer()
                            Button {
                                Task {
                                    await libraryViewModel.toggleFavorite(content)
                                }
                            } label: {
                                Image(systemName: libraryViewModel.isFavorite(content) ? "heart.fill" : "heart")
                                    .foregroundStyle(libraryViewModel.isFavorite(content) ? .red : .white)
                                    .font(.title3)
                                    .padding(8)
                                    .background(Circle().fill(.ultraThinMaterial))
                            }
                            .padding(8)
                        }
                    }
                }
            
            Text(content.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
            
            Text(content.contentType == .movie ? "Movie" : "TV Show")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// History row item
struct HistoryRowView: View {
    let item: WatchHistoryItem
    let libraryViewModel: LibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 120)
                .overlay {
                    Image(systemName: item.content.contentType == .movie ? "film" : "tv")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.7))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.content.contentType == .movie ? "Movie" : "TV Show")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(item.formattedDate)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await libraryViewModel.toggleFavorite(item.content)
                }
            } label: {
                Image(systemName: libraryViewModel.isFavorite(item.content) ? "heart.fill" : "heart")
                    .foregroundStyle(libraryViewModel.isFavorite(item.content) ? .red : .gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

/// Full favorites list view
struct FavoritesListView: View {
    let viewModel: LibraryViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.favorites, id: \.contentID) { content in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 90)
                        .overlay {
                            Image(systemName: content.contentType == .movie ? "film" : "tv")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .font(.headline)
                        Text(content.contentType == .movie ? "Movie" : "TV Show")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeFromFavorites(content)
                        }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Full watch history view
struct WatchHistoryView: View {
    let viewModel: LibraryViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.recentlyWatched) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 90)
                            .overlay {
                                Image(systemName: item.content.contentType == .movie ? "film" : "tv")
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.content.title)
                                .font(.headline)
                            Text(item.content.contentType == .movie ? "Movie" : "TV Show")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(item.formattedDate)
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await viewModel.toggleFavorite(item.content)
                            }
                        } label: {
                            Image(systemName: viewModel.isFavorite(item.content) ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isFavorite(item.content) ? .red : .gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Watch History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LibraryView(libraryService: LibraryService())
}
