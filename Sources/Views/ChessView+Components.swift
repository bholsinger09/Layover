import SwiftUI

// MARK: - Setup View Components

extension ChessView {
    var setupViewTitle: some View {
        Text("Chess")
            .font(ChessUIStyle.titleFont)
            .foregroundStyle(.white)
            .shadow(color: ChessUIStyle.shadowDeep.color, radius: 15, x: 0, y: 5)
    }

    var colorSelectionSection: some View {
        VStack(spacing: ChessUILayout.elementSpacing) {
            Text("Choose Your Pieces")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            HStack(spacing: ChessUILayout.sectionSpacing) {
                colorButton(for: .white, label: "White", subtitle: "Goes First")
                colorButton(for: .black, label: "Black", subtitle: "Goes Second")
            }
            .padding(.vertical)
        }
    }

    private func colorButton(for color: ChessGame.PieceColor, label: String, subtitle: String) -> some View {
        Button {
            selectedColor = color
        } label: {
            VStack(spacing: ChessUILayout.tightSpacing) {
                ZStack {
                    if selectedColor == color {
                        Circle()
                            .fill(Color.white.opacity(ChessUIStyle.glowOpacity))
                            .frame(width: ChessUILayout.colorCircleGlowSize, height: ChessUILayout.colorCircleGlowSize)
                            .blur(radius: 8)
                    }

                    Circle()
                        .fill(
                            color == .white ?
                                ChessUIStyle.whiteCircleGradient :
                                ChessUIStyle.blackCircleGradient
                        )
                        .frame(width: ChessUILayout.colorCircleSize, height: ChessUILayout.colorCircleSize)
                        .overlay(
                            Circle()
                                .stroke(color == .white ? Color.gray.opacity(ChessUIStyle.tertiaryOpacity) : Color.white, lineWidth: 3)
                        )
                        .shadow(color: ChessUIStyle.shadowMedium.color, radius: 8, x: 0, y: 4)

                    if selectedColor == color {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: ChessUILayout.checkmarkIconSize))
                            .foregroundStyle(.green)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: ChessUILayout.checkmarkCircleSize, height: ChessUILayout.checkmarkCircleSize)
                            )
                    }
                }

                VStack(spacing: 4) {
                    Text(label)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(ChessUIStyle.highlightOpacity))
                }
            }
            .padding(ChessUILayout.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusLarge)
                    .fill(selectedColor == color ? Color.white.opacity(ChessUIStyle.lowOpacity) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusLarge)
                            .stroke(
                                selectedColor == color ? Color.white : Color.white.opacity(ChessUIStyle.strikeOpacity),
                                lineWidth: selectedColor == color ? 3 : 1
                            )
                    )
            )
            .shadow(color: selectedColor == color ? .white.opacity(ChessUIStyle.glowOpacity) : .clear, radius: 12, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }

    var gameModeSection: some View {
        VStack(spacing: ChessUILayout.tightSpacing) {
            Text("Choose Game Mode")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.top, 10)

            VStack(spacing: 16) {
                gameModeButton(
                    icon: "shareplay",
                    title: "Play with SharePlay",
                    subtitle: isGuestMode ? "Account required" : "Multiplayer with friends",
                    mode: .sharePlay,
                    isLocked: isGuestMode,
                    action: {
                        if isGuestMode {
                            showSignInAlert = true
                        } else {
                            gameMode = .sharePlay
                        }
                    }
                )

                gameModeButton(
                    icon: "cpu",
                    title: "Play vs Computer",
                    subtitle: "Challenge the AI",
                    mode: .vsComputer,
                    isLocked: false,
                    action: { gameMode = .vsComputer }
                )
            }
        }
    }

    private func gameModeButton(
        icon: String,
        title: String,
        subtitle: String,
        mode: GameMode,
        isLocked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: ChessUILayout.elementSpacing) {
                Image(systemName: icon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .opacity(ChessUIStyle.highlightOpacity)
                }

                Spacer()

                if gameMode == mode && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(.orange.opacity(ChessUIStyle.highlightOpacity))
                }
            }
            .foregroundStyle(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                    .fill(gameMode == mode && !isLocked ? (mode == .sharePlay ? Color.blue.opacity(ChessUIStyle.dimOpacity) : Color.purple.opacity(ChessUIStyle.dimOpacity)) : Color.white.opacity(ChessUIStyle.lowOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                            .stroke(gameMode == mode && !isLocked ? (mode == .sharePlay ? Color.blue : Color.purple) : Color.white.opacity(ChessUIStyle.tertiaryOpacity), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    var difficultySelectionView: some View {
        VStack(spacing: 12) {
            Text("Select Difficulty")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.top, 8)

            VStack(spacing: 8) {
                ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                    difficultyButton(difficulty)
                }
            }
        }
    }

    private func difficultyButton(_ difficulty: AIDifficulty) -> some View {
        Button {
            selectedDifficulty = difficulty
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(difficulty.rawValue)
                        .font(.headline)
                    Spacer()
                    if selectedDifficulty == difficulty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                Text(difficulty.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(ChessUIStyle.highlightOpacity))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                    .fill(selectedDifficulty == difficulty ? Color.orange.opacity(ChessUIStyle.dimOpacity) : Color.white.opacity(ChessUIStyle.lowOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                            .stroke(selectedDifficulty == difficulty ? Color.orange : Color.white.opacity(ChessUIStyle.tertiaryOpacity), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game View Components

extension ChessView {
    var gameHeader: some View {
        HStack {
            Text("Chess")
                .font(ChessUIStyle.headerFont)
                .bold()
                .foregroundStyle(.white)
                .shadow(color: ChessUIStyle.shadowSmall.color, radius: 5, x: 0, y: 2)

            Text("")
                .hidden()
                .id(viewModel.sharePlayStateVersion)

            Spacer()

            if viewModel.isAIThinking {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    Text("AI thinking...")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                .padding(8)
                .background(Color.black.opacity(ChessUIStyle.dimOpacity))
                .cornerRadius(ChessUILayout.cornerRadiusSmall)
            }
        }
    }

    func gameStatusDisplay(_ game: ChessGame) -> some View {
        VStack(spacing: 8) {
            Text(gameStatusText(game))
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: ChessUIStyle.shadowSmall.color, radius: 3, x: 0, y: 2)

            if game.gameState == .check {
                Text("Check!")
                    .foregroundColor(ChessUIStyle.checkStateColor)
                    .bold()
                    .shadow(color: ChessUIStyle.shadowDeep.color, radius: 5, x: 0, y: 2)
            }

            if game.gameState == .checkmate, let winnerID = game.winnerID {
                let winnerColor = game.players.first(where: { $0.userID == winnerID })?.color
                Text("\(winnerColor == .white ? "White" : "Black") wins!")
                    .font(.title2)
                    .bold()
                    .foregroundColor(ChessUIStyle.winnersTextColor)
                    .shadow(color: ChessUIStyle.shadowDeep.color, radius: 5, x: 0, y: 2)
            }
        }
    }

    func capturedPiecesDisplay(_ game: ChessGame) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Captured:")
                .font(.caption)
                .foregroundStyle(.white.opacity(ChessUIStyle.highlightOpacity))

            HStack(spacing: 4) {
                ForEach(game.capturedPieces.indices, id: \.self) { index in
                    let piece = game.capturedPieces[index]
                    Text(piece.symbol)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(piece.color == .white ? ChessUIStyle.whiteCheckColor : ChessUIStyle.blackCheckColor)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(piece.color == .white ? ChessUIStyle.capturedPieceRedBackground : Color.clear)
                                .frame(width: ChessUILayout.capturedPieceSize, height: ChessUILayout.capturedPieceSize)
                        )
                }
            }
            .padding(8)
            .background(Color.black.opacity(ChessUIStyle.dimOpacity))
            .cornerRadius(ChessUILayout.cornerRadiusSmall)
        }
    }

    var gameControlsArea: some View {
        HStack(spacing: ChessUILayout.componentSpacing) {
            gameControlButton(title: "Resign", color: .red) {
                Task {
                    await viewModel.resign(playerID: currentUser.id)
                }
            }

            gameControlButton(title: "Back", color: .gray) {
                dismiss()
            }
        }
    }

    private func gameControlButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: color == .red ? 
                            [Color.red.opacity(0.9), Color.red.opacity(0.7)] :
                            [Color.gray.opacity(0.7), Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(ChessUILayout.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                        .stroke(Color.white.opacity(ChessUIStyle.strikeOpacity), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Start Game Button

extension ChessView {
    var startGameButton: some View {
        #if os(tvOS)
        return Button {
            Task {
                await viewModel.startGame(room: room, currentUser: currentUser, playerColor: selectedColor, includeAI: gameMode == .vsComputer)
                if gameMode == .sharePlay {
                    await viewModel.startSharePlay(room: room, currentUser: currentUser, playerColor: selectedColor)
                }
            }
        } label: {
            HStack(spacing: ChessUILayout.buttonIconSize) {
                Image(systemName: gameMode == .sharePlay ? "shareplay" : "cpu")
                    .font(.title2)
                Text(gameMode == .sharePlay ? "Connect with SharePlay" : "Start Game")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
        }
        .buttonStyle(.card)
        #else
        return Button {
            Task {
                await viewModel.startGame(room: room, currentUser: currentUser, playerColor: selectedColor)
                if gameMode == .sharePlay {
                    await viewModel.startSharePlay(room: room, currentUser: currentUser, playerColor: selectedColor)
                }
            }
        } label: {
            HStack(spacing: ChessUILayout.buttonIconSize) {
                Image(systemName: gameMode == .sharePlay ? "shareplay" : "cpu")
                    .font(.title2)
                Text(gameMode == .sharePlay ? "Connect with SharePlay" : "Start Game vs \(selectedDifficulty.rawValue)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                    .fill(gameMode == .sharePlay ? ChessUIStyle.blueButtonGradient : ChessUIStyle.purpleButtonGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ChessUILayout.cornerRadiusMedium)
                    .stroke(Color.white.opacity(ChessUIStyle.strikeOpacity), lineWidth: 2)
            )
            .shadow(color: ChessUIStyle.shadowLarge.color, radius: 15, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        #endif
    }
}
