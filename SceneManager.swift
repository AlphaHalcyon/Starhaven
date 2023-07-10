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
    var objectsPlacedInCameraView: Bool = false
    
    // OBJECT POOLING for EXPLOSION + MISSILE + TRIANGLE objects and nodes
    var explosions: [Explosion] = []
    // Missile Pool
    var missiles: [OSNRMissile] = []
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
        self.createPlanet(name: "base.jpg")
        self.createStar()
        self.createBlackHoles()
        self.createAI()
    }
    deinit {
        print("SceneManager is being deallocated")
    }
    var blackHoles: [SCNNode] = []
    let blackHoleCount: Int = 15
    func createBlackHoles() {
        for _ in 0...self.blackHoleCount {
            self.createBlackHole()
        }
    }
    func createBlackHole() {
        let blackHole: SCNNode = BH.blackHole(pov: self.cameraManager.cameraNode).clone()
        let pos = SCNVector3(0, 2_000,0)
        blackHole.position = pos
        self.blackHoles.append(blackHole)
        self.view.prepare([blackHole]) { success in
            self.addNode(blackHole)
        }
    }
    func distributeBlackHoles() {
        for blackHole in blackHoles {
            let pos = self.generateRandomPointInSphere(with: 15_000)
            blackHole.position = pos
        }
    }
    // Rendering Loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update the game state
        let deltaTime = time - lastUpdateTime
        self.lastUpdateTime = time
        self.updateShip(deltaTime: time)
        self.updateCamera(deltaTime: Float(deltaTime))
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
        self.createSkybox()
        self.view.delegate = self
        self.scene.physicsWorld.contactDelegate = self.createPhysicsManager()
    }
    func addShip() {
        self.shipManager.ship.position = SCNVector3(0,3000,-1000)
        self.addNode(self.shipManager.ship)

    }
    func createAI() {
        let num = 15
        let node = ModelManager.createShip(scale: 0.15)
        for i in 0...num {
            let offset: SCNVector3 = SCNVector3(-500,2200,-500)
            self.createDrone(node: node.flattenedClone(), offset: offset, i: i, faction: .OSNR)
        }
        for i in 0...num {
            let offset: SCNVector3 = SCNVector3(500,2200,-500)
            self.createDrone(node: node.flattenedClone(), offset: offset, i: i, faction: .Wraith)
        }
    }
    func createDrone(node: SCNNode, offset: SCNVector3, i: Int, faction: Faction) {
        let drone = AI(node: node.clone(), faction: faction, sceneManager: self)
        let vector = SCNVector3(offset.x,offset.y+Float(i),offset.z + Float(i) * 100)
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
    
    public func createStar() {
        let star = Star(radius: 1_000, color: .orange, sceneManager: self)
        star.node.position = SCNVector3(0, 1_500, 150_000)
        self.sceneObjects.append(star)
        self.addNode(star.node)
    }
    public func createPlanet(name: String) {
        guard let image = UIImage(named: name) else {
            print("Failed to create planet from imagename \(name)")
            return
        }
        let planet = Planet(image: image, radius: 2000, view: self.view, asteroidBeltImage: image, sceneManager: self)
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
