import SceneKit

// MARK: - Game Configuration

struct JacksGameConfig {
    // Ball physics
    static let ballRadius: CGFloat = 0.15
    static let ballMass: CGFloat = 0.15
    static let ballRestitution: CGFloat = 0.85
    static let ballFriction: CGFloat = 0.4
    static let ballRollingFriction: CGFloat = 0.1
    static let ballDamping: CGFloat = 0.08
    static let ballAngularDamping: CGFloat = 0.1
    static let ballDropHeight: Float = 8.0
    static let ballRestY: Float = 0.15

    // Floor physics
    static let floorRestitution: CGFloat = 0.7
    static let floorFriction: CGFloat = 0.6

    // Jack configuration
    static let totalJacks = 10
    static let jackArmLength: CGFloat = 0.1
    static let jackArmRadius: CGFloat = 0.018
    static let jackTipRadius: CGFloat = 0.028
    static let jackCenterRadius: CGFloat = 0.04
    static let jackHitRadius: CGFloat = 0.18
    static let jackMinDistance: Float = 0.45
    static let jackScatterRadiusMin: Float = 0.6
    static let jackScatterRadiusMax: Float = 2.8

    // Bounce detection
    static let bounceCheckInterval: TimeInterval = 0.05
    static let bounceRequiredFrames = 8
    static let bounceSpeedThreshold: Float = 0.15

    // Animation durations
    static let jackFadeOutDuration: TimeInterval = 0.2
    static let jackPickUpHeight: Float = 0.3
    static let ballResetDuration: TimeInterval = 0.4

    // Camera setup
    static let cameraFOV: CGFloat = 50
    static let cameraNear: CGFloat = 0.1
    static let cameraFar: CGFloat = 100
    static let cameraPosition = SCNVector3(0, 4.5, 6)
    static let cameraAngle = SCNVector3(-Float.pi / 5.5, 0, 0)

    // Physics bitmasks
    enum PhysicsBitMask: Int {
        case floor = 1
        case ball = 2
        case jacks = 4
    }

    // Score
    static let jackPointValue = 10
}

// MARK: - Color Palette

struct JacksColorPalette {
    static let skyColor = JacksColorPalette.color(r: 0.15, g: 0.12, b: 0.1)
    static let floorColor = JacksColorPalette.color(r: 0.55, g: 0.35, b: 0.18)
    static let floorLineColor = JacksColorPalette.color(r: 0.35, g: 0.22, b: 0.12)
    static let ballColor = JacksColorPalette.color(r: 0.85, g: 0.15, b: 0.15)
    static let ballSpecular = JacksColorPalette.color(r: 1.0, g: 1.0, b: 1.0)
    static let jackMetalColor = JacksColorPalette.color(r: 0.75, g: 0.75, b: 0.78)
    static let jackSpecular = JacksColorPalette.color(r: 1.0, g: 1.0, b: 1.0)
    static let lightColor = JacksColorPalette.color(r: 1.0, g: 0.95, b: 0.85)
    static let ambientColor = JacksColorPalette.color(r: 0.9, g: 0.85, b: 0.75)
    static let fillLightColor = JacksColorPalette.color(r: 0.8, g: 0.85, b: 1.0)
    static let floorSpecular = JacksColorPalette.color(r: 0.3, g: 0.2, b: 0.1)

    static func color(r: CGFloat, g: CGFloat, b: CGFloat) -> Any {
        #if canImport(UIKit)
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        #elseif canImport(AppKit)
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        #else
        return SCNVector4(r, g, b, 1.0)
        #endif
    }
}

// MARK: - Material Factories

struct MaterialFactory {
    static func createMetalMaterial(diffuseColor: Any) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuseColor
        material.metalness.contents = 0.95
        material.roughness.contents = 0.15
        material.specular.contents = JacksColorPalette.jackSpecular
        material.fresnelExponent = 5.0
        return material
    }

    static func createWoodMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = JacksColorPalette.floorColor
        material.roughness.contents = 0.7
        material.metalness.contents = 0.0
        material.normal.intensity = 0.4
        material.specular.contents = JacksColorPalette.floorSpecular
        return material
    }

    static func createBallMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = JacksColorPalette.ballColor
        material.specular.contents = JacksColorPalette.ballSpecular
        material.roughness.contents = 0.2
        material.metalness.contents = 0.1
        material.fresnelExponent = 2.0
        return material
    }

    static func createTransparentHitMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = JacksColorPalette.color(r: 1, g: 1, b: 1)
        material.transparency = 0.001
        return material
    }
}

// MARK: - Physics Presets

struct PhysicsPresetFactory {
    static func createFloorPhysicsBody() -> SCNPhysicsBody {
        let body = SCNPhysicsBody(type: .static, shape: nil)
        body.restitution = JacksGameConfig.floorRestitution
        body.friction = JacksGameConfig.floorFriction
        body.categoryBitMask = JacksGameConfig.PhysicsBitMask.floor.rawValue
        body.collisionBitMask = JacksGameConfig.PhysicsBitMask.ball.rawValue | JacksGameConfig.PhysicsBitMask.jacks.rawValue
        return body
    }

    static func createBallPhysicsBody() -> SCNPhysicsBody {
        let body = SCNPhysicsBody(type: .dynamic, shape: nil)
        body.mass = JacksGameConfig.ballMass
        body.restitution = JacksGameConfig.ballRestitution
        body.friction = JacksGameConfig.ballFriction
        body.rollingFriction = JacksGameConfig.ballRollingFriction
        body.damping = JacksGameConfig.ballDamping
        body.angularDamping = JacksGameConfig.ballAngularDamping
        body.categoryBitMask = JacksGameConfig.PhysicsBitMask.ball.rawValue
        body.collisionBitMask = JacksGameConfig.PhysicsBitMask.floor.rawValue
        body.contactTestBitMask = JacksGameConfig.PhysicsBitMask.floor.rawValue
        body.isAffectedByGravity = false
        return body
    }

    static func createJackPhysicsBody() -> SCNPhysicsBody {
        let body = SCNPhysicsBody(type: .dynamic, shape: nil)
        body.categoryBitMask = JacksGameConfig.PhysicsBitMask.jacks.rawValue
        body.collisionBitMask = JacksGameConfig.PhysicsBitMask.floor.rawValue
        return body
    }
}
