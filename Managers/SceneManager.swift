//
//  SceneManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit
import SpriteKit

class SceneManager: NSObject, SCNSceneRendererDelegate, ObservableObject {
    weak var gameManager: GameManager?
    var sceneObjects: [SceneObject] = []
    @Published var viewLoaded: Bool = false
    var lastUpdateTime: TimeInterval = .zero
    let view: SCNView
    let scene: SCNScene
    let cameraManager: CameraManager
    let shipManager: ShipManager
    var celestialManager: CelestialManager? = nil
    var objectsPlacedInCameraView: Bool = false
    
    // OBJECT POOLING for EXPLOSION + MISSILE + TRIANGLE objects and nodes
    var explosions: [Explosion] = []
    // Missile Pool
    var missiles: [OSNRMissile] = []
    func createMissiles() {
        for i in 0...10 {
            let missile = OSNRMissile(target: nil, particleSystemColor: .white, sceneManager: self)
            self.missiles.append(missile)
        }
    }
    // Triangle Pool
    var trianglePool: [SKShapeNode] = []
    init(cameraManager: CameraManager, shipManager: ShipManager, scene: SCNScene) {
        self.scene = scene
        self.view = SCNView()
        self.cameraManager = cameraManager
        self.shipManager = shipManager
        super.init()
        self.setupScene()
        self.addShip()
        self.celestialManager = CelestialManager(manager: self)
        self.view.pause(nil)
        self.shipManager.currentRotation = self.shipManager.ship.simdOrientation
        //self.createMissiles()
        self.createAI()
        self.view.prepare([self.scene]) { success in
            self.view.play(nil)
        }
    }
    deinit {
        print("SceneManager is being deallocated")
    }
    
    // Rendering Loop
    @MainActor func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update the game state
        let deltaTime = time - lastUpdateTime
        self.lastUpdateTime = time
        if let manager = self.gameManager {
            if manager.userSelectedContinue {
                self.updateShip(deltaTime: time)
                self.updateCamera(deltaTime: Float(deltaTime))
            } else {
                self.shipManager.updateRotation(deltaTime: deltaTime)
            }
        }
        self.updateSceneObjects(updateAtTime: time)
    }
    func updateSceneObjects(updateAtTime time: TimeInterval) {
        for obj in self.sceneObjects {
            obj.update(updateAtTime: time)
        }
    }
    func setTrackingStatePlayer() {
        self.cameraManager.trackingState = CameraTrackState.player(ship: self.shipManager.ship)
    }
    func updateCamera(deltaTime: Float) {
        self.cameraManager.updateCamera(deltaTime: deltaTime)
    }
    func updateShip(deltaTime: TimeInterval) {
        self.shipManager.update(deltaTime: deltaTime)
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
        self.view.delegate = self
        self.scene.physicsWorld.contactDelegate = self.createPhysicsManager()
    }
    func addShip() {
        self.shipManager.ship.position = SCNVector3(0,3000,-1000)
        self.addNode(self.shipManager.ship)

    }
    func createAI() {
        let num = 10
        let node = ModelManager.createShip(scale: 0.15)
        for i in 0...num {
            let offset: SCNVector3 = SCNVector3(-750,2400 + Float.random(in: -100...100),-750)
            self.createDrone(node: node.flattenedClone(), offset: offset, i: i, faction: .OSNR)
        }
        for i in 0...num {
            let offset: SCNVector3 = SCNVector3(750,2400 + Float.random(in: -100...100),-750)
            self.createDrone(node: node.flattenedClone(), offset: offset, i: i, faction: .Wraith)
        }
    }
    func createDrone(node: SCNNode, offset: SCNVector3, i: Int, faction: Faction) {
        let drone = AI(node: node.clone(), faction: faction, sceneManager: self)
        let vector = SCNVector3(offset.x,offset.y+Float(i),offset.z + Float(i) * 150)
        drone.node.position = vector
        
        self.addNode(drone.node)
        self.sceneObjects.append(drone)
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
    
    
    func createExplosion(at position: SCNVector3) {
        if self.explosions.isEmpty {
            Explosion(at: position, sceneManager: self)
        } else if let explosion = self.explosions.popLast() {
            explosion.setPosition(at: position)
        } else {
            Explosion(at: position, sceneManager: self)
        }
    }
    
    func addNode(_ node: SCNNode) {
        self.view.prepare([node]) { success in
            self.scene.rootNode.addChildNode(node)
        }
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
        let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionEnd])
        self.sceneManager.view.prepare([self.node]) { success in
            self.sceneManager.addNode(self.node)
            self.node.runAction(SCNAction.repeat(pulseSequence, count: 1))
            var distance = Float(abs(self.node.position.distance(to: self.sceneManager.shipManager.ship.position)))
            let maxDistance: Float = 5000; if distance>maxDistance{distance=maxDistance}
            self.sceneManager.gameManager?.audioManager.playExplosion(distance: distance, maxDistance: maxDistance)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.sceneManager.removeNode(self.node)
                self.sceneManager.explosions.append(self)
            }
        }
    }
    func update(updateAtTime time: TimeInterval) {
    }
    func destroy() {
    }
}
protocol Updateable {
    func update(updateAtTime time: TimeInterval)
}
protocol SceneObject: Updateable {
    var node: SCNNode { get set }
    var sceneManager: SceneManager { get set }
    var isAI: Bool { get set }
    var faction: Faction { get set }
    init(node: SCNNode, sceneManager: SceneManager)
    func update(updateAtTime time: TimeInterval)
    func destroy()
}
