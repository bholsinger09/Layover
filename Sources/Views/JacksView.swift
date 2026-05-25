import SwiftUI
import SceneKit
#if canImport(UIKit)
import UIKit
#endif

public struct JacksView: View {
    let room: Room
    let currentUser: User

    @State private var isPlaying = false
    @State private var remainingTime = 30
    @State private var pickedJacks = Set<Int>()
    @State private var ballBouncing = false
    @State private var ballDragOffset = CGSize.zero
    @State private var isHoldingBall = false
    @State private var ballDropped = false
    @State private var showBallHand = false
    @State private var activeJackIndex: Int? = nil
    @State private var jackDragOffset = CGSize.zero
    @State private var jackDragging = false
    @State private var handPosition = CGPoint.zero
    @State private var showGameOver = false
    @State private var jackSeed = UUID()
    @Environment(\.dismiss) private var dismiss

    private let totalJacks = 10
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let initialJackOffsets: [CGSize] = [
        .init(width: -80, height: -10),
        .init(width: -40, height: -14),
        .init(width: 0, height: -20),
        .init(width: 42, height: -12),
        .init(width: 82, height: -8),
        .init(width: -66, height: 36),
        .init(width: -18, height: 42),
        .init(width: 24, height: 48),
        .init(width: 60, height: 34),
        .init(width: 12, height: 18)
    ]

    public init(room: Room, currentUser: User) {
        self.room = room
        self.currentUser = currentUser
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.12, green: 0.1, blue: 0.28),
                    Color(red: 0.08, green: 0.16, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                headerView

                ballArea
                    .frame(height: 240)

                VStack(spacing: 20) {
                    actionRow
                    jackGrid
                }
                .padding(.horizontal, 20)

                Spacer()

                footerView
            }
            .padding(.top, 35)
            .padding(.bottom, 20)
        }
        .onAppear {
            startBounceAnimation()
        }
        .onReceive(timer) { _ in
            guard isPlaying, remainingTime > 0 else { return }
            remainingTime -= 1
            if remainingTime == 0 {
                endGame()
            }
        }
        .alert("Game Over", isPresented: $showGameOver) {
            Button("Play Again") {
                resetGame()
            }
            Button("Close", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("You picked up \(pickedJacks.count) jacks in 30 seconds.")
        }
    }

    private var headerView: some View {
        VStack(spacing: 10) {
            Text("Jacks")
                .font(.system(size: 58, weight: .heavy))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.8), radius: 15, x: 0, y: 6)

            Text("Bounce the ball, grab the jacks, and beat the timer.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 20)
        }
    }

    private var ballArea: some View {
        let metrics = ballMetrics
        return ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.08, blue: 0.18), Color(red: 0.1, green: 0.14, blue: 0.26)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.13), lineWidth: 1)
                )

            // Wooden floor plane
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.44, green: 0.28, blue: 0.14), Color(red: 0.34, green: 0.21, blue: 0.09), Color(red: 0.47, green: 0.30, blue: 0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 172)
                    .offset(y: 68)
                    .rotation3DEffect(.degrees(14), axis: (x: 1, y: 0, z: 0), anchor: .center)
                    .shadow(color: Color.black.opacity(0.24), radius: 16, x: 0, y: 12)

                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.brown.opacity(0.18), lineWidth: 1)
                    .frame(height: 172)
                    .offset(y: 68)
                    .rotation3DEffect(.degrees(14), axis: (x: 1, y: 0, z: 0), anchor: .center)

                VStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Rectangle()
                            .fill(Color.black.opacity(0.06))
                            .frame(height: 2)
                            .opacity(0.55)
                            .padding(.horizontal, 24)
                            .offset(y: CGFloat(index * 28 - 26))
                    }
                }
                .frame(height: 172)
                .offset(y: 68)
                .rotation3DEffect(.degrees(14), axis: (x: 1, y: 0, z: 0), anchor: .center)
                .blendMode(.overlay)
                .opacity(0.8)

                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 4, height: 120)
                        .rotationEffect(.degrees(6))
                        .offset(x: CGFloat(index * 36 - 64), y: 40)
                        .opacity(0.35)
                }
            }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 180, height: 55)
                        .offset(y: 108)
                        .blur(radius: 10)

                        Circle()
                            .fill(Color.black.opacity(0.28))
                            .frame(width: 150 * metrics.shadow, height: 30 * metrics.shadow)
                            .offset(y: 106)
                            .blur(radius: 9)
                            .opacity(ballDropped ? 1.0 : 0.86)

                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [Color(red: 1.0, green: 0.94, blue: 0.74), Color(red: 0.98, green: 0.44, blue: 0.08), Color(red: 0.78, green: 0.15, blue: 0.02)]),
                                        center: .center,
                                        startRadius: 6,
                                        endRadius: 46
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [Color.black.opacity(0.12), Color.clear]),
                                                center: .bottom,
                                                startRadius: 4,
                                                endRadius: 46
                                            )
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.16), lineWidth: 1.2)
                                        .blur(radius: 1)
                                )

                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.1)]),
                                        center: .topLeading,
                                        startRadius: 1,
                                        endRadius: 32
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .offset(x: -18, y: -16)

                            Circle()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1.4)
                                .frame(width: 96, height: 96)
                                .blur(radius: 0.4)

                            if showBallHand || ballDropped {
                                Image(systemName: isHoldingBall ? "hand.raised.fill" : "hand.point.up.left.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white)
                                    .offset(x: ballDragOffset.width * 0.7, y: min(ballDragOffset.height + 40, 90))
                                    .shadow(color: Color.black.opacity(0.55), radius: 10, x: 0, y: 3)
                                    .opacity((showBallHand || ballDropped) ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.18), value: showBallHand)
                            }
                        }
                        .frame(width: 92, height: 92)
                        .shadow(color: Color.orange.opacity(0.62), radius: 22, x: 0, y: 14)
                        .scaleEffect(metrics.scale)
                        .offset(x: ballDragOffset.width, y: metrics.y)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isHoldingBall = true
                                    showBallHand = true
                                    ballDragOffset = value.translation
                                    ballDropped = false
                                }
                                .onEnded { value in
                                    isHoldingBall = false
                                    showBallHand = false
                                    ballDragOffset = .zero
                                    if value.translation.height > 24 {
                                        dropBallToGround()
                                    } else {
                                        ballDropped = false
                                    }
                                }
                        )
                        .animation(.easeInOut(duration: 0.25), value: ballDragOffset)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: ballBouncing)

                        Text("Bounce")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .offset(y: 110)
                    }

                    VStack(spacing: 6) {
                        Text(isPlaying ? "Pick up the jacks while the ball bounces on the ground" : "Drag the ball down to the floor to begin")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Use your hand to lift a jack from the floor after the ball hits the ground.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 20)
            }
            .padding(.horizontal, 16)
        }

    private var ballMetrics: (y: CGFloat, scale: CGFloat, shadow: CGFloat) {
        if isHoldingBall {
            return (ballDragOffset.height, 1.08, 0.48)
        }

        if ballDropped {
            return (ballBouncing ? 18 : 42, ballBouncing ? 1.02 : 0.92, ballBouncing ? 1.22 : 0.96)
        }

        return (-70, 1.0, 0.7)
    }

    private var actionRow: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Time")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(remainingTime)s")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(remainingTime <= 5 ? .red : .white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Score")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Text("\(pickedJacks.count)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                if isPlaying {
                    endGame()
                } else {
                    startGame()
                }
            }) {
                Text(isPlaying ? "Stop" : "Start")
                    .font(.headline)
                    .frame(minWidth: 110, minHeight: 45)
                    .background(isPlaying ? Color.red : Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(14)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
    }

    private var jackGrid: some View {
        #if canImport(UIKit)
        JacksSceneKitView(
            pickedJacks: $pickedJacks,
            ballDropped: $ballDropped,
            seed: jackSeed,
            onJackPicked: handleJackPickup
        )
        .frame(height: 300)
        #else
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.42, green: 0.24, blue: 0.10), Color(red: 0.29, green: 0.17, blue: 0.07), Color(red: 0.35, green: 0.20, blue: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 300)
                .shadow(color: Color.black.opacity(0.22), radius: 18, x: 0, y: 12)

            VStack(spacing: 16) {
                Text("Wood floor and metal jacks preview is only available on iOS.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        #endif
    }

    #if canImport(UIKit)
    private struct JacksSceneKitView: UIViewRepresentable {
        @Binding var pickedJacks: Set<Int>
        @Binding var ballDropped: Bool
        let seed: UUID
        let onJackPicked: (Int) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.scene = context.coordinator.scene
            scnView.backgroundColor = .clear
            scnView.autoenablesDefaultLighting = false
            scnView.allowsCameraControl = false
            scnView.rendersContinuously = true
            scnView.delegate = context.coordinator

            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
            scnView.addGestureRecognizer(tap)

            context.coordinator.updatePickedJacks(pickedJacks)
            context.coordinator.updateBallBounce(enabled: ballDropped)
            return scnView
        }

        func updateUIView(_ uiView: SCNView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.updatePickedJacks(pickedJacks)
            context.coordinator.updateBallBounce(enabled: ballDropped)
            if context.coordinator.seed != seed {
                context.coordinator.seed = seed
                context.coordinator.refreshJackPositions()
            }
        }

        class Coordinator: NSObject, SCNSceneRendererDelegate {
            var parent: JacksSceneKitView
            let scene = SCNScene()
            let ballNode = SCNNode()
            var jackNodes: [Int: SCNNode] = [:]
            var jackPositions: [SCNVector3] = []
            var seed: UUID
            var bounceAction: SCNAction?

            init(parent: JacksSceneKitView) {
                self.parent = parent
                self.seed = parent.seed
                super.init()
                jackPositions = Coordinator.generateRandomJackPositions()
                scene.lightingEnvironment.contents = UIColor(white: 0.96, alpha: 1)
                scene.lightingEnvironment.intensity = 1.15

                let cameraNode = SCNNode()
                cameraNode.camera = SCNCamera()
                cameraNode.camera?.wantsHDR = true
                cameraNode.camera?.wantsExposureAdaptation = true
                cameraNode.camera?.automaticallyAdjustsZRange = true
                cameraNode.position = SCNVector3(0, 5.8, 10.5)
                cameraNode.eulerAngles = SCNVector3(-0.58, 0, 0)
                scene.rootNode.addChildNode(cameraNode)

                let ambientLight = SCNLight()
                ambientLight.type = .ambient
                ambientLight.color = UIColor(white: 0.35, alpha: 1)
                let ambientNode = SCNNode()
                ambientNode.light = ambientLight
                scene.rootNode.addChildNode(ambientNode)

                let keyLight = SCNLight()
                keyLight.type = .directional
                keyLight.color = UIColor(white: 0.98, alpha: 1)
                keyLight.castsShadow = true
                keyLight.shadowRadius = 8
                keyLight.shadowColor = UIColor(white: 0.0, alpha: 0.4)
                let keyNode = SCNNode()
                keyNode.light = keyLight
                keyNode.eulerAngles = SCNVector3(-0.8, 0.5, 0)
                scene.rootNode.addChildNode(keyNode)

                let fillLight = SCNLight()
                fillLight.type = .directional
                fillLight.color = UIColor(white: 0.6, alpha: 1)
                let fillNode = SCNNode()
                fillNode.light = fillLight
                fillNode.eulerAngles = SCNVector3(-0.2, -1.0, 0)
                scene.rootNode.addChildNode(fillNode)

                let woodPlane = SCNPlane(width: 12, height: 12)
                woodPlane.firstMaterial = makeWoodMaterial()
                woodPlane.firstMaterial?.isDoubleSided = true
                let floorNode = SCNNode(geometry: woodPlane)
                floorNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                floorNode.position = SCNVector3(0, 0, 0)
                scene.rootNode.addChildNode(floorNode)

                // The interactive ball is rendered in SwiftUI above, so the SceneKit floor only shows the jacks.
                let jacksContainer = SCNNode()
                for index in 0..<10 {
                    let jack = makeJackNode(index: index)
                    jack.position = jackPositions[index]
                    jack.eulerAngles = SCNVector3(
                        Float.random(in: -0.18...0.18),
                        Float.random(in: 0..<Float.pi * 2),
                        Float.random(in: -0.18...0.18)
                    )
                    jack.castsShadow = true
                    jacksContainer.addChildNode(jack)
                    jackNodes[index] = jack
                }
                scene.rootNode.addChildNode(jacksContainer)

                bounceAction = .repeatForever(
                    .sequence([
                        .moveBy(x: 0, y: -1.0, z: 0, duration: 0.95),
                        .moveBy(x: 0, y: 1.0, z: 0, duration: 0.95)
                    ])
                )
            }

            @objc func handleTap(_ gesture: UITapGestureRecognizer) {
                guard let scnView = gesture.view as? SCNView else { return }
                let location = gesture.location(in: scnView)
                let hits = scnView.hitTest(location, options: [SCNHitTestOption.boundingBoxOnly: false])
                guard let hit = hits.first(where: { $0.node.name?.starts(with: "jack_") == true }) else { return }
                if let name = hit.node.name, let index = Int(name.replacingOccurrences(of: "jack_", with: "")) {
                    onJackTapped(index)
                }
            }

            private func onJackTapped(_ index: Int) {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.onJackPicked(index)
                }
            }

            func updatePickedJacks(_ picked: Set<Int>) {
                for (index, node) in jackNodes {
                    let isPicked = picked.contains(index)
                    node.enumerateChildNodes { child, _ in
                        child.geometry?.firstMaterial = makeJackMaterial(picked: isPicked)
                    }
                }
            }

            func updateBallBounce(enabled: Bool) {
                ballNode.removeAllActions()
                if enabled, let bounceAction = bounceAction {
                    ballNode.runAction(bounceAction, forKey: "bounce")
                } else {
                    ballNode.position = SCNVector3(0, 2.0, 0)
                }
            }

            private func makeWoodMaterial() -> SCNMaterial {
                let material = SCNMaterial()
                material.diffuse.contents = makeWoodTexture()
                material.metalness.contents = 0.1
                material.roughness.contents = 0.55
                material.specular.contents = UIColor(white: 0.7, alpha: 1)
                material.locksAmbientWithDiffuse = true
                return material
            }

            private func makeBallNode() -> SCNNode {
                let sphere = SCNSphere(radius: 0.72)
                sphere.segmentCount = 80
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(red: 0.92, green: 0.14, blue: 0.05, alpha: 1)
                material.metalness.contents = 0.96
                material.roughness.contents = 0.06
                material.specular.contents = UIColor(white: 1.0, alpha: 0.98)
                material.clearCoat.contents = 1.0
                material.clearCoatRoughness.contents = 0.05
                material.lightingModel = .physicallyBased
                sphere.firstMaterial = material

                let node = SCNNode(geometry: sphere)
                return node
            }

            private func makeJackNode(index: Int) -> SCNNode {
                let jackRoot = SCNNode()
                jackRoot.name = "jack_\(index)"

                let center = SCNSphere(radius: 0.14)
                center.segmentCount = 96
                center.firstMaterial = makeJackMaterial(picked: false)
                let centerNode = SCNNode(geometry: center)
                jackRoot.addChildNode(centerNode)

                let directions: [SCNVector3] = [
                    SCNVector3(1, 0, 0),
                    SCNVector3(-1, 0, 0),
                    SCNVector3(0, 1, 0),
                    SCNVector3(0, -1, 0),
                    SCNVector3(0, 0, 1),
                    SCNVector3(0, 0, -1)
                ]

                let shaftLength: Float = 0.78
                let shaftRadius: CGFloat = 0.048
                let tipDistance = shaftLength / 2 + 0.14
                let endDistance = shaftLength + 0.14

                for direction in directions {
                    let shaft = SCNCapsule(capRadius: shaftRadius, height: CGFloat(shaftLength))
                    shaft.radialSegmentCount = 36
                    shaft.capSegmentCount = 24
                    shaft.firstMaterial = makeJackMaterial(picked: false)
                    let shaftNode = SCNNode(geometry: shaft)

                    if direction.x != 0 {
                        shaftNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
                    } else if direction.z != 0 {
                        shaftNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                    }

                    shaftNode.position = SCNVector3(
                        direction.x * tipDistance,
                        direction.y * tipDistance,
                        direction.z * tipDistance
                    )
                    shaftNode.castsShadow = true
                    jackRoot.addChildNode(shaftNode)

                    let endBall = SCNSphere(radius: 0.11)
                    endBall.segmentCount = 48
                    endBall.firstMaterial = makeJackMaterial(picked: false)
                    let endNode = SCNNode(geometry: endBall)
                    endNode.position = SCNVector3(
                        direction.x * endDistance,
                        direction.y * endDistance,
                        direction.z * endDistance
                    )
                    endNode.castsShadow = true
                    jackRoot.addChildNode(endNode)
                }

                let scale = Float.random(in: 0.92...1.06)
                jackRoot.scale = SCNVector3(scale, scale, scale)
                jackRoot.castsShadow = true

                return jackRoot
            }

            private func makeJackMaterial(picked: Bool) -> SCNMaterial {
                let material = SCNMaterial()
                material.lightingModel = .physicallyBased
                material.diffuse.contents = picked ? UIColor(red: 0.96, green: 0.88, blue: 0.70, alpha: 1) : UIColor(red: 0.92, green: 0.93, blue: 0.97, alpha: 1)
                material.metalness.contents = 1.0
                material.roughness.contents = picked ? 0.18 : 0.06
                material.specular.contents = UIColor(white: 1.0, alpha: 0.96)
                material.shininess = 180
                material.emission.contents = picked ? UIColor(red: 0.18, green: 0.14, blue: 0.10, alpha: 0.08) : UIColor.clear
                material.clearCoat.contents = 1.0
                material.clearCoatRoughness.contents = 0.08
                material.reflective.contents = UIColor(white: 0.95, alpha: 0.22)
                material.locksAmbientWithDiffuse = true
                return material
            }

            private static func generateRandomJackPositions() -> [SCNVector3] {
                var positions: [SCNVector3] = []
                while positions.count < 10 {
                    let x = Float.random(in: -1.8...1.8)
                    let z = Float.random(in: -1.6...1.6)
                    let candidate = SCNVector3(x, 0.18, z)
                    let minDistance: Float = 0.72
                    let tooClose = positions.contains { existing in
                        let dx = existing.x - candidate.x
                        let dz = existing.z - candidate.z
                        return sqrt(dx * dx + dz * dz) < minDistance
                    }
                    if !tooClose {
                        positions.append(candidate)
                    }
                }
                return positions
            }

            func refreshJackPositions() {
                jackPositions = Coordinator.generateRandomJackPositions()
                for (index, node) in jackNodes {
                    node.position = jackPositions[index]
                    node.eulerAngles = SCNVector3(0, Float.random(in: 0..<Float.pi * 2), 0)
                }
            }

            private func makeWoodTexture() -> UIImage {
                let size = CGSize(width: 512, height: 512)
                let renderer = UIGraphicsImageRenderer(size: size)
                return renderer.image { context in
                    let cgContext = context.cgContext
                    let base = UIColor(red: 0.47, green: 0.29, blue: 0.14, alpha: 1)
                    cgContext.setFillColor(base.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: size))

                    for x in stride(from: 0, to: Int(size.width), by: 64) {
                        let lineColor = UIColor(white: 0.0, alpha: 0.08)
                        cgContext.setFillColor(lineColor.cgColor)
                        cgContext.fill(CGRect(x: CGFloat(x), y: 0, width: 4, height: size.height))
                    }

                    for index in 0..<6 {
                        let y = CGFloat(index) * 92 + 24
                        let stripeColor = UIColor(white: 1, alpha: 0.05)
                        cgContext.setFillColor(stripeColor.cgColor)
                        cgContext.fill(CGRect(x: 0, y: y, width: size.width, height: 12))
                    }

                    for _ in 0..<80 {
                        let x = CGFloat.random(in: 0..<size.width)
                        let y = CGFloat.random(in: 0..<size.height)
                        let alpha = CGFloat.random(in: 0.05...0.16)
                        let radius = CGFloat.random(in: 1...2.5)
                        cgContext.setFillColor(UIColor(white: 1, alpha: alpha).cgColor)
                        cgContext.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
                    }
                }
            }
        }
    }
    #endif

    private var footerView: some View {
        VStack(spacing: 12) {
            Text("Pick up all the jacks before the ball lands. Every jack counts!")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 24)

            Button(action: resetGame) {
                Text("Reset")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .cornerRadius(18)
            }
            .disabled(isPlaying)
        }
        .padding(.horizontal, 20)
    }

    private func handleJackPickup(_ index: Int) {
        guard isPlaying, remainingTime > 0, !pickedJacks.contains(index) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            _ = pickedJacks.insert(index)
        }
    }

    private func startGame() {
        isPlaying = true
        remainingTime = 30
        pickedJacks.removeAll()
        showGameOver = false
        ballDropped = false
        isHoldingBall = false
        jackSeed = UUID()
    }

    private func endGame() {
        isPlaying = false
        showGameOver = true
    }

    private func resetGame() {
        isPlaying = false
        remainingTime = 30
        pickedJacks.removeAll()
        showGameOver = false
        ballDropped = false
        isHoldingBall = false
        jackSeed = UUID()
    }

    private func dropBallToGround() {
        ballDropped = true
        ballBouncing = true
    }

    private func startBounceAnimation() {
        ballBouncing = true
    }
}

#Preview {
    JacksView(
        room: Room(
            name: "Jacks",
            hostID: UUID(),
            activityType: .chess
        ),
        currentUser: User(username: "Test")
    )
}
