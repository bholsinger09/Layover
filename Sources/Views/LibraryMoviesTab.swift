import SwiftUI

// MARK: - Movies Tab

struct LibraryMoviesTab: View {
    let viewModel: LibraryViewModel
    @Binding var searchText: String
    @State private var showSearchAlert = false
    
    var movieFavorites: [MediaContent] {
        let filtered = viewModel.favorites.filter { $0.contentType == .movie || $0.contentType == .tvShow }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var movieHistory: [WatchHistoryItem] {
        let filtered = viewModel.recentlyWatched.filter { $0.content.contentType == .movie || $0.content.contentType == .tvShow }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.content.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var movieRecommendations: [MediaContent] {
        let filtered = viewModel.recommendations.filter { $0.contentType == .movie || $0.contentType == .tvShow }
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // AI Search Results Section
                if !viewModel.aiMovieResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Search Results (\(viewModel.aiMovieResults.count))")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Clear") {
                                viewModel.clearAIResults()
                                searchText = ""
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.aiMovieResults, id: \.contentID) { content in
                                    ContentCardView(content: content, libraryViewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if !searchText.isEmpty && !viewModel.isSearching {
                    // Show message when search completed but no results
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Click the 'AI search' button below")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Results will appear here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
                
                // Loading indicator
                if viewModel.isSearching {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Searching with AI...")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                // Stats Overview Card
                if let stats = viewModel.stats {
                    StatsCardView(stats: stats)
                        .padding(.horizontal)
                }
                
                // Recommendations Section
                if !movieRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for You")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(movieRecommendations, id: \.contentID) { content in
                                    ContentCardView(content: content, libraryViewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Favorites Section
                if !movieFavorites.isEmpty {
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
                                ForEach(movieFavorites.prefix(10), id: \.contentID) { content in
                                    ContentCardView(content: content, libraryViewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Recently Watched Section
                if !movieHistory.isEmpty {
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
                            ForEach(movieHistory.prefix(5)) { item in
                                HistoryRowView(item: item, libraryViewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Empty State
                if movieFavorites.isEmpty && movieHistory.isEmpty {
                    ContentUnavailableView {
                        Label("No Movies or TV Shows Yet", systemImage: "tv")
                    } description: {
                        Text("Start watching content and adding favorites to build your library")
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
        .alert("Web Search", isPresented: $showSearchAlert) {
            Button("OK") { }
        } message: {
            Text("Opening Google search for: '\(searchText)'")
        }
    }
}
