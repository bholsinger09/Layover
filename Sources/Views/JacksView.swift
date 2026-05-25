import SwiftUI
import SceneKit

// MARK: - SceneKit Coordinator

/// Manages the 3D SceneKit scene for the Jacks game
public final class JacksSceneCoordinator: NSObject, ObservableObject, SCNPhysicsContactDelegate {
    @Published var scene: SCNScene
    @Published var pickedUpCount: Int = 0
    @Published var phase: JacksGame.GamePhase = .ready
    @Published var round: Int = 1
    @Published var score: Int = 0
    @Published var canCollect: Bool = false

    private var ballNode: SCNNode!
    private var jackNodes: [SCNNode] = []
    private var floorNode: SCNNode!
    private var cameraNode: SCNNode!
    private var lightNode: SCNNode!
    private var ambientLightNode: SCNNode!
    private let totalJacks = 10
    private var ballRestY: Float = 0.15
    private var ballDropHeight: Float = 2.5
    private var isBallResting = false

    public override init() {
        scene = SCNScene()
        super.init()
        setupScene()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        scene.background.contents = createSkyColor()
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scene.physicsWorld.contactDelegate = self

        setupCamera()
        setupLighting()
        setupFloor()
        setupBall()
        scatterJacks()
    }

    private func createSkyColor() -> Any {
        #if canImport(UIKit)
        return UIColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1.0)
        #elseif canImport(AppKit)
        return NSColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1.0)
        #else
        return SCNVector4(0.15, 0.12, 0.1, 1.0)
        #endif
    }

    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 50
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 4.5, 6)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 5.5, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLighting() {
        lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .spot
        lightNode.light?.intensity = 1200
        lightNode.light?.spotInnerAngle = 30
        lightNode.light?.spotOuterAngle = 80
        lightNode.light?.castsShadow = true
        lightNode.light?.shadowRadius = 8
        lightNode.light?.shadowSampleCount = 16
        lightNode.light?.shadowMode = .deferred
        lightNode.light?.color = platformColor(r: 1.0, g: 0.95, b: 0.85)
        lightNode.position = SCNVector3(2, 8, 4)
        lightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(lightNode)

        ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 400
        ambientLightNode.light?.color = platformColor(r: 0.9, g: 0.85, b: 0.75)
        scene.rootNode.addChildNode(ambientLightNode)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.light?.color = platformColor(r: 0.8, g: 0.85, b: 1.0)
        fillLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)
    }

    private func platformColor(r: CGFloat, g: CGFloat, b: CGFloat) -> Any {
        #if canImport(UIKit)
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        #elseif canImport(AppKit)
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        #else
        return SCNVector4(r, g, b, 1.0)
        #endif
    }

    private func setupFloor() {
        let floorGeometry = SCNBox(width: 12, height: 0.15, length: 12, chamferRadius: 0)
        let woodMaterial = SCNMaterial()
        woodMaterial.diffuse.contents = platformColor(r: 0.55, g: 0.35, b: 0.18)
        woodMaterial.roughness.contents = 0.7
        woodMaterial.metalness.contents = 0.0
        woodMaterial.normal.intensity = 0.4
        woodMaterial.specular.contents = platformColor(r: 0.3, g: 0.2, b: 0.1)

        let plankOverlay = SCNMaterial()
        plankOverlay.diffuse.contents = platformColor(r: 0.50, g: 0.32, b: 0.16)
        plankOverlay.roughness.contents = 0.8

        floorGeometry.materials = [woodMaterial, woodMaterial, plankOverlay, plankOverlay, woodMaterial, woodMaterial]

        floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position = SCNVector3(0, -0.075, 0)
        floorNode.physicsBody = SCNPhysicsBody.static()
        floorNode.physicsBody?.restitution = 0.7
        floorNode.physicsBody?.friction = 0.6
        floorNode.physicsBody?.categoryBitMask = 1
        floorNode.name = "floor"
        scene.rootNode.addChildNode(floorNode)

        addFloorPlankLines()
    }

    private func addFloorPlankLines() {
        let plankWidth: CGFloat = 1.2
        for i in -4...4 {
            let lineGeometry = SCNBox(width: 0.02, height: 0.001, length: 12, chamferRadius: 0)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = platformColor(r: 0.35, g: 0.22, b: 0.12)
            lineGeometry.materials = [lineMaterial]
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = SCNVector3(Float(i) * Float(plankWidth), 0.002, 0)
            scene.rootNode.addChildNode(lineNode)
        }
    }

    // MARK: - Ball

    private func setupBall() {
        let ballGeometry = SCNSphere(radius: 0.15)
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = platformColor(r: 0.85, g: 0.15, b: 0.15)
        ballMaterial.specular.contents = platformColor(r: 1.0, g: 1.0, b: 1.0)
        ballMaterial.roughness.contents = 0.2
        ballMaterial.metalness.contents = 0.1
        ballMaterial.fresnelExponent = 2.0
        ballGeometry.materials = [ballMaterial]

        ballNode = SCNNode(geometry: ballGeometry)
        ballNode.position = SCNVector3(0, ballRestY, 0)
        ballNode.name = "ball"

        let ballBody = SCNPhysicsBody.dynamic()
        ballBody.mass = 0.05
        ballBody.restitution = 0.85
        ballBody.friction = 0.3
        ballBody.rollingFriction = 0.1
        ballBody.damping = 0.05
        ballBody.angularDamping = 0.1
        ballBody.categoryBitMask = 2
        ballBody.contactTestBitMask = 1
        ballBody.isAffectedByGravity = false
        ballNode.physicsBody = ballBody

        scene.rootNode.addChildNode(ballNode)
    }

    // MARK: - Jacks

    private func scatterJacks() {
        for node in jackNodes {
            node.removeFromParentNode()
        }
        jackNodes.removeAll()

        var positions: [SIMD2<Float>] = []

        for i in 0..<totalJacks {
            var pos: SIMD2<Float>
            var attempts = 0
            repeat {
                let angle = Float.random(in: 0...(2 * .pi))
                let radius = Float.random(in: 0.6...2.8)
                pos = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
                attempts += 1
            } while attempts < 50 && positions.contains(where: { distance($0, pos) < 0.45 })
            positions.append(pos)

            let jackNode = createJackNode(index: i)
            jackNode.position = SCNVector3(pos.x, 0.12, pos.y)
            jackNode.eulerAngles = SCNVector3(
                Float.random(in: 0...(2 * .pi)),
                Float.random(in: 0...(2 * .pi)),
                Float.random(in: 0...(2 * .pi))
            )

            let jackBody = SCNPhysicsBody.static()
            jackBody.categoryBitMask = 4
            jackNode.physicsBody = jackBody

            scene.rootNode.addChildNode(jackNode)
            jackNodes.append(jackNode)
        }
    }

    private func createJackNode(index: Int) -> SCNNode {
        let jackRoot = SCNNode()
        jackRoot.name = "jack_\(index)"

        let metalMaterial = SCNMaterial()
        metalMaterial.diffuse.contents = platformColor(r: 0.75, g: 0.75, b: 0.78)
        metalMaterial.metalness.contents = 0.95
        metalMaterial.roughness.contents = 0.15
        metalMaterial.specular.contents = platformColor(r: 1.0, g: 1.0, b: 1.0)
        metalMaterial.fresnelExponent = 5.0

        let centerSphere = SCNSphere(radius: 0.04)
        centerSphere.segmentCount = 16
        centerSphere.materials = [metalMaterial]
        let centerNode = SCNNode(geometry: centerSphere)
        jackRoot.addChildNode(centerNode)

        let armLength: CGFloat = 0.1
        let armRadius: CGFloat = 0.018
        let tipRadius: CGFloat = 0.028

        let directions: [(Float, Float, Float)] = [
            (1, 0, 0), (-1, 0, 0),
            (0, 1, 0), (0, -1, 0),
            (0, 0, 1), (0, 0, -1)
        ]

        for dir in directions {
            let arm = SCNCylinder(radius: armRadius, height: armLength)
            arm.radialSegmentCount = 8
            arm.materials = [metalMaterial]
            let armNode = SCNNode(geometry: arm)

            let halfLen = Float(armLength) / 2
            armNode.position = SCNVector3(dir.0 * halfLen, dir.1 * halfLen, dir.2 * halfLen)

            if dir.0 != 0 {
                armNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            } else if dir.2 != 0 {
                armNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            }

            jackRoot.addChildNode(armNode)

            let tip = SCNSphere(radius: tipRadius)
            tip.segmentCount = 12
            tip.materials = [metalMaterial]
            let tipNode = SCNNode(geometry: tip)
            tipNode.position = SCNVector3(
                dir.0 * Float(armLength),
                dir.1 * Float(armLength),
                dir.2 * Float(armLength)
            )
            jackRoot.addChildNode(tipNode)
        }

        return jackRoot
    }

    private func distance(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    // MARK: - Game Actions

    func dropBall() {
        guard phase == .ready else { return }
        phase = .ballDropped
        canCollect = false
        isBallResting = false

        ballNode.physicsBody?.isAffectedByGravity = true
        ballNode.physicsBody?.velocity = SCNVector3Zero
        ballNode.position = SCNVector3(0, ballDropHeight, 0)
        ballNode.physicsBody?.velocity = SCNVector3(0, 0, 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.phase = .ballBouncing
            self?.startBounceMonitor()
        }
    }

    private func startBounceMonitor() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            var stationaryFrames = 0
            let checkInterval: TimeInterval = 0.05
            let requiredFrames = 8

            while stationaryFrames < requiredFrames {
                Thread.sleep(forTimeInterval: checkInterval)
                guard let velocity = self.ballNode.physicsBody?.velocity else { break }
                let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
                if speed < 0.15 {
                    stationaryFrames += 1
                } else {
                    stationaryFrames = 0
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.phase = .collecting
                self.canCollect = true
                self.isBallResting = true
            }
        }
    }

    func collectJack(at index: Int) {
        guard phase == .collecting, index < jackNodes.count else { return }
        let node = jackNodes[index]
        guard !node.isHidden else { return }

        let fadeOut = SCNAction.group([
            SCNAction.scale(to: 0, duration: 0.2),
            SCNAction.fadeOut(duration: 0.2),
            SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.2)
        ])

        node.runAction(fadeOut) { [weak self] in
            node.isHidden = true
            DispatchQueue.main.async {
                self?.pickedUpCount += 1
                self?.score += 10
            }
        }
    }

    func stopCollecting() {
        guard phase == .collecting else { return }
        if pickedUpCount >= totalJacks {
            phase = .gameOver
        } else {
            completeRound()
        }
    }

    private func completeRound() {
        phase = .roundComplete
        round += 1

        ballNode.physicsBody?.isAffectedByGravity = false
        ballNode.physicsBody?.velocity = SCNVector3Zero
        ballNode.physicsBody?.angularVelocity = SCNVector4Zero

        let resetAction = SCNAction.move(to: SCNVector3(0, ballRestY, 0), duration: 0.4)
        resetAction.timingMode = .easeInEaseOut
        ballNode.runAction(resetAction) { [weak self] in
            DispatchQueue.main.async {
                self?.canCollect = false
                self?.phase = .ready
            }
        }
    }

    func resetGame() {
        score = 0
        round = 1
        pickedUpCount = 0
        phase = .ready
        canCollect = false
        isBallResting = false

        ballNode.physicsBody?.isAffectedByGravity = false
        ballNode.physicsBody?.velocity = SCNVector3Zero
        ballNode.physicsBody?.angularVelocity = SCNVector4Zero
        ballNode.position = SCNVector3(0, ballRestY, 0)
        ballNode.scale = SCNVector3(1, 1, 1)
        ballNode.opacity = 1

        for node in jackNodes {
            node.isHidden = false
            node.scale = SCNVector3(1, 1, 1)
            node.opacity = 1
        }

        scatterJacks()
    }

    // MARK: - Physics Contact

    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Ball hitting the floor creates the bounce sound opportunity
    }
}

// MARK: - SceneKit View Representable

#if canImport(UIKit)
struct JacksSceneView: UIViewRepresentable {
    @ObservedObject var coordinator: JacksSceneCoordinator
    var onTapJack: ((Int) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = coordinator.scene
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .clear
        scnView.isPlaying = true

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(SceneViewCoordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> SceneViewCoordinator {
        SceneViewCoordinator(onTapJack: onTapJack)
    }

    class SceneViewCoordinator: NSObject {
        var onTapJack: ((Int) -> Void)?
        init(onTapJack: ((Int) -> Void)?) {
            self.onTapJack = onTapJack
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.all.rawValue,
                .boundingBoxOnly: false
            ])

            for result in hitResults {
                if let jackIndex = findJackIndex(for: result.node) {
                    onTapJack?(jackIndex)
                    return
                }
            }
        }

        private func findJackIndex(for node: SCNNode) -> Int? {
            var current: SCNNode? = node
            while let n = current {
                if let name = n.name, name.hasPrefix("jack_"),
                   let idx = Int(name.replacingOccurrences(of: "jack_", with: "")) {
                    return idx
                }
                current = n.parent
            }
            return nil
        }
    }
}
#elseif canImport(AppKit)
struct JacksSceneView: NSViewRepresentable {
    @ObservedObject var coordinator: JacksSceneCoordinator
    var onTapJack: ((Int) -> Void)?

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = coordinator.scene
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isPlaying = true

        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(SceneViewCoordinator.handleClick(_:)))
        scnView.addGestureRecognizer(clickGesture)

        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {}

    func makeCoordinator() -> SceneViewCoordinator {
        SceneViewCoordinator(onTapJack: onTapJack)
    }

    class SceneViewCoordinator: NSObject {
        var onTapJack: ((Int) -> Void)?
        init(onTapJack: ((Int) -> Void)?) {
            self.onTapJack = onTapJack
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.all.rawValue,
                .boundingBoxOnly: false
            ])

            for result in hitResults {
                if let jackIndex = findJackIndex(for: result.node) {
                    onTapJack?(jackIndex)
                    return
                }
            }
        }

        private func findJackIndex(for node: SCNNode) -> Int? {
            var current: SCNNode? = node
            while let n = current {
                if let name = n.name, name.hasPrefix("jack_"),
                   let idx = Int(name.replacingOccurrences(of: "jack_", with: "")) {
                    return idx
                }
                current = n.parent
            }
            return nil
        }
    }
}
#endif

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
                Text("\(coordinator.pickedUpCount)/10 Jacks")
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

            HStack(spacing: 20) {
                switch coordinator.phase {
                case .ready:
                    actionButton(title: "Drop Ball", icon: "arrow.down.circle.fill", color: .orange) {
                        coordinator.dropBall()
                    }
                case .ballDropped, .ballBouncing:
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Ball bouncing...")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                case .collecting:
                    actionButton(title: "Stop & Grab Ball", icon: "hand.raised.fill", color: .green) {
                        coordinator.stopCollecting()
                    }
                    Text("Tap jacks to pick them up!")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                case .roundComplete:
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Resetting ball...")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                case .gameOver:
                    actionButton(title: "Play Again", icon: "arrow.counterclockwise", color: .blue) {
                        coordinator.resetGame()
                    }
                }
            }
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
        case .ready: return .blue
        case .ballDropped, .ballBouncing: return .orange
        case .collecting: return .green
        case .roundComplete: return .purple
        case .gameOver: return .red
        }
    }

    private var phaseText: String {
        switch coordinator.phase {
        case .ready: return "Ready - Press Drop Ball to start"
        case .ballDropped: return "Ball dropped!"
        case .ballBouncing: return "Wait for the ball to settle..."
        case .collecting: return "Tap jacks to collect them!"
        case .roundComplete: return "Round complete!"
        case .gameOver: return "All jacks collected!"
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

            Text("You collected all 10 jacks!")
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
