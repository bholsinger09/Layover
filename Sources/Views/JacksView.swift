import SwiftUI

public struct JacksView: View {
    let room: Room
    let currentUser: User

    @StateObject var coordinator = JacksSceneCoordinator()
    @Environment(\.dismiss) var dismiss

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

    private var sceneArea: some View {
        JacksSceneView(coordinator: coordinator) { jackIndex in
            if coordinator.canCollect {
                coordinator.collectJack(at: jackIndex)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
