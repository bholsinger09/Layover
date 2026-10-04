import SwiftUI

// MARK: - Main Jacks View

public struct JacksView: View {
    let room: Room
    let currentUser: User

    @StateObject private var coordinator = JacksSceneCoordinator()
    @Environment(\.dismiss) private var dismiss

    public init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                sceneArea
                controlPanel
            }
        }
        .overlay(alignment: .center) {
            if coordinator.phase == .gameOver {
                gameOverOverlay
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Jacks")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Round \(coordinator.round)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Score: \(coordinator.score)")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("\(coordinator.pickedUpCount)/\(JacksGameConfig.totalJacks) Jacks")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.8))
    }

    // MARK: - 3D Scene

    private var sceneArea: some View {
        JacksSceneView(coordinator: coordinator) { jackIndex in
            if coordinator.canCollect {
                coordinator.collectJack(at: jackIndex)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Controls

    private var controlPanel: some View {
        VStack(spacing: 12) {
            phaseIndicator
            actionArea
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color(white: 0.12), Color(white: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var actionArea: some View {
        HStack(spacing: 20) {
            switch coordinator.phase {
            case .ready:
                actionButton(title: "Drop Ball", icon: "arrow.down.circle.fill", color: .orange) {
                    coordinator.dropBall()
                }

            case .ballDropped, .ballBouncing:
                loadingIndicator(message: "Ball bouncing...")

            case .collecting:
                actionButton(title: "Stop & Grab Ball", icon: "hand.raised.fill", color: .green) {
                    coordinator.stopCollecting()
                }
                Text("Tap jacks to pick them up!")
                    .font(.caption)
                    .foregroundStyle(.yellow)

            case .roundComplete:
                loadingIndicator(message: "Resetting ball...")

            case .gameOver:
                actionButton(title: "Play Again", icon: "arrow.counterclockwise", color: .blue) {
                    coordinator.resetGame()
                }
            }
        }
    }

    private var phaseIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(phaseColor)
                .frame(width: 8, height: 8)
            Text(phaseText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var phaseColor: Color {
        switch coordinator.phase {
        case .ready: .blue
        case .ballDropped, .ballBouncing: .orange
        case .collecting: .green
        case .roundComplete: .purple
        case .gameOver: .red
        }
    }

    private var phaseText: String {
        switch coordinator.phase {
        case .ready: "Ready - Press Drop Ball to start"
        case .ballDropped: "Ball dropped!"
        case .ballBouncing: "Wait for the ball to settle..."
        case .collecting: "Tap jacks to collect them!"
        case .roundComplete: "Round complete!"
        case .gameOver: "All jacks collected!"
        }
    }

    private func loadingIndicator(message: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text(message)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.5), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("Congratulations!")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text("You collected all \(JacksGameConfig.totalJacks) jacks!")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                Text("Final Score")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(coordinator.score)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.orange)
                Text("Rounds: \(coordinator.round)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            actionButton(title: "Play Again", icon: "arrow.counterclockwise", color: .blue) {
                coordinator.resetGame()
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20)
    }
}
