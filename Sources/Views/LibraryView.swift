import SwiftUI

// MARK: - Main Library View

public struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var selectedTab: LibraryContentTab = .movies
    @State private var searchText = ""
    
    public init(libraryService: LibraryServiceProtocol) {
        _viewModel = State(initialValue: LibraryViewModel(libraryService: libraryService))
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelector
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    LibraryMoviesTab(viewModel: viewModel, searchText: $searchText)
                        .tag(LibraryContentTab.movies)
                    
                    LibraryStoriesTab(viewModel: viewModel, searchText: $searchText)
                        .tag(LibraryContentTab.stories)
                    
                    LibraryMusicTab(viewModel: viewModel, searchText: $searchText)
                        .tag(LibraryContentTab.music)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
        }
        .searchable(text: $searchText, prompt: "Search")
    }
    
    private var headerView: some View {
        HStack {
            Text("My Library")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 16) {
            ForEach(LibraryContentTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Text(tab.label)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .foregroundStyle(selectedTab == tab ? .orange : .gray)
                        
                        if selectedTab == tab {
                            Capsule()
                                .frame(height: 3)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.black)
    }
}

// MARK: - Library Content Tab

enum LibraryContentTab: CaseIterable, Hashable {
    case movies
    case stories
    case music
    
    var label: String {
        switch self {
        case .movies:
            return "Movies"
        case .stories:
            return "Stories"
        case .music:
            return "Music"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LibraryView(libraryService: LibraryService())
}
#endif
