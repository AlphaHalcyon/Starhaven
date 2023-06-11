//
//  SpacegroundViewModel.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit
import simd
import CoreImage
import AVFoundation

@MainActor class SpacegroundViewModel: NSObject, ObservableObject, SCNSceneRendererDelegate, SCNPhysicsContactDelegate  {
    // View and Scene
    @Published var view: SCNView
    @Published var scene: SCNScene = SCNScene()
    @Published var cameraNode: SCNNode
    @Published var gameOver: Bool = false
    // Player Ship and Navigation
    @Published var ship: Ship
    @Published var currentRotation = simd_quatf(angle: .pi, axis: simd_float3(x: 0, y: 1, z: 0))
    @Published var rotationDeltaX: Float = 0
    @Published var rotationDeltaY: Float = 0
    @Published var rotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var isRotationActive: Bool = false
    @Published var isDragging: Bool = false
    @Published var isPressed: Bool = false
    @Published var isInverted: Bool = false
    // Nav. control extensions
    @Published var previousTranslation: CGSize = CGSize.zero
    @Published var longPressTimer: Bool = false
    @Published var averageRotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var rotationVelocityBufferX: VelocityBuffer = VelocityBuffer(bufferCapacity: 1)
    @Published var rotationVelocityBufferY: VelocityBuffer = VelocityBuffer(bufferCapacity: 1)
    // Weapon systems
    @Published var missiles: [Missile] = []
    @Published var weaponType: String = "Missile"
    @Published var inMissileView: Bool = false
    @Published var cameraMissile: Missile?
    @Published var boundingBoxNode: SCNNode? = nil
    @Published var fireCooldown: Bool = false
    // Black Holes
    @Published var blackHoles: [BlackHole] = []
    @Published var closestBlackHole: BlackHole?
    @Published var distanceToBlackHole: CGFloat = .greatestFiniteMagnitude

    // Enemies
    @Published var ghosts: [Raider] = []
    @Published var raiders: [Raider] = []
    @Published var closestEnemy: SCNNode? = nil
    @Published var currentTime: TimeInterval = 0

    // Scoring
    @Published var points: Int = 0
    @Published var showScoreIncrement: Bool = false
    @Published var showKillIncrement: Bool = false

    // Helper View Model
    @Published var ecosystems: [Ecosystem] = []
    
    // Loading Sequence
    @Published var loadingSceneView: Bool = true
    
    // Audio
    @Published var audioPlayer: AVAudioPlayer = AVAudioPlayer()
    @Published var musicPlayer: AVAudioPlayer = AVAudioPlayer()
    
    // Settings
    @Published var skyboxIntensity: Float = 0
    @Published var distanceFromShip: Float = 25
    @Published var missileLockEnabled: Bool = false
    public func toggleMissileLock() {
        self.missileLockEnabled.toggle()
    }
    public func setSkyboxIntensity(intensity: Float) {
        self.skyboxIntensity = intensity
    }
    public func setDistanceFromShip(distance: Float) {
        self.distanceFromShip = distance
    }
    init(view: SCNView, cameraNode: SCNNode) {
        // Initialize all properties
        self.view = view
        self.cameraNode = cameraNode
        self.ship = Ship(view: view, cameraNode: cameraNode)

        // Call super.init()
        super.init()

        // Now you can call methods or use closures that reference self
        self.setupCamera()
        self.view.prepare([self.cameraNode]) { [weak self] success in
            guard let self = self else { return }
            self.scene.rootNode.addChildNode(self.cameraNode)
        }
        self.audioPlayer.volume = 0.24
        self.musicPlayer.volume = 0.25
    }
    // Rendering Loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if !self.inMissileView {
            self.updateShipPosition()
        } else {
            if let missile = self.cameraMissile {
                self.updateCameraMissile(node: missile.missileNode)
            }
        }
        //self.boundingBoxUpdate()
        Task {
            for ghost in self.ghosts {
                ghost.updateAI()
            }
        }
        Task {
            for missile in self.missiles {
                missile.trackTarget()
            }
        }
        Task {
            self.currentTime += 1/60
        }
    }
    @MainActor func makeSpaceView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = self.scene
        scnView.rendersContinuously = true
        self.playMusic()
        self.createShip(scnView: scnView)
        self.updateShipPosition()
        self.createEcosystem()
        self.createSkybox(scnView: scnView)
        scnView.delegate = self
        scnView.prepare(self.scene)
        Task {
            self.view = scnView
        }
        return scnView
    }
    // WORLD CREATION
    public func createStar() {
        let star = Star(radius: 200_000, color: .orange, camera: self.cameraNode)
        star.starNode.position = SCNVector3(1000, 100_000, 2_000_000)
        self.scene.rootNode.addChildNode(star.starNode)
    }
    public func createPlanet(name: String) {
        let planet = Planet(image: UIImage(imageLiteralResourceName: name), radius: 50_000, view: self.view)
        planet.addToScene(scene: self.scene)
    }
    public func createShip(scnView: SCNView) {
        self.ship.shipNode = self.ship.createShip(scale: 0.05)
        self.ship.shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.ship.containerNode.position = SCNVector3(0, 5_000, -200_000)
        self.ship.shipNode.simdOrientation = self.currentRotation
        self.scene.rootNode.addChildNode(self.ship.containerNode)
    }
    public func createEcosystem(offset: CGFloat = 0) {
        Ecosystem(spacegroundViewModel: self, offset: offset)
    }
    func createSkybox(scnView: SCNView) {
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.pointOfView?.light = SCNLight()
        scnView.backgroundColor = UIColor.black
        scnView.scene?.background.contents = [
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky")
        ]
        scnView.scene?.background.intensity = 0.98
    }

    // PILOT NAV
    @Published var dampingFactor: Float = 0.666
    func applyRotation() {
        if self.isRotationActive {
            DispatchQueue.main.async {
                // Apply damping to the rotation velocity
                if !self.isDragging { self.averageRotationVelocity *= self.dampingFactor }
                let adjustedDeltaX = self.averageRotationVelocity.x
                let rotationY = simd_quatf(angle: adjustedDeltaX, axis: self.cameraNode.simdWorldUp)
                let cameraRight = self.cameraNode.simdWorldRight
                let rotationX = simd_quatf(angle: self.averageRotationVelocity.y, axis: cameraRight)

                let totalRotation = simd_mul(rotationY, rotationX)
                self.currentRotation = simd_mul(totalRotation, self.currentRotation)
                self.ship.shipNode.simdOrientation = self.currentRotation
                // Stop the rotation when the velocity is below a certain threshold
                if length(self.averageRotationVelocity) < 0.01 {
                    self.isPressed = false
                    self.isRotationActive = false
                    self.averageRotationVelocity = .zero
                }
            }
            
        }
    }
    @MainActor public func updateShipPosition() {
        DispatchQueue.main.async {
            self.applyRotation() // CONTINUE UPDATING ROTATION
            self.ship.shipNode.simdPosition += self.ship.shipNode.simdWorldFront * self.ship.throttle
            let distance: Float = 15 // Define the desired distance between the camera and the spaceship
            let cameraPosition = self.ship.shipNode.simdPosition - (self.ship.shipNode.simdWorldFront * distance)
            self.cameraNode.simdPosition = cameraPosition
            self.cameraNode.simdOrientation = self.ship.shipNode.simdOrientation
            // Update the look-at constraint target
            self.cameraNode.constraints = [self.createLookAtConstraint()]
            // Find the closest black hole and its distance
            self.findClosestHole()
        }
        
    }
    @MainActor func dragChanged(value: DragGesture.Value) {
        let translation = value.translation
        print(translation.width, translation.height)
        let deltaX = Float(translation.width - previousTranslation.width) * 0.005
        let deltaY = Float(translation.height - previousTranslation.height) * 0.005
        // Update the averageRotationVelocity
        self.averageRotationVelocity = SIMD2<Float>(Float(deltaX), Float(deltaY))
        self.previousTranslation = translation
        self.isRotationActive = true
    }
    func dragEnded() {
        self.isDragging = false
        self.previousTranslation = CGSize.zero
    }
    public func updateCameraMissile(node: SCNNode) {
        Task {
            let distance: Float = 100
            let newOrientation = node.simdOrientation
            let cameraPosition = node.presentation.simdPosition - (node.simdWorldFront * distance)
            let mixFactor: Float = 0.1
            let mixedX = simd_mix(self.cameraNode.simdPosition.x, cameraPosition.x, mixFactor)
            let mixedY = simd_mix(self.cameraNode.simdPosition.y, cameraPosition.y, mixFactor)
            let mixedZ = simd_mix(self.cameraNode.simdPosition.z, cameraPosition.z, mixFactor)
            DispatchQueue.main.async {
                self.cameraNode.simdPosition = SIMD3<Float>(mixedX, mixedY, mixedZ)
                self.cameraNode.simdOrientation = newOrientation
                // Update the look-at constraint target
                self.cameraNode.constraints = [self.createLookAtConstraintForNode(node: node)]
            }
        }
    }
    public func findClosestHole() {
        Task {
            var closestDistance: Float = .greatestFiniteMagnitude
            var closestContainerDistance: Float = .greatestFiniteMagnitude
            self.closestBlackHole = nil
            for blackHole in self.blackHoles {
                let distance = simd_distance(blackHole.blackHoleNode.simdWorldPosition, self.ship.shipNode.simdWorldPosition)
                let containerDistance = simd_distance(blackHole.blackHoleNode.simdWorldPosition, self.ship.containerNode.simdWorldPosition)
                if distance < closestDistance {
                    self.closestBlackHole = blackHole
                    closestDistance = distance
                    closestContainerDistance = containerDistance
                }
            }
            let minFov: Float = 120 // minimum field of view
            let maxFov: Float = 150 // maximum field of view
            let maxDistance: Float = 15_000 // maximum distance at which the field of view starts to increase

            if closestDistance < maxDistance {
                let ratio = (maxDistance - closestDistance) / maxDistance
                self.cameraNode.camera!.fieldOfView = CGFloat(minFov + (maxFov - minFov) * ratio)
            } else {
                self.cameraNode.camera!.fieldOfView = CGFloat(minFov)
            }
            // Check if the ship is in contact with the closest black hole (use a threshold value)
            let contactThreshold: Float = self.closestBlackHole == nil ? 0 : Float(self.closestBlackHole!.radius * 1.25 + 5)
            if closestDistance < contactThreshold || closestContainerDistance < contactThreshold {
                self.playSound(name: "snap")
                self.incrementScore(killsOrBlackHoles: 1)
                // Remove black hole from scene and view model
                self.closestBlackHole?.blackHoleNode.removeFromParentNode()
                if let index = self.blackHoles.firstIndex(where: { $0 === self.closestBlackHole }) {
                    self.blackHoles.remove(at: index)
                }
                print("Contact with a black hole at \(self.ship.throttle * 10.0) km/s! Points: +\(self.points)")
                if self.blackHoles.isEmpty {
                    self.endGame()
                }
            }
        }
    }
    public func throttle(value: Float) {
        self.ship.throttle = value
        print(ship.throttle)
    }
    
    // WEAPONS MECHANICS
    @MainActor func fireMissile(target: SCNNode? = nil) {
        self.hitTest()
        let missile = Missile(target: target, particleSystemColor: .red, viewModel: self)
        // Convert shipNode's local position to world position
        let worldPosition = self.ship.shipNode.convertPosition(SCNVector3(0, -50, 33), to: self.ship.containerNode.parent)
        
        missile.missileNode.position = worldPosition
        missile.missileNode.orientation = self.ship.shipNode.presentation.orientation
        missile.missileNode.eulerAngles.x += Float.pi / 2
        let direction = self.ship.shipNode.presentation.worldFront
        let missileMass = missile.missileNode.physicsBody?.mass ?? 1
        let missileForce = CGFloat(abs(self.ship.throttle) + 1) * 5 * missileMass
        missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        self.view.prepare([missile.missileNode]) { success in
            self.scene.rootNode.addChildNode(missile.missileNode)
            self.missiles.append(missile)
            //self.cameraMissile = missile
            //self.inMissileView = true
        }
        self.closestEnemy = nil
    }
    public func hitTest() {
        let centerPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

        // Perform a hit test at the center of the view
        let hitResults = self.view.hitTest(centerPoint, options: nil)

        // Find the first hit node that is a ship
        let closestNode = hitResults.first
        if let closestNode = closestNode {
            // closestNode is the SCNNode closest to the center of the screen
            self.closestEnemy = closestNode.node
        }
    }
    
    // CAMERA RELATED
    func createLookAtConstraint() -> SCNLookAtConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: ship.shipNode)
        lookAtConstraint.influenceFactor = 1
        return lookAtConstraint
    }
    func createLookAtConstraintForNode(node: SCNNode) -> SCNLookAtConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: node)
        return lookAtConstraint
    }
    func setupCamera() {
        // Create a camera
        let camera = SCNCamera()
        camera.zFar = 2_000_000
        camera.zNear = 1
        // Create a camera node and attach the camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        
        // Position the camera node relative to the spacecraft
        self.cameraNode.position = SCNVector3(x: 0, y: 5, z: 25)
        self.cameraNode.camera?.fieldOfView = 120

        // Add a look-at constraint to the camera node
        cameraNode.constraints = [createLookAtConstraint()]
    }
    
    // QUAT MATRIX ROTATION HELPERS
    func worldQuaternionToEulerAngles(_ node: SCNNode) -> SCNVector3 {
        let worldOrientation = node.presentation.simdWorldOrientation
        let matrix = simd_float3x3(worldOrientation)
        
        let sy = sqrt(matrix[0][0] * matrix[0][0] + matrix[1][0] * matrix[1][0])
        let singular = sy < 1e-6
        
        var x, y, z: Float
        if !singular {
            x = atan2(matrix[2][1], matrix[2][2])
            y = atan2(-matrix[2][0], sy)
            z = atan2(matrix[1][0], matrix[0][0])
        } else {
            x = atan2(-matrix[1][2], matrix[1][1])
            y = atan2(-matrix[2][0], sy)
            z = 0
        }
        return SCNVector3(x, y, z)
    }
    func quaternionToEulerAngles(_ quaternion: SCNQuaternion) -> SCNVector3 {
        let q = simd_quatf(ix: quaternion.x, iy: quaternion.y, iz: quaternion.z, r: quaternion.w)
        let matrix = simd_float3x3(q)
        
        let sy = sqrt(matrix[0][0] * matrix[0][0] + matrix[1][0] * matrix[1][0])
        let singular = sy < 1e-6
        
        var x, y, z: Float
        if !singular {
            x = atan2(matrix[2][1], matrix[2][2])
            y = atan2(-matrix[2][0], sy)
            z = atan2(matrix[1][0], matrix[0][0])
        } else {
            x = atan2(-matrix[1][2], matrix[1][1])
            y = atan2(-matrix[2][0], sy)
            z = 0
        }
        return SCNVector3(x, y, z)
    }
    
    // GAME METRICS AND WORLD STATE
    func endGame() {
        self.gameOver = true
    }
    func incrementScore(killsOrBlackHoles: Int) {
        DispatchQueue.main.async {
            switch killsOrBlackHoles {
            case 1:
                self.points += 100 * Int(self.ship.throttle) * 60
                self.showScoreIncrement = true
            case 2:
                self.points += 10000
                self.showKillIncrement = true
            default:
                self.points += 0
            }
        }
    }
    
    // AUDIO AND MUSIC
    @MainActor func playSound(name: String) {
        DispatchQueue.main.async {
            let url = Bundle.main.url(forResource: name, withExtension: "wav")
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url!)
                if !self.audioPlayer.isPlaying {
                    self.audioPlayer.play()
                }
            } catch {
                print("Error playing sound")
            }
        }
    }
    public func playMusic() {
        DispatchQueue.main.async {
            let url = Bundle.main.url(forResource: "HVNDarkseid", withExtension: "mp3")
            do {
                self.musicPlayer = try AVAudioPlayer(contentsOf: url!)
                if !self.musicPlayer.isPlaying {
                    self.musicPlayer.play()
                }
            } catch {
                print("Error playing sound")
            }
        }
    }
    
    // CONTACT HANDLING
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if let contactBodyA = contact.nodeA.physicsBody, let contactBodyB = contact.nodeB.physicsBody {
            let contactMask = contactBodyA.categoryBitMask | contactBodyB.categoryBitMask
            switch contactMask {
            case CollisionCategory.laser | CollisionCategory.enemyShip:
                self.handleLaserEnemyCollision(contact: contact)
            case CollisionCategory.missile | CollisionCategory.enemyShip:
                self.handleMissileEnemyCollision(contact: contact)
            default:
                return
            }
        }
    }
    func death(node: SCNNode, enemyNode: SCNNode) {
        DispatchQueue.main.async {
            self.createExplosion(at: enemyNode.position)
            node.removeFromParentNode()
            enemyNode.removeFromParentNode()
            self.ghosts = self.ghosts.filter { $0.shipNode != enemyNode }
        }
    }
    func handleLaserEnemyCollision(contact: SCNPhysicsContact) {
        Task {
            if let contactBody = contact.nodeA.physicsBody {
                let laserNode = contactBody.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
                let enemyNode = contactBody.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
                DispatchQueue.main.async {
                    if self.loadingSceneView {
                       self.loadingSceneView = false
                       self.ship.containerNode.position = SCNVector3(0, 6_000, -14000)
                   }
                }
                let node = self.ghosts.first(where: { $0.shipNode == enemyNode })
                if let color = laserNode.childNodes.first?.particleSystems?.first?.particleColor, let node = node {
                    switch node.faction {
                    case .Wraith:
                        if color == .green || color == .cyan  {
                            if Float.random(in: 0...1) > 0.9 {
                                print("wraith death")
                                self.death(node: laserNode, enemyNode: enemyNode)
                            }
                            else {
                                //node.isEvading = true
                            }
                        }
                    case .Phantom:
                        if color == .red || color == .systemPink {
                            if Float.random(in: 0...1) > 0.9 {
                                self.death(node: laserNode, enemyNode: enemyNode)
                            }
                            else {
                                //node.isEvading = true
                            }
                        }
                    }
                }
            }
        }
    }
    func handleMissileEnemyCollision(contact: SCNPhysicsContact) {
        Task {
            // Determine which node is the missile and which is the enemy ship
            let missileNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.missile ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            
            // Find the corresponding missile object and call the handleCollision function
            if let missile = self.missiles.first(where: { $0.getMissileNode() == missileNode }) {
                print(missile.particleSystem.particleColor)
                if missile.particleSystem.particleColor != .cyan {
                    return
                }
                self.playSound(name: "snatchHiss")
                missile.detonate()
            }
            // Remove the missile and enemy ship from the scene
            DispatchQueue.main.async {
                self.createExplosion(at: enemyNode.position)
                enemyNode.removeFromParentNode()
                self.cameraMissile = nil
                self.inMissileView = false
                // Add logic for updating the score or other game state variables
                // For example, you could call a function in the SpacegroundViewModel to increase the score:
                self.incrementScore(killsOrBlackHoles: 2)
                self.ghosts = self.ghosts.filter { $0.shipNode != enemyNode }
                self.closestEnemy = nil
            }
        }
    }
    func createExplosion(at position: SCNVector3) {
        Task {
            let explosionNode = SCNNode()
            explosionNode.position = position
            explosionNode.addParticleSystem(ParticleManager.explosionParticleSystem)
            
            let implodeAction = SCNAction.scale(to: 5, duration: 0.40)
            let implodeActionStep = SCNAction.scale(to: 2.5, duration: 1)
            let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
            let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
            
            DispatchQueue.main.async {
                self.view.prepare([explosionNode]) { success in
                    self.scene.rootNode.addChildNode(explosionNode)
                    explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        explosionNode.removeFromParentNode()
                    }
                }
            }
        }
    }

    func setupPhysics() {
        self.scene.physicsWorld.contactDelegate = self
    }
}
