import SwiftUI

/// Simple games launcher view
public struct GamesLauncherView: View {
    let currentUser: User
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingChess = false
    @State private var showingCheckers = false
    @State private var showingConnectFour = false
    @State private var showingJacks = false
    
    public init(currentUser: User) {
        self.currentUser = currentUser
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.95),
                        Color(red: 0.1, green: 0.05, blue: 0.15),
                        Color(red: 0.15, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Choose Your Game")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("All games available in single-player mode")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 40)
                        
                        // Game Cards
                        VStack(spacing: 20) {
                            // Chess Card
                            GameCardButton(
                                title: "Chess",
                                icon: "chess.board.fill",
                                description: "Classic strategy game with AI opponent",
                                gradients: [Color(red: 0.2, green: 0.4, blue: 0.9), Color(red: 0.1, green: 0.6, blue: 0.8)],
                                shadowColor: .cyan
                            ) {
                                showingChess = true
                            }
                            
                            // Checkers Card
                            GameCardButton(
                                title: "Checkers",
                                icon: "circle.fill",
                                description: "Jump and capture in this timeless board game",
                                gradients: [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.1)],
                                shadowColor: .red
                            ) {
                                showingCheckers = true
                            }
                            
                            // Connect Four Card
                            GameCardButton(
                                title: "Connect Four",
                                icon: "circle.grid.3x3.fill",
                                description: "Get 4 in a row to win!",
                                gradients: [Color(red: 0.1, green: 0.5, blue: 0.8), Color(red: 0.2, green: 0.7, blue: 0.9)],
                                shadowColor: .blue
                            ) {
                                showingConnectFour = true
                            }

                            // Jacks Card
                            GameCardButton(
                                title: "Jacks",
                                icon: "sparkles",
                                description: "Bounce the ball and grab the jacks!",
                                gradients: [Color(red: 0.9, green: 0.5, blue: 0.1), Color(red: 0.95, green: 0.3, blue: 0.2)],
                                shadowColor: .orange
                            ) {
                                showingJacks = true
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Games")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            #endif
            .sheet(isPresented: $showingChess) {
                ChessView(
                    room: Room(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                        name: "Chess",
                        hostID: currentUser.id,
                        activityType: .chess,
                        maxParticipants: 2,
                        isPrivate: false
                    ),
                    currentUser: currentUser
                )
            }
            .sheet(isPresented: $showingCheckers) {
                CheckersView(
                    room: Room(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
                        name: "Checkers",
                        hostID: currentUser.id,
                        activityType: .chess,
                        maxParticipants: 2,
                        isPrivate: false
                    ),
                    currentUser: currentUser
                )
            }
            .sheet(isPresented: $showingConnectFour) {
                ConnectFourView(
                    room: Room(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID(),
                        name: "Connect Four",
                        hostID: currentUser.id,
                        activityType: .chess,
                        maxParticipants: 2,
                        isPrivate: false
                    ),
                    currentUser: currentUser
                )
            }
            .sheet(isPresented: $showingJacks) {
                JacksView(
                    room: Room(
                        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID(),
                        name: "Jacks",
                        hostID: currentUser.id,
                        activityType: .chess,
                        maxParticipants: 1,
                        isPrivate: false
                    ),
                    currentUser: currentUser
                )
            }
        }
    }
}

// Game Card Button Component
private struct GameCardButton: View {
    let title: String
    let icon: String
    let description: String
    let gradients: [Color]
    let shadowColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 35))
                        .foregroundStyle(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradients,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
            )
            .shadow(color: shadowColor.opacity(0.5), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GamesLauncherView(currentUser: User(username: "Test", email: "test@example.com"))
}
