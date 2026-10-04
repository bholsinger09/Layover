import SwiftUI
import SceneKit

// MARK: - Platform-Agnostic Gesture Coordinator

class BaseSceneViewCoordinator: NSObject {
    var onTapJack: ((Int) -> Void)?
    private var collectedIndices: Set<Int> = []

    init(onTapJack: ((Int) -> Void)?) {
        self.onTapJack = onTapJack
    }

    func hitTestForJack(in scnView: SCNView, at location: CGPoint) -> Int? {
        let hitResults = scnView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .boundingBoxOnly: false
        ])
        
        for result in hitResults {
            if let jackIndex = findJackIndex(for: result.node) {
                return jackIndex
            }
        }
        return nil
    }

    func findJackIndex(for node: SCNNode) -> Int? {
        var current: SCNNode? = node
        while let n = current {
            if let name = n.name, name.hasPrefix("jack_") {
                let indexStr = name.replacingOccurrences(of: "jack_", with: "")
                    .replacingOccurrences(of: "hit_", with: "")
                return Int(indexStr)
            }
            current = n.parent
        }
        return nil
    }

    func trackCollection(_ index: Int) {
        collectedIndices.insert(index)
    }

    func resetTracking() {
        collectedIndices.removeAll()
    }

    func wasAlreadyCollected(_ index: Int) -> Bool {
        collectedIndices.contains(index)
    }
}

#if canImport(UIKit)

// MARK: - iOS Implementation

struct JacksSceneView: UIViewRepresentable {
    @ObservedObject var coordinator: JacksSceneCoordinator
    var onTapJack: ((Int) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        print("🟢 JacksSceneView.makeUIView() called")
        print("🟢 coordinator.scene: \(coordinator.scene)")
        print("🟢 coordinator.scene.rootNode.childNodes.count: \(coordinator.scene.rootNode.childNodes.count)")
        
        let scnView = SCNView()
        scnView.scene = coordinator.scene
        print("🟢 Scene assigned to SCNView")
        print("🟢 SCNView.scene: \(scnView.scene)")
        print("🟢 SCNView.scene?.rootNode.childNodes.count: \(scnView.scene?.rootNode.childNodes.count ?? -1)")
        
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .clear
        scnView.isPlaying = true
        
        print("🟢 SCNView configuration complete")

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(IOSSceneViewCoordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(IOSSceneViewCoordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        print("🟢 JacksSceneView.makeUIView() completed, returning SCNView")

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> IOSSceneViewCoordinator {
        IOSSceneViewCoordinator(onTapJack: onTapJack)
    }
}

class IOSSceneViewCoordinator: BaseSceneViewCoordinator {
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let scnView = gesture.view as? SCNView else { return }
        let location = gesture.location(in: scnView)
        if let jackIndex = hitTestForJack(in: scnView, at: location) {
            onTapJack?(jackIndex)
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let scnView = gesture.view as? SCNView else { return }
        let location = gesture.location(in: scnView)

        switch gesture.state {
        case .began:
            resetTracking()
            if let jackIndex = hitTestForJack(in: scnView, at: location) {
                trackCollection(jackIndex)
                onTapJack?(jackIndex)
            }
        case .changed:
            if let jackIndex = hitTestForJack(in: scnView, at: location),
               !wasAlreadyCollected(jackIndex) {
                trackCollection(jackIndex)
                onTapJack?(jackIndex)
            }
        case .ended, .cancelled:
            resetTracking()
        default:
            break
        }
    }
}

#elseif canImport(AppKit)

// MARK: - macOS Implementation

struct JacksSceneView: NSViewRepresentable {
    @ObservedObject var coordinator: JacksSceneCoordinator
    var onTapJack: ((Int) -> Void)?

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = coordinator.scene
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isPlaying = true

        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(MacOSSceneViewCoordinator.handleClick(_:)))
        scnView.addGestureRecognizer(clickGesture)

        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {}

    func makeCoordinator() -> MacOSSceneViewCoordinator {
        MacOSSceneViewCoordinator(onTapJack: onTapJack)
    }
}

class MacOSSceneViewCoordinator: BaseSceneViewCoordinator {
    @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
        guard let scnView = gesture.view as? SCNView else { return }
        let location = gesture.location(in: scnView)
        if let jackIndex = hitTestForJack(in: scnView, at: location) {
            onTapJack?(jackIndex)
        }
    }
}

#endif
