//
//  SceneManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

class SceneManager: NSObject, SCNSceneRendererDelegate, ObservableObject {
    weak var gameManager: GameManager?
    var sceneObjects: [SceneObject] = []
    var viewLoaded: Bool = false
    var lastUpdateTime: TimeInterval = .zero
    let view: SCNView
    let scene: SCNScene
    let cameraManager: CameraManager
    let shipManager: ShipManager
    var objectsPlacedInCameraView: Bool = false
    init(cameraManager: CameraManager, shipManager: ShipManager, scene: SCNScene) {
        self.scene = scene
        self.view = SCNView()
        self.cameraManager = cameraManager
        self.shipManager = shipManager
        super.init()
        self.setupScene()
        self.addShip()
        self.createPlanet(name: "base.jpg")
        self.createStar()
        self.createAI()
        self.view.prepare([self.scene]) { success in
            print("prepared!")
            self.viewLoaded = true
            print(self.viewLoaded)
        }
    }
    deinit {
        print("SceneManager is being deallocated")
    }
    // Rendering Loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update the game state
        let deltaTime = time - lastUpdateTime
        //self.updateObjectPositions()
        self.lastUpdateTime = time
        self.updateShip(deltaTime: time)
        self.updateCamera(deltaTime: Float(deltaTime))
        self.updateSceneObjects()
    }
    func updateSceneObjects() {
        for obj in self.sceneObjects {
            obj.update()
        }
    }
    func updateCamera(deltaTime: Float) {
        self.cameraManager.updateCamera(for: CameraTrackState.player(ship: self.shipManager.ship), deltaTime: deltaTime)
    }
    func updateShip(deltaTime: TimeInterval) {
        self.shipManager.update(deltaTime: deltaTime)
    }
    func updateObjectPositions() {
        let playerPosition = self.shipManager.ship.position
        
        // Calculate distance from the origin
        let distanceFromOrigin = sqrt(pow(playerPosition.x, 2) + pow(playerPosition.y, 2) + pow(playerPosition.z, 2))
        
        if distanceFromOrigin > 200_000 {
            // Update positions of all scene objects relative to the player.
            for object in self.sceneObjects {
                if object is OSNRMissile || object is Explosion {
                    object.node.removeFromParentNode()
                    self.sceneObjects.removeAll(where: {$0.node==object.node})
                } else {
                    object.node.position = object.node.position - playerPosition
                }
            }
            self.sceneObjects.removeAll(where: { $0 is OSNRMissile || $0 is Explosion })
            self.shipManager.ship.position = SCNVector3Zero
        }
    }
    var physicsManager: PhysicsManager? // This is a strong reference
    
    func createPhysicsManager() -> PhysicsManager {
        let manager = PhysicsManager(sceneManager: self)
        self.physicsManager = manager // Hold a strong reference
        return manager
    }
    // Scene Creation
    func setupScene() {
        self.view.scene = self.scene
        self.createSkybox()
        self.view.delegate = self
        self.scene.physicsWorld.contactDelegate = self.createPhysicsManager()
    }
    func addShip() {
        self.shipManager.ship.position = SCNVector3(-2000,2500,-2000)
        self.addNode(self.shipManager.ship)
    }
    func createAI() {
        let num = 8
        let node = ModelManager.createShip(scale: 0.05)
        for i in 0...num {
            let drone = AI(node: node.clone(), faction: .OSNR, sceneManager: self)
            let vector = SCNVector3(-500,1800 + i,-1900 + i*100)
            drone.node.position = vector
            
            self.addNode(drone.node)
            self.sceneObjects.append(drone)
        }
        for i in 0...num {
            let drone = AI(node: node.clone(), faction: .Wraith, sceneManager: self)
            let vector = SCNVector3(500,1800 + i,-1900 + i*100)
            drone.node.position = vector
            
            self.addNode(drone.node)
            self.sceneObjects.append(drone)
        }
    }
    func createBlackHoles(around planet: Planet, count: Int) {
        for _ in 0..<count {
            let randomPoint = generateRandomPointInSphere(with: Float(planet.sphere.radius * 4))
            let blackHole = BlackHole(scene: self.scene, view: self.view, radius: CGFloat.random(in: 10...50), camera: self.cameraManager.cameraNode, ringCount: Int.random(in: 5...15), vibeOffset: Int.random(in: 1...2), bothRings: false, vibe: ShaderVibe.discOh, period: 20, shipNode: self.shipManager.ship)
            blackHole.blackHoleNode.position = randomPoint + planet.node.position
            self.addNode(blackHole.blackHoleNode)
        }
    }
    func generateRandomPointInSphere(with radius: Float) -> SCNVector3 {
        let u = Float.random(in: 0...1)
        let v = Float.random(in: 0...1)
        let theta = 2 * Float.pi * u
        let phi = acos(2 * v - 1)
        let x = radius * sin(phi) * cos(theta)
        let y = radius * sin(phi) * sin(theta)
        let z = radius * cos(phi)
        return SCNVector3(x, y, z)
    }
    
    public func createStar() {
        let star = Star(radius: 1_000, color: .orange, sceneManager: self)
        star.node.position = SCNVector3(0, 1_500, 100_000)
        self.sceneObjects.append(star)
        self.addNode(star.node)
    }
    public func createPlanet(name: String) {
        guard let image = UIImage(named: name) else {
            print("Failed to create planet from imagename \(name)")
            return
        }
        let planet = Planet(image: image, radius: 1750, view: self.view, asteroidBeltImage: image, sceneManager: self)
        planet.node.castsShadow = true
        self.sceneObjects.append(planet)
        planet.addToScene(scene: self.scene)
        //self.createBlackHoles(around: planet, count: 10)
        self.shipManager.ship.look(at: planet.node.position)
        self.shipManager.currentRotation = self.shipManager.ship.simdOrientation
    }
    public func createEarth() {
        guard let image = UIImage(named: "Earth.jpg") else {
            return
        }
        let planet = Planet(image: image, radius: 10_000, view: self.view, asteroidBeltImage: image, sceneManager: self)
        planet.node.castsShadow = true
        planet.node.position = SCNVector3(-5_000, -15_000, 15000)
        self.sceneObjects.append(planet)
        planet.addToScene(scene: self.scene)
    }
    func createSkybox() {
        self.view.allowsCameraControl = false
        self.view.backgroundColor = UIColor.black
        self.view.scene?.background.contents = [
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky")
        ]
        self.view.scene?.background.intensity = 0.5
    }
    
    // OBJECT POOLING for EXPLOSION and MISSILE objects
    var explosions: [Explosion] = []
    func createExplosion(at position: SCNVector3) {
        if self.explosions.isEmpty {
            Explosion(at: position, sceneManager: self)
        } else if let explosion = self.explosions.popLast() {
            explosion.setPosition(at: position)
        } else {
            Explosion(at: position, sceneManager: self)
        }
    }
    var missiles: [OSNRMissile] = []
    func addNode(_ node: SCNNode) {
        self.scene.rootNode.addChildNode(node)
    }
    func removeNode(_ node: SCNNode) {
        node.removeFromParentNode()
    }
}
class Explosion: SceneObject {
    var node: SCNNode = SCNNode()
    var sceneManager: SceneManager
    var isAI: Bool = false
    var faction: Faction = .Celestial
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.node = node
        self.sceneManager = sceneManager
    }
    init(at position: SCNVector3, sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        self.node = SCNNode()
        self.node.position = position
        self.node.addParticleSystem(ParticleManager.explosionParticleSystem)
        self.explode()
    }
    func setPosition(at position: SCNVector3) {
        self.node.position = position
        self.explode()
    }
    func explode() {
        let implodeAction = SCNAction.scale(to: 5, duration: 0.40)
        let implodeActionStep = SCNAction.scale(to: 2.5, duration: 1)
        let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
        self.sceneManager.view.prepare([self.node]) { success in
            self.sceneManager.addNode(self.node)
            self.node.runAction(SCNAction.repeat(pulseSequence, count: 1))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.sceneManager.removeNode(self.node)
                self.sceneManager.explosions.append(self)
            }
        }
    }
    func update() {
    }
    func destroy() {
    }
}
protocol Updateable {
    func update()
}
protocol SceneObject: Updateable {
    var node: SCNNode { get set }
    var sceneManager: SceneManager { get set }
    var isAI: Bool { get set }
    var faction: Faction { get set }
    init(node: SCNNode, sceneManager: SceneManager)
    func update()
    func destroy()
}
