import SwiftUI

// MARK: - Header Bar

extension JacksView {
    var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(JacksUIStyle.primaryOpacity))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Jacks")
                    .font(JacksUIStyle.headerFont)
                    .foregroundStyle(.white)
                Text("Round \(coordinator.round)")
                    .font(JacksUIStyle.captionFont)
                    .foregroundStyle(.white.opacity(JacksUIStyle.secondaryOpacity))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Score: \(coordinator.score)")
                    .font(JacksUIStyle.headerFont)
                    .foregroundStyle(.orange)
                Text("\(coordinator.pickedUpCount)/\(JacksGameConfig.totalJacks) Jacks")
                    .font(JacksUIStyle.captionFont)
                    .foregroundStyle(.white.opacity(JacksUIStyle.secondaryOpacity))
            }
        }
        .padding(.horizontal, JacksUILayout.horizontalPadding)
        .padding(.vertical, JacksUILayout.verticalPaddingSmall)
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Control Panel

extension JacksView {
    var controlPanel: some View {
        VStack(spacing: JacksUILayout.componentSpacing) {
            phaseIndicator
            actionArea
        }
        .padding(.horizontal, JacksUILayout.horizontalPadding)
        .padding(.vertical, JacksUILayout.verticalPaddingLarge)
        .background(JacksUIStyle.controlPanelGradient)
    }

    var phaseIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(phaseColor)
                .frame(width: JacksUILayout.statusCircleSize, height: JacksUILayout.statusCircleSize)
            Text(phaseText)
                .font(JacksUIStyle.captionFont)
                .foregroundStyle(.white.opacity(JacksUIStyle.highlightOpacity))
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

    var actionArea: some View {
        HStack(spacing: JacksUILayout.elementSpacing) {
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
                    .font(JacksUIStyle.captionFont)
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
}

// MARK: - Reusable Components

extension JacksView {
    func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: JacksUILayout.tightSpacing) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(JacksUIStyle.headerFont)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, JacksUILayout.buttonHorizontalPadding)
            .padding(.vertical, JacksUILayout.buttonVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: JacksUILayout.cornerRadius)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(JacksUIStyle.shadowOpacity), radius: JacksUIStyle.buttonShadowRadius, y: JacksUIStyle.buttonShadowYOffset)
            )
        }
        .buttonStyle(.plain)
    }

    func loadingIndicator(message: String) -> some View {
        HStack(spacing: JacksUILayout.tightSpacing) {
            ProgressView()
                .tint(.white)
            Text(message)
                .foregroundStyle(.white.opacity(JacksUIStyle.primaryOpacity))
        }
    }
}

// MARK: - Game Over Overlay

extension JacksView {
    var gameOverOverlay: some View {
        VStack(spacing: 20) {
            Text("Congratulations!")
                .font(JacksUIStyle.titleFont)
                .foregroundStyle(.white)

            Text("You collected all \(JacksGameConfig.totalJacks) jacks!")
                .font(.title3)
                .foregroundStyle(.white.opacity(JacksUIStyle.highlightOpacity))

            scoreDisplay

            actionButton(title: "Play Again", icon: "arrow.counterclockwise", color: .blue) {
                coordinator.resetGame()
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: JacksUILayout.overlayCornerRadius)
                .fill(Color.black.opacity(JacksUIStyle.overlayOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: JacksUILayout.overlayCornerRadius)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(JacksUIStyle.shadowOpacity), radius: JacksUIStyle.overlayBoxShadowRadius)
    }

    private var scoreDisplay: some View {
        VStack(spacing: 8) {
            Text("Final Score")
                .font(JacksUIStyle.captionFont)
                .foregroundStyle(.white.opacity(JacksUIStyle.secondaryOpacity))
            Text("\(coordinator.score)")
                .font(JacksUIStyle.scoreFont)
                .foregroundStyle(.orange)
            Text("Rounds: \(coordinator.round)")
                .font(JacksUIStyle.subheadlineFont)
                .foregroundStyle(.white.opacity(JacksUIStyle.highlightOpacity))
        }
    }
}
