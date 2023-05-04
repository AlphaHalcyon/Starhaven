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

@MainActor class SpacegroundViewModel: ObservableObject {
    // View and Scene
    @Published var view: SCNView = SCNView()
    @Published var scene: SCNScene = SCNScene()
    @Published var cameraNode: SCNNode!

    // Player Ship and Navigation
    @Published var ship = Ship()
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
    @Published var longPressTimer: Timer = Timer()
    @Published var averageRotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var rotationVelocityBufferX: VelocityBuffer
    @Published var rotationVelocityBufferY: VelocityBuffer
    // Weapon systems
    @Published var missiles: [Missile] = []
    @Published var weaponType: String = "Missile"
    
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
    init() {
        rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 2)
        rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 2)
        self.setupCamera()
    }
    @MainActor public func makeSpaceView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = self.scene
        self.createShip(scnView: scnView)
        self.updateShipPosition()
        self.createEcosystem()
        self.createSkybox(scnView: scnView)
        scnView.prepare([self.scene]) { success in
            DispatchQueue.main.async {
                self.ship.containerNode.position = SCNVector3(0, 3000, -8000)
                self.loadingSceneView = false
            }
        }
        return scnView
    }
    @MainActor public func createShip(scnView: SCNView) {
        DispatchQueue.main.async {
            self.ship.shipNode = self.ship.createShip()
            self.ship.shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            self.scene.rootNode.addChildNode(self.cameraNode)
            self.ship.containerNode.position = SCNVector3(0, 0, -50_000)
            self.ship.shipNode.simdOrientation = self.currentRotation
            self.scene.rootNode.addChildNode(self.ship.containerNode)
        }
    }
    @MainActor public func startWorldTimer() {
        // WORLD CONTROLLER TIMER <- move things in here
        Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateShipPosition()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.enemyControlTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    for ghost in self.ghosts {
                        ghost.updateAI()
                    }
                }
            }
        }
    }
    @MainActor public func createEcosystem() {
        DispatchQueue.main.async {
            let system: Ecosystem = Ecosystem(spacegroundViewModel: self)
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
    func toggleWeapon() {
        if weaponType == "Missile" {
            weaponType = "Laser"
        } else {
            weaponType = "Missile"
        }
    }
    /// FLIGHT
    let dampingFactor: Float = 0.80
    func applyRotation() {
        if isRotationActive {
            // Apply damping to the rotation velocity
            averageRotationVelocity *= dampingFactor
            let adjustedDeltaX = averageRotationVelocity.x
            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: cameraNode.simdWorldUp)
            let cameraRight = cameraNode.simdWorldRight
            let rotationX = simd_quatf(angle: averageRotationVelocity.y, axis: cameraRight)

            let totalRotation = simd_mul(rotationY, rotationX)
            currentRotation = simd_mul(totalRotation, currentRotation)
            ship.shipNode.simdOrientation = currentRotation

            // Stop the rotation when the velocity is below a certain threshold
            if length(averageRotationVelocity) < 0.00001 {
                isRotationActive = false
                averageRotationVelocity = .zero
            }
        }
    }
    func startContinuousRotation() {
        // Invalidate any existing timer
        longPressTimer.invalidate()

        // Create a new timer that calls applyRotation continuously
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            Task { await self.applyRotation() }
        }
    }
    func updateShipOrientation() {
        let worldUp = SIMD3<Float>(0, 1, 0)
        let shipUp = ship.shipNode.presentation.simdWorldUp

        // Calculate the dot product of the ship's up vector and the world's up vector
        let dotProduct = simd_dot(shipUp, worldUp)

        if dotProduct < 0 {
            DispatchQueue.main.async {
                self.isInverted = true
            }
        } else {
            DispatchQueue.main.async {
                self.isInverted = false
            }
        }
        let shipQuaternion = ship.shipNode.presentation.orientation
        let eulerAngles = quaternionToEulerAngles(shipQuaternion)

        DispatchQueue.main.async {
            self.ship.yaw = CGFloat(eulerAngles.y * 180 / Float.pi)
            self.ship.pitch = CGFloat(eulerAngles.x * 180 / Float.pi)
            self.ship.roll = CGFloat(eulerAngles.z * 180 / Float.pi)
        }
    }
    func updateShipPosition() {
        self.applyRotation() // CONTINUE UPDATING ROTATION

        self.ship.shipNode.simdPosition += self.ship.shipNode.simdWorldFront * self.ship.throttle
        // Find the closest black hole and its distance
        var closestDistance: Float = .greatestFiniteMagnitude
        var closestContainerDistance: Float = .greatestFiniteMagnitude
        DispatchQueue.main.async {
            self.closestBlackHole = nil
        }
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
        let maxFov: Float = 150 // maximum field of view
        let maxDistance: Float = 7500 // maximum distance at which the field of view starts to increase

        if closestDistance < maxDistance {
            let ratio = (maxDistance - closestDistance) / maxDistance
            self.cameraNode.camera!.fieldOfView = CGFloat(minFov + (maxFov - minFov) * ratio)
        } else {
            self.cameraNode.camera!.fieldOfView = CGFloat(minFov)
        }
        // Check if the ship is in contact with the closest black hole (use a threshold value)
        let contactThreshold: Float = self.closestBlackHole == nil ? 0 : Float(self.closestBlackHole!.radius * 1.25 + 5)
        if closestDistance < contactThreshold || closestContainerDistance < contactThreshold {
            self.incrementScore(killsOrBlackHoles: 1)
            // Remove black hole from scene and view model
            self.closestBlackHole?.blackHoleNode.removeFromParentNode()
            if let index = self.blackHoles.firstIndex(where: { $0 === self.closestBlackHole }) {
                self.blackHoles.remove(at: index)
            }
            print("Contact with a black hole at \(self.ship.throttle * 10.0) km/s! Points: +\(self.points)")
        }
        let distance: Float = 15.0 // Define the desired distance between the camera and the spaceship
        let cameraPosition = self.ship.shipNode.simdPosition - (self.ship.shipNode.simdWorldFront * distance)
        self.cameraNode.simdPosition = cameraPosition
        self.cameraNode.simdOrientation = self.ship.shipNode.simdOrientation
        // Update the look-at constraint target
        self.cameraNode.constraints = [self.createLookAtConstraint()]
        self.updateShipOrientation()
        
    }
    func throttle(value: Float) {
        self.ship.throttle = value
        print(ship.throttle)
    }
    func dragChanged(value: DragGesture.Value) {
        let translation = value.translation
        let deltaX = Float(translation.width - previousTranslation.width) * 0.006
        let deltaY = Float(translation.height - previousTranslation.height) * 0.0075

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
        self.rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 5)
        self.rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 5)
        startContinuousRotation()
    }
    func createLookAtConstraint() -> SCNLookAtConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: ship.shipNode)
        lookAtConstraint.influenceFactor = 0.5
        return lookAtConstraint
    }
    func setupCamera() {
        // Create a camera
        let camera = SCNCamera()
        camera.zFar = 100000
        camera.zNear = 1
        // Create a camera node and attach the camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        
        // Position the camera node relative to the spacecraft
        self.cameraNode.position = SCNVector3(x: 0, y: 5, z: 15)
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
}
