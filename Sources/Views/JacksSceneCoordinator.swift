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

    private var isBallResting = false
    private var bounceMonitorTimer: Timer?

    public override init() {
        scene = SCNScene()
        super.init()
        print("🟢 JacksSceneCoordinator.init() called")
        print("🟢 Scene created: \(scene)")
        print("🟢 Scene rootNode: \(scene.rootNode)")
        setupScene()
        print("🟢 setupScene() completed")
        print("🟢 Scene now has \(scene.rootNode.childNodes.count) child nodes")
    }

    deinit {
        bounceMonitorTimer?.invalidate()
    }

    // MARK: - Scene Setup

    private func setupScene() {
        print("🟢 setupScene() starting")
        scene.background.contents = JacksColorPalette.skyColor
        print("🟢 Background set to: \(String(describing: JacksColorPalette.skyColor))")
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scene.physicsWorld.contactDelegate = self

        setupCamera()
        print("🟢 Camera setup complete")
        setupLighting()
        print("🟢 Lighting setup complete")
        setupFloor()
        print("🟢 Floor setup complete, floor node: \(floorNode as Any)")
        setupBall()
        print("🟢 Ball setup complete, ball node: \(ballNode as Any)")
        scatterJacks()
        print("🟢 Jacks scattered, count: \(jackNodes.count)")
    }

    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = JacksGameConfig.cameraFOV
        cameraNode.camera?.zNear = JacksGameConfig.cameraNear
        cameraNode.camera?.zFar = JacksGameConfig.cameraFar
        cameraNode.position = JacksGameConfig.cameraPosition
        cameraNode.eulerAngles = JacksGameConfig.cameraAngle
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupLighting() {
        setupSpotLight()
        setupAmbientLight()
        setupFillLight()
    }

    private func setupSpotLight() {
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
        lightNode.light?.color = JacksColorPalette.lightColor
        lightNode.position = SCNVector3(2, 8, 4)
        lightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(lightNode)
    }

    private func setupAmbientLight() {
        ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 400
        ambientLightNode.light?.color = JacksColorPalette.ambientColor
        scene.rootNode.addChildNode(ambientLightNode)
    }

    private func setupFillLight() {
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.light?.color = JacksColorPalette.fillLightColor
        fillLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)
    }

    private func setupFloor() {
        let floorGeometry = SCNFloor()
        let woodMaterial = MaterialFactory.createWoodMaterial()
        floorGeometry.reflectivity = 0.05
        floorGeometry.materials = [woodMaterial]

        floorNode = SCNNode(geometry: floorGeometry)
        floorNode.position = SCNVector3(0, 0, 0)

        let floorShape = SCNPhysicsShape(geometry: floorGeometry, options: nil)
        let floorBody = PhysicsPresetFactory.createFloorPhysicsBody()
        floorBody.physicsShape = floorShape
        floorNode.physicsBody = floorBody
        floorNode.name = "floor"
        scene.rootNode.addChildNode(floorNode)

        addFloorPlankLines()
    }

    private func addFloorPlankLines() {
        let plankWidth: CGFloat = 1.2
        for i in -4...4 {
            let lineGeometry = SCNBox(width: 0.02, height: 0.001, length: 12, chamferRadius: 0)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = JacksColorPalette.floorLineColor
            lineGeometry.materials = [lineMaterial]
            let lineNode = SCNNode(geometry: lineGeometry)
            lineNode.position = SCNVector3(Float(i) * Float(plankWidth), 0.002, 0)
            scene.rootNode.addChildNode(lineNode)
        }
    }

    // MARK: - Ball

    private func setupBall() {
        let ballGeometry = SCNSphere(radius: JacksGameConfig.ballRadius)
        let ballMaterial = MaterialFactory.createBallMaterial()
        ballGeometry.materials = [ballMaterial]

        ballNode = SCNNode(geometry: ballGeometry)
        ballNode.position = SCNVector3(0, JacksGameConfig.ballRestY, 0)
        ballNode.name = "ball"

        let ballShape = SCNPhysicsShape(geometry: ballGeometry, options: nil)
        let ballBody = PhysicsPresetFactory.createBallPhysicsBody()
        ballBody.physicsShape = ballShape
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

        for i in 0..<JacksGameConfig.totalJacks {
            var pos: SIMD2<Float>
            var attempts = 0
            repeat {
                let angle = Float.random(in: 0...(2 * .pi))
                let radius = Float.random(in: JacksGameConfig.jackScatterRadiusMin...JacksGameConfig.jackScatterRadiusMax)
                pos = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
                attempts += 1
            } while attempts < 50 && positions.contains(where: { distance($0, pos) < JacksGameConfig.jackMinDistance })
            positions.append(pos)

            let jackNode = createJackNode(index: i)
            jackNode.position = SCNVector3(pos.x, 0.12, pos.y)
            jackNode.eulerAngles = SCNVector3(
                Float.random(in: -0.3...0.3),
                Float.random(in: 0...(2 * .pi)),
                Float.random(in: -0.3...0.3)
            )

            scene.rootNode.addChildNode(jackNode)
            jackNodes.append(jackNode)
        }
    }

    private func createJackNode(index: Int) -> SCNNode {
        let jackRoot = SCNNode()
        jackRoot.name = "jack_\(index)"

        let metalMaterial = MaterialFactory.createMetalMaterial(diffuseColor: JacksColorPalette.jackMetalColor)

        let centerSphere = SCNSphere(radius: JacksGameConfig.jackCenterRadius)
        centerSphere.segmentCount = 16
        centerSphere.materials = [metalMaterial]
        let centerNode = SCNNode(geometry: centerSphere)
        jackRoot.addChildNode(centerNode)

        let directions: [(Float, Float, Float)] = [
            (1, 0, 0), (-1, 0, 0),
            (0, 1, 0), (0, -1, 0),
            (0, 0, 1), (0, 0, -1)
        ]

        for dir in directions {
            let arm = SCNCylinder(radius: JacksGameConfig.jackArmRadius, height: JacksGameConfig.jackArmLength)
            arm.radialSegmentCount = 8
            arm.materials = [metalMaterial]
            let armNode = SCNNode(geometry: arm)

            let halfLen = Float(JacksGameConfig.jackArmLength) / 2
            armNode.position = SCNVector3(dir.0 * halfLen, dir.1 * halfLen, dir.2 * halfLen)

            if dir.0 != 0 {
                armNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            } else if dir.2 != 0 {
                armNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            }

            jackRoot.addChildNode(armNode)

            let tip = SCNSphere(radius: JacksGameConfig.jackTipRadius)
            tip.segmentCount = 12
            tip.materials = [metalMaterial]
            let tipNode = SCNNode(geometry: tip)
            tipNode.position = SCNVector3(
                dir.0 * Float(JacksGameConfig.jackArmLength),
                dir.1 * Float(JacksGameConfig.jackArmLength),
                dir.2 * Float(JacksGameConfig.jackArmLength)
            )
            jackRoot.addChildNode(tipNode)
        }

        let hitSphere = SCNSphere(radius: JacksGameConfig.jackHitRadius)
        hitSphere.materials = [MaterialFactory.createTransparentHitMaterial()]
        let hitNode = SCNNode(geometry: hitSphere)
        hitNode.name = "jack_hit_\(index)"
        jackRoot.addChildNode(hitNode)

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

        ballNode.physicsBody?.clearAllForces()
        ballNode.physicsBody?.velocity = SCNVector3Zero
        ballNode.physicsBody?.angularVelocity = SCNVector4Zero
        ballNode.physicsBody?.isAffectedByGravity = false

        ballNode.position = SCNVector3(0, JacksGameConfig.ballDropHeight, 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.ballNode.physicsBody?.isAffectedByGravity = true
            self.phase = .ballBouncing
            self.startBounceMonitor()
        }
    }

    private func startBounceMonitor() {
        bounceMonitorTimer?.invalidate()
        var stationaryFrames = 0

        bounceMonitorTimer = Timer.scheduledTimer(withTimeInterval: JacksGameConfig.bounceCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            guard let velocity = self.ballNode.physicsBody?.velocity else {
                self.bounceMonitorTimer?.invalidate()
                return
            }

            let speed = Float(sqrt(CGFloat(velocity.x) * CGFloat(velocity.x) + CGFloat(velocity.y) * CGFloat(velocity.y) + CGFloat(velocity.z) * CGFloat(velocity.z)))
            
            if speed < Float(JacksGameConfig.bounceSpeedThreshold) {
                stationaryFrames += 1
            } else {
                stationaryFrames = 0
            }

            if stationaryFrames >= JacksGameConfig.bounceRequiredFrames {
                self.bounceMonitorTimer?.invalidate()
                self.ballRestDetected()
            }
        }
    }

    private func ballRestDetected() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.phase = .collecting
            self.canCollect = true
            self.isBallResting = true
        }
    }

    func collectJack(at index: Int) {
        guard phase == .collecting, index < jackNodes.count else { return }
        let node = jackNodes[index]
        guard !node.isHidden else { return }

        let fadeOut = SCNAction.group([
            SCNAction.scale(to: 0, duration: JacksGameConfig.jackFadeOutDuration),
            SCNAction.fadeOut(duration: JacksGameConfig.jackFadeOutDuration),
            SCNAction.moveBy(x: 0, y: CGFloat(JacksGameConfig.jackPickUpHeight), z: 0, duration: JacksGameConfig.jackFadeOutDuration)
        ])

        node.runAction(fadeOut) { [weak self] in
            node.isHidden = true
            DispatchQueue.main.async {
                self?.pickedUpCount += 1
                self?.score += JacksGameConfig.jackPointValue
            }
        }
    }

    func stopCollecting() {
        guard phase == .collecting else { return }
        if pickedUpCount >= JacksGameConfig.totalJacks {
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

        let resetAction = SCNAction.move(to: SCNVector3(0, JacksGameConfig.ballRestY, 0), duration: JacksGameConfig.ballResetDuration)
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
        ballNode.position = SCNVector3(0, JacksGameConfig.ballRestY, 0)
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
