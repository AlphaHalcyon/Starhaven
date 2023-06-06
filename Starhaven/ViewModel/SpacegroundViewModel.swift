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
    @Published var rotationVelocityBufferX: VelocityBuffer = VelocityBuffer(bufferCapacity: 2)
    @Published var rotationVelocityBufferY: VelocityBuffer = VelocityBuffer(bufferCapacity: 2)
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
    @Published var enemyControlTimer: Timer? = nil

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
        rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 1)
        rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 1)

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

    // This method will be called once per frame
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !self.inMissileView {
            self.updateShipPosition()
                //self.hitTest()
        } else {
            if let missile = self.cameraMissile {
                self.updateCameraMissile(node: missile.missileNode)
            }
        }
        //self.boundingBoxUpdate()
        for ghost in self.ghosts {
            Task {
                ghost.updateAI()
            }
        }
   }
    @MainActor public func makeSpaceView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = self.scene
        scnView.rendersContinuously = true
        self.createShip(scnView: scnView)
        self.updateShipPosition()
        self.createEcosystem()
        self.createSkybox(scnView: scnView)
        scnView.delegate = self
        scnView.prepare(self.scene)
        DispatchQueue.main.async {
            self.view = scnView
        }
        return scnView
    }
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
        DispatchQueue.main.async {
            self.ship.shipNode = self.ship.createShip(scale: 0.04)
            self.ship.shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            self.ship.shipNode.simdOrientation = self.currentRotation
            self.ship.containerNode.position = SCNVector3(0, 0, -200_000)
            self.scene.rootNode.addChildNode(self.ship.containerNode)
        }
    }
    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil) {
        DispatchQueue.main.async {
            print("fire!")
            let missile = Missile(target: target, particleSystemColor: .red, viewModel: self)
            // Convert shipNode's local position to world position
            let worldPosition = self.ship.shipNode.convertPosition(SCNVector3(0, -20, 15), to: self.ship.containerNode.parent)
            
            missile.missileNode.position = worldPosition
            missile.missileNode.orientation = self.ship.shipNode.presentation.orientation
            missile.missileNode.eulerAngles.x += Float.pi / 2
            let direction = self.ship.shipNode.presentation.worldFront
            let missileMass = missile.missileNode.physicsBody?.mass ?? 1
            let missileForce = CGFloat(abs(self.ship.throttle) + 1) * 2 * missileMass
            missile.missileNode.physicsBody?.velocity = self.ship.shipNode.physicsBody!.velocity
            missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
            self.view.prepare([missile.missileNode]) { success in
                self.scene.rootNode.addChildNode(missile.missileNode)
                if Bool.random() {
                    if self.cameraMissile == nil && self.missiles.isEmpty {
                        self.cameraMissile = missile
                        self.inMissileView = true
                    }
                }
            }
            self.missiles.append(missile)
        }
    }
    public func createEcosystem(offset: CGFloat = 0) {
        DispatchQueue.main.async {
            let system: Ecosystem = Ecosystem(spacegroundViewModel: self, offset: offset)
            self.scene.rootNode.addChildNode(system.centralNode)
            self.ecosystems.append(system)
        }
    }
    public func removeEcosystem(system: Ecosystem) {
        self.ecosystems = self.ecosystems.filter { $0.id != system.id }
    }
    public func checkWinCondition() -> Bool {
        return ecosystems.isEmpty
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
        scnView.scene?.background.intensity = 1
    }

    // PILOT NAV
    public func hitTest() {
        let centerPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

        // Perform a hit test at the center of the view
        let hitResults = self.view.hitTest(centerPoint, options: nil)

        // Find the first hit node that is a ship
        let closestNode = hitResults.first(where: { $0.node.physicsBody?.contactTestBitMask == CollisionCategory.enemyShip })

        if let closestNode = closestNode {
            // closestNode is the SCNNode closest to the center of the screen
            self.closestEnemy = closestNode.node
        }
    }
    /// FLIGHT
    @Published var dampingFactor: Float = 0.70
    @MainActor func applyRotation() {
        if self.isRotationActive {
            // Apply damping to the rotation velocity
            self.averageRotationVelocity *= self.dampingFactor
            let adjustedDeltaX = self.averageRotationVelocity.x
            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: cameraNode.simdWorldUp)
            let cameraRight = cameraNode.simdWorldRight
            let rotationX = simd_quatf(angle: self.averageRotationVelocity.y, axis: cameraRight)

            let totalRotation = simd_mul(rotationY, rotationX)
            self.currentRotation = simd_mul(totalRotation, self.currentRotation)
            self.ship.shipNode.simdOrientation = self.currentRotation
            DispatchQueue.main.async {
                // Stop the rotation when the velocity is below a certain threshold
                if length(self.averageRotationVelocity) < 0.01 {
                    self.longPressTimer = false
                    self.isRotationActive = false
                    self.averageRotationVelocity = .zero
                }
            }
        }
    }
    public func startContinuousRotation() {
        DispatchQueue.main.async {
            // Invalidate any existing timer
            self.longPressTimer = true
        }
    }
    public func updateCameraMissile(node: SCNNode) {
        DispatchQueue.main.async {
            let distance: Float = 25.0
            let newOrientation = node.simdOrientation
            self.cameraNode.simdOrientation = newOrientation
            let cameraPosition = node.presentation.simdPosition - (node.simdWorldFront * distance)
            let mixFactor: Float = 0.1
            let mixedX = simd_mix(self.cameraNode.simdPosition.x, cameraPosition.x, mixFactor)
            let mixedY = simd_mix(self.cameraNode.simdPosition.y, cameraPosition.y, mixFactor)
            let mixedZ = simd_mix(self.cameraNode.simdPosition.z, cameraPosition.z, mixFactor)
            self.cameraNode.simdPosition = SIMD3<Float>(mixedX, mixedY, mixedZ)

            // Update the look-at constraint target
            self.cameraNode.constraints = [self.createLookAtConstraintForNode(node: node)]
        }
    }

    @MainActor public func updateShipPosition() {
        DispatchQueue.main.async {
            self.applyRotation() // CONTINUE UPDATING ROTATION
            self.ship.shipNode.simdPosition += self.ship.shipNode.simdWorldFront * self.ship.throttle
            let distance: Float = 30.0 // Define the desired distance between the camera and the spaceship
            let cameraPosition = self.ship.shipNode.simdPosition - (self.ship.shipNode.simdWorldFront * distance)
            self.cameraNode.simdPosition = cameraPosition
            self.cameraNode.simdOrientation = self.ship.shipNode.simdOrientation
            // Update the look-at constraint target
            self.cameraNode.constraints = [self.createLookAtConstraint()]
            // Find the closest black hole and its distance
            self.findClosestHole()
        }
        
    }
    public func findClosestHole() {
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
                self.blackHoles.forEach { hole in
                    DispatchQueue.main.async { hole.updateSpinningState() }
                }
            }
        }
        let minFov: Float = 120 // minimum field of view
        let maxFov: Float = 140 // maximum field of view
        let maxDistance: Float = 10_000 // maximum distance at which the field of view starts to increase

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
    @MainActor public func throttle(value: Float) {
        self.ship.throttle = value
        print(ship.throttle)
    }
    @MainActor func dragChanged(value: DragGesture.Value) {
        let translation = value.translation
        let deltaX = Float(translation.width - previousTranslation.width) * 0.007
        let deltaY = Float(translation.height - previousTranslation.height) * 0.007

        // Add the deltaX and deltaY to their respective buffers
        rotationVelocityBufferX.addVelocity(CGFloat(deltaX))
        rotationVelocityBufferY.addVelocity(CGFloat(deltaY))

        // Compute the weighted average velocities
        let weightedAverageVelocityX = rotationVelocityBufferX.weightedAverageVelocity()
        let weightedAverageVelocityY = rotationVelocityBufferY.weightedAverageVelocity()

        // Update the averageRotationVelocity
        averageRotationVelocity = SIMD2<Float>(Float(weightedAverageVelocityX), Float(weightedAverageVelocityY))

        previousTranslation = translation
        isRotationActive = true
    }
    func dragEnded() {
        previousTranslation = CGSize.zero
        self.rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 4)
        self.rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 4)
        startContinuousRotation()
    }
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
        switch killsOrBlackHoles {
        case 1:
            points += 100 * Int(self.ship.throttle) * 60
            self.showScoreIncrement = true
        case 2:
            points += 10000
            self.showKillIncrement = true
        default:
            self.points += 0
        }
    }
    
    // AUDIO AND MUSIC
    func playSound(name: String) {
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
        DispatchQueue.main.async {
            let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
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
        DispatchQueue.main.async {
            if self.loadingSceneView {
                self.ship.containerNode.position = SCNVector3(0, 8_000, -20_000)
                self.loadingSceneView = false
                DispatchQueue.main.async {
                    self.playMusic()
                }
            }
            let laserNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            let node = self.ghosts.first(where: { $0.shipNode == enemyNode })
            if let color = laserNode.childNodes.first?.particleSystems?.first?.particleColor {
                switch node?.faction {
                case .Wraith:
                    if color == .green || color == .cyan  {
                        if Float.random(in: 0...1) > 0.75 {
                            print("wraith death")
                            self.death(node: laserNode, enemyNode: enemyNode)
                        }
                    }
                case .Phantom:
                    if color == .red || color == .systemPink {
                        if Float.random(in: 0...1) > 0.75 {
                            self.death(node: laserNode, enemyNode: enemyNode)
                        }
                    }
                default:
                    return
                }
            }
        }
    }
    func handleMissileEnemyCollision(contact: SCNPhysicsContact) {
        DispatchQueue.main.async {
            // Determine which node is the missile and which is the enemy ship
            let missileNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.missile ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            
            // Find the corresponding missile object and call the handleCollision function
            if let missile = self.missiles.first(where: { $0.getMissileNode() == missileNode }) {
                print(missile.particleSystem.particleColor)
                if missile.particleSystem.particleColor != .red {
                    return
                }
                print("nice!")
                self.playSound(name: "snatchHiss")
                missile.detonate()
            }
            self.createExplosion(at: enemyNode.position)
            enemyNode.removeFromParentNode()
            self.cameraMissile = nil
            self.inMissileView = false
            // Add logic for updating the score or other game state variables
            // For example, you could call a function in the SpacegroundViewModel to increase the score:
            self.incrementScore(killsOrBlackHoles: 2)
        
            // Remove the missile and enemy ship from the scene
            let node = self.ghosts.first(where: { $0.shipNode == enemyNode })
            self.ghosts = self.ghosts.filter { $0.shipNode != enemyNode }
        }
    }
    func createExplosion(at position: SCNVector3) {
        let coronaGeo = SCNSphere(radius: 100)
        
        // Create the particle system programmatically
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 1000000
        fireParticleSystem.particleSize = 0.5
        fireParticleSystem.particleIntensity = 0.90
        fireParticleSystem.particleLifeSpan = 0.30
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 90
        fireParticleSystem.emitterShape = coronaGeo
        // Make the particle system surface-based
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        
        // Create an SCNNode to hold the particle system
        let explosionNode = SCNNode()
        
        // Set the position of the explosion
        explosionNode.position = position
        
        // Add the explosion particle system to the node
        explosionNode.addParticleSystem(fireParticleSystem)
        DispatchQueue.main.async {
            // Add the explosion node to the scene
            self.scene.rootNode.addChildNode(explosionNode)
            
            // Configure and run the scale actions
            let implodeAction = SCNAction.scale(to: 5, duration: 0.20)
            let implodeActionStep = SCNAction.scale(to: 2.5, duration: 1)
            let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
            let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
            explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))

            // Remove the explosion node after some time (e.g., 2 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                explosionNode.removeFromParentNode()
            }
        }
    }
    func setupPhysics() {
        self.scene.physicsWorld.contactDelegate = self
    }
}
