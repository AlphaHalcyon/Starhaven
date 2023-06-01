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

@MainActor class SpacegroundViewModel: NSObject, ObservableObject, SCNSceneRendererDelegate  {
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
    init(view: SCNView, cameraNode: SCNNode) {
        // Initialize all properties
        self.view = view
        self.cameraNode = cameraNode
        self.ship = Ship(view: view, cameraNode: cameraNode)
        rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 5)
        rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 5)

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
    nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
       DispatchQueue.main.async {
           if !self.inMissileView {
               DispatchQueue.main.async {
                   self.updateShipPosition()
               }
           } else {
               if let missile = self.cameraMissile {
                   DispatchQueue.main.async {
                       self.updateCameraMissile(node: missile.missileNode)
                   }
               }
           }
           //self.boundingBoxUpdate()
           for ghost in self.ghosts {
               DispatchQueue.main.async {
                   ghost.updateAI()
               }
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
            self.ship.containerNode.position = SCNVector3(-5000, 8000, -80_000)
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
        scnView.scene?.background.intensity = 0.25
    }

    // PILOT NAV
    public func boundingBoxUpdate() {
        if self.fireCooldown {
            if let boundingBoxNode = self.boundingBoxNode {
                boundingBoxNode.removeFromParentNode()
                self.boundingBoxNode = nil
            }
        }
        else {
            self.updateMissileLockBoundingBox()
        }
    }
    public func updateMissileLockBoundingBox() {
        // Find the enemy ship that is closest to the player's ship
        let centerPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)

        var closestNode: SCNNode?
        var minDistance = CGFloat.greatestFiniteMagnitude

        for node in self.ghosts {
            if !self.loadingSceneView && self.currentRotation != simd_quatf(angle: .pi, axis: simd_float3(x: 0, y: 1, z: 0)) {
                let projectedPoint = self.view.projectPoint(node.shipNode.position)
                let projectedCGPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
                let distance = hypot(projectedCGPoint.x - centerPoint.x, projectedCGPoint.y - centerPoint.y)

                if distance < minDistance {
                    minDistance = distance
                    closestNode = node.shipNode
                }
            }
        }

        if let closestNode = closestNode {
            // closestNode is the SCNNode closest to the center of the screen
            self.closestEnemy = closestNode
        }

        // Remove the existing bounding box if it's attached to a different enemy
        if let existingBoundingBox = boundingBoxNode, let parentNode = existingBoundingBox.parent, parentNode != self.closestEnemy {
            DispatchQueue.main.async {
                existingBoundingBox.removeFromParentNode()
                self.boundingBoxNode = nil
            }
        }

        // Check if there is a closest enemy within a certain distance
        if let closestEnemy = closestNode {
            // If a bounding box node does not exist, create it and add it as a child node to the closest enemy
            if boundingBoxNode == nil {
                let boundingBox = closestEnemy.boundingBox
                let width = CGFloat(boundingBox.max.x - boundingBox.min.x)
                let height = CGFloat(boundingBox.max.x - boundingBox.min.x)
                let box = SCNBox(width: width * 1, height: height * 1, length: height * 2, chamferRadius: 1)
                box.firstMaterial?.diffuse.contents = UIColor.red
                let planeNode = SCNNode(geometry: box)
                planeNode.opacity = 0.5
                planeNode.position = SCNVector3((boundingBox.min.x + boundingBox.max.x) / 2, (boundingBox.min.y + boundingBox.max.y) / 2, 0)
                boundingBoxNode = planeNode
                self.view.prepare([planeNode]) { success in
                    closestEnemy.addChildNode(planeNode)
                }
            }
        } else {
            DispatchQueue.main.async {
                // If there is no closest enemy or it's out of range, remove the bounding box
                if let box = self.boundingBoxNode {
                    box.removeFromParentNode()
                    self.boundingBoxNode = nil
                }
            }
        }
    }
    func toggleWeapon() {
        if weaponType == "Missile" {
            weaponType = "Laser"
        } else {
            weaponType = "Missile"
        }
    }
    /// FLIGHT
    let dampingFactor: Float = 0.70
    @MainActor func applyRotation() {
        if isRotationActive {
            // Apply damping to the rotation velocity
            averageRotationVelocity *= dampingFactor
            let adjustedDeltaX = averageRotationVelocity.x
            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: cameraNode.simdWorldUp)
            let cameraRight = cameraNode.simdWorldRight
            let rotationX = simd_quatf(angle: averageRotationVelocity.y, axis: cameraRight)

            let totalRotation = simd_mul(rotationY, rotationX)
            currentRotation = simd_mul(totalRotation, currentRotation)
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
    @MainActor public func playMusic() {
        DispatchQueue.main.async {
            let url = Bundle.main.url(forResource: "HVN", withExtension: "mp3")
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
}
