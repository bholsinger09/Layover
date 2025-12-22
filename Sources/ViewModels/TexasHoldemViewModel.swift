import Foundation
import Observation

/// ViewModel for Texas Hold'em game rooms
@MainActor
@Observable
final class TexasHoldemViewModel: LayoverViewModel {
    private let gameService: TexasHoldemServiceProtocol

    private(set) var currentGame: TexasHoldemGame?
    private(set) var isLoading = false
    var errorMessage: String?

    var currentPhase: TexasHoldemGame.GamePhase {
        currentGame?.gamePhase ?? .preFlop
    }

    var pot: Int {
        currentGame?.pot ?? 0
    }

    var communityCards: [PlayingCard] {
        currentGame?.communityCards ?? []
    }

    nonisolated init(gameService: TexasHoldemServiceProtocol) {
        self.gameService = gameService
    }

    func startGame(roomID: UUID, players: [UUID]) async {
        isLoading = true
        errorMessage = nil

        do {
            let game = try await gameService.startGame(roomID: roomID, players: players)
            currentGame = game
            try await gameService.dealCards()
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func bet(playerID: UUID, amount: Int) async {
        errorMessage = nil

        do {
            try await gameService.bet(playerID: playerID, amount: amount)
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fold(playerID: UUID) async {
        errorMessage = nil

        do {
            try await gameService.fold(playerID: playerID)
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func call(playerID: UUID) async {
        errorMessage = nil

        do {
            try await gameService.call(playerID: playerID)
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func raise(playerID: UUID, amount: Int) async {
        errorMessage = nil

        do {
            try await gameService.raise(playerID: playerID, amount: amount)
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nextPhase() async {
        errorMessage = nil

        do {
            try await gameService.nextPhase()
            currentGame = gameService.currentGame
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endGame() async {
        await gameService.endGame()
        currentGame = nil
    }

    func getPlayer(for userID: UUID) -> TexasHoldemPlayer? {
        currentGame?.players.first { $0.userID == userID }
    }
}
