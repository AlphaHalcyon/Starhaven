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

@MainActor class SpacecraftViewModel: ObservableObject {
    @Published var previousTranslation: CGSize = CGSize.zero
    @Published var currentRotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    @Published var view: SCNView = SCNView()
    @Published var scene: SCNScene = SCNScene()
    @Published var ship = Ship()
    @Published var cameraNode: SCNNode!
    @Published var blackHoles: [BlackHole] = []
    @Published var isInverted: Bool = false
    @Published var rotationDeltaX: Float = 0
    @Published var rotationDeltaY: Float = 0
    @Published var isDragging: Bool = false
    @Published var rotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var isRotationActive: Bool = false
    @Published var isPressed: Bool = false
    @Published var longPressTimer: Timer = Timer()
    @Published var averageRotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var rotationVelocityBufferX: VelocityBuffer
    @Published var rotationVelocityBufferY: VelocityBuffer
    @Published var closestBlackHole: BlackHole?
    @Published var distanceToBlackHole: CGFloat = .greatestFiniteMagnitude
    @Published var points: Int = 0
    @Published var showScoreIncrement: Bool = false
    @Published var weaponType: String = "Missile"
    @Published var enemyControlTimer: Timer? = nil
    @Published var belligerents: [SCNNode] = []
    @Published var missiles: [Missile] = []
    init() {
        rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 2)
        rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 2)
        self.setupCamera()
        // Create a timer to update the ship's position
        Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateShipPosition()
                
            }
        }
    }
    @MainActor public func makeSpaceView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = self.scene
        self.ship.shipNode = self.ship.createShip()
        scnView.scene?.rootNode.addChildNode(self.cameraNode)
        self.ship.containerNode.position = SCNVector3(0, 1_000, -5_010)

        // GHOST SHIP CREATION
        let enemyShip = EnemyShip(spacegroundViewModel: self)
        let enemyShip2 = EnemyShip(spacegroundViewModel: self)
        let enemyShipNode = enemyShip.createShip(scale: 20.0)
        let enemyShip2Node = enemyShip2.createShip(scale: 10.0)
        enemyShipNode.position = SCNVector3(0, 1_000, -4_950)
        enemyShip2Node.position = SCNVector3(20, 1_000, -4_450)
        scnView.scene?.rootNode.addChildNode(enemyShip.containerNode)
        scnView.scene?.rootNode.addChildNode(enemyShip2.containerNode)
        // GHOST MOVEMENT SCHEDULE
        DispatchQueue.main.async {
            self.belligerents = [self.ship.shipNode, enemyShipNode, enemyShip2Node]
            self.enemyControlTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    enemyShip.updateAI()
                    enemyShip2.updateAI()
                }
            }
        }
        scnView.scene?.rootNode.addChildNode(self.ship.containerNode)
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
        // Create scattered black holes
        for _ in 1...10 {
            let radius = CGFloat.random(in: 30...150)
            let ringCount = Int.random(in: 10...20)
            let blackHole = self.addBlackHole(radius: radius, ringCount: ringCount, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh, period: 8)
            DispatchQueue.main.async {
                self.blackHoles.append(blackHole)
            }
        }
        // Create center black hole
        let centerBlackHoleRadius = CGFloat(1000)
        let centerBlackHole = self.addBlackHole(radius: centerBlackHoleRadius, ringCount: 25, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh, period: 8)
        DispatchQueue.main.async {
            self.blackHoles.append(centerBlackHole)
        }
        
        scnView.prepare(self.scene)
        return scnView
    }
    // GHOST WEAPONS
    func createMissile(target: SCNNode? = nil) {
        let missile = Missile(target: target)
        self.missiles.append(missile)
    }
    // WEAPONS DYANMICS
    func toggleWeapon() {
        if weaponType == "Missile" {
            weaponType = "Laser"
        } else {
            weaponType = "Missile"
        }
    }
    // WORLD DYNAMICS
    
    // WORLD SCALE
    func applyAffineTransform(vector: SCNVector3, transform: SCNMatrix4) -> SCNVector3 {
        let x = transform.m11 * vector.x + transform.m21 * vector.y + transform.m31 * vector.z + transform.m41
        let y = transform.m12 * vector.x + transform.m22 * vector.y + transform.m32 * vector.z + transform.m42
        let z = transform.m13 * vector.x + transform.m23 * vector.y + transform.m33 * vector.z + transform.m43
        return SCNVector3(x: x, y: y, z: z)
    }
    // WORLD SET-UP
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String, period: Float) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, view: self.view, radius: radius, camera: self.cameraNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe, period: period, shipNode: self.ship.shipNode)
        blackHole.blackHoleNode.position = SCNVector3(CGFloat.random(in: -100000...100000), CGFloat.random(in: -10000...10000), CGFloat.random(in: -10000...100000))
        self.view.prepare(blackHole.blackHoleNode)
        self.scene.rootNode.addChildNode(blackHole.containerNode)
        return blackHole
    }

    // PILOT NAV
    let dampingFactor: Float = 0.70

    func applyRotation() {
        if isRotationActive {
            // Apply damping to the rotation velocity
            averageRotationVelocity *= dampingFactor
            let adjustedDeltaX = averageRotationVelocity.x
            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: cameraNode.simdWorldUp)
            let cameraRight = cameraNode.simdWorldRight
            let rotationX = simd_quatf(angle: averageRotationVelocity.y, axis: cameraNode.simdWorldRight)

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
            self.applyRotation()
        }
    }
    func stopContinuousRotation() {
        
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
        applyRotation() // Add this line

        ship.shipNode.simdPosition += ship.shipNode.simdWorldFront * ship.throttle
        // Find the closest black hole and its distance
        var closestDistance: Float = .greatestFiniteMagnitude
        var closestContainerDistance: Float = .greatestFiniteMagnitude
        closestBlackHole = nil
        for blackHole in self.blackHoles {
            let distance = simd_distance(blackHole.blackHoleNode.simdWorldPosition, ship.shipNode.simdWorldPosition)
            let containerDistance = simd_distance(blackHole.blackHoleNode.simdWorldPosition, ship.containerNode.simdWorldPosition)
            if distance < closestDistance {
                self.closestBlackHole = blackHole
                closestDistance = distance
                closestContainerDistance = containerDistance
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
        let contactThreshold: Float = self.closestBlackHole == nil ? 0 : Float(self.closestBlackHole!.radius + 5)
        if closestDistance < contactThreshold || closestContainerDistance < contactThreshold {
            points += 100 * Int(self.ship.throttle)
            self.showScoreIncrement = true
            // Remove black hole from scene and view model
            closestBlackHole?.blackHoleNode.removeFromParentNode()
            if let index = blackHoles.firstIndex(where: { $0 === closestBlackHole }) {
                blackHoles.remove(at: index)
            }
            print("Contact with a black hole! Points: \(points)")
        }
        let distance: Float = 15.0 // Define the desired distance between the camera and the spaceship
        let cameraPosition = ship.shipNode.simdPosition - (ship.shipNode.simdWorldFront * distance)
        cameraNode.simdPosition = cameraPosition
        cameraNode.simdOrientation = ship.shipNode.simdOrientation
        // Update the look-at constraint target
        cameraNode.constraints = [createLookAtConstraint()]
        self.updateShipOrientation()
        
    }
    func throttle(value: Float) {
        ship.throttle = value
        print(ship.throttle)
    }

    func dragChanged(value: DragGesture.Value) {
        let translation = value.translation
        let deltaX = Float(translation.width - previousTranslation.width) * 0.0075
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
        stopContinuousRotation()
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
}
