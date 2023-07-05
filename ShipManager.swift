//
//  PhysicsObject.swift
//  Starhaven
//
//  Created by JxR on 6/15/23.
//

import Foundation
import SceneKit
import SwiftUI
import ARKit

// This refactoring is majorly focused on single-responsibility as a principle, because that was lacking before: we managed nearly all of these components in one view model. \\
// So! We have a PhysicsManager. We have CollisionHandlers. We have Levels. We have a SceneManager. And we have SceneObjects. \\
// We want to introduce a class that can manage our camera. Right now the logic for moving the game camera around is deeply intertwined with the nav logic. \\
// In that vein, we should also have a class for managing the player control of the ship (we want to think about how to generalize this in the future). \\
// So we have a CameraManager, which features the new CameraTrackingState enum which allows us to place the camera with more flexibility. \\
// We also have a ShipManager which handles inputs and controls the ship accordingly: we will break that down into an InputHandler and a more general PlayerObjectManager class. \\
// We've taken advantage of our CameraManager's flexibility to add a mixing factor to its follow behavior, making for smooth interpolated rotations when turning. \\
// We are going to try to rebuild our app from this starting point, keeping inspirations from our previous codebase. \\
// The hope is that we can untangle some things in the process that may improve our rendering experience. \\

class ShipManager {
    // Player controls
    var ship: SCNNode
    var containerNode: SCNNode = SCNNode()
    var throttle: Float = 0
    var closestBlackHole: BlackHole?
    var currentRotation = simd_quatf(angle: .pi, axis: simd_float3(x: 0, y: 1, z: 0))
    var rotationDeltaX: Float = 0
    var rotationDeltaY: Float = 0
    var rotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    var isRotationActive: Bool = false
    var isDragging: Bool = false
    var isPressed: Bool = false
    var isInverted: Bool = false
    var dampingFactor: Float = 0.5
    var previousTranslation: CGSize = CGSize.zero
    var initialTouchPoint: CGPoint = .zero
    var joystickVector: SIMD2<Float> = .zero
    var closestEnemy: SCNNode?
    let arSession: ARSession = ARSession()
    var currentFrame: ARFrame?
    init() {
        self.ship = SCNNode() //ModelManager.createShip()
        self.ship.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: self.ship))
        self.ship.physicsBody?.isAffectedByGravity = false
        self.ship.physicsBody?.categoryBitMask = CollisionCategory.ship
        // Set the category, collision, and contact test bit masks
        self.ship.physicsBody?.collisionBitMask = CollisionCategory.celestial
        self.ship.physicsBody?.contactTestBitMask = CollisionCategory.celestial
        self.startARSession()
    }
    
    //  ROTATION and POSITION HANDLING
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        arSession.run(configuration)
    }
    var currentOrientation: SIMD2<Float> = .zero
    func update(deltaTime: TimeInterval) {
        self.adoptDeviceOrientation()
        self.updateShipPosition(deltaTime: deltaTime)
        //self.updateRotation(deltaTime: deltaTime)
        self.findClosestHole()
    }
    var lastPosition: SIMD3<Float> = .zero
    var lastRotation: simd_quatf = simd_quatf()
    func adoptDeviceOrientation() {
        self.currentFrame = arSession.currentFrame
        if let cameraTransform = currentFrame?.camera.transform {
            // Convert the 4x4 transform matrix to a quaternion
            let quaternion = simd_quaternion(cameraTransform)

            // Use the quaternion to update the ship's orientation
            self.currentRotation = quaternion
            self.ship.simdOrientation = quaternion
        } else {
            //print("failed")
        }
    }
    func updateShipPosition(deltaTime: TimeInterval) {
        // Apply the new position
        let throttleDelta = self.throttle // * Float(deltaTime)
        self.ship.simdPosition += self.ship.simdWorldFront * throttleDelta
    }
    // Add a new function to calculate the distance between two orientation vectors
        func distance(_ a: simd_float3, _ b: simd_float3) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            let dz = a.z - b.z
            return sqrt(dx*dx + dy*dy + dz*dz)
        }
    func updateRotation(deltaTime: TimeInterval) {
        // Update rotationVelocity with deltaTime
        //self.rotationVelocity *= Float(deltaTime)
        if self.rotationVelocity != .zero {
            // Create the rotation quaternions
            let adjustedDeltaX = self.rotationVelocity.x
            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: self.ship.simdWorldUp)
            let cameraRight = self.ship.simdWorldRight
            let rotationX = simd_quatf(angle: self.rotationVelocity.y, axis: cameraRight)
            let totalRotation = simd_mul(rotationX, rotationY)
            let newRotation = simd_mul(totalRotation, self.currentRotation)
            
            // Apply low-pass filter
            let alpha: Float = 1
            let filteredRotation =  simd_normalize(simd_slerp(self.lastRotation, newRotation, alpha))
            // Normalize the quaternion
            self.lastRotation = filteredRotation
            
            // Apply the new rotation
            self.ship.simdOrientation = filteredRotation
            self.currentRotation = filteredRotation
            if length(self.rotationVelocity) < 0.005 {
                self.rotationVelocity = .zero
            }
        } else {
            self.ship.simdOrientation = self.currentRotation
        }
    }
    func dragChanged(value: DragGesture.Value) {
        let translation = value.translation
        //print(translation.width, translation.height)
        let deltaX = Float(translation.width - self.previousTranslation.width) * 0.005
        let deltaY = Float(translation.height - self.previousTranslation.height) * 0.005
        // Update the averageRotationVelocity
        self.rotationVelocity = SIMD2<Float>(Float(deltaX), Float(deltaY))
        self.previousTranslation = translation
    }
    func dragEnded() {
        self.isDragging = false
        self.previousTranslation = .zero
        self.rotationVelocity = .zero
        self.initialTouchPoint = .zero
        self.rotationDeltaX = .zero
        self.rotationDeltaY = .zero
        self.isRotationActive = false
    }

    func findClosestHole() {
        // Find the closest black hole and its distance
    }
    
    func throttle(value: Float) {
        DispatchQueue.main.async {
            // Your throttle code here
            self.throttle = value
        }
    }
    
    func fireMissile(target: SCNNode? = nil) {
        // Your fireMissile code here
    }

    func hitTest() -> SCNNode? {
        // Your hitTest code here
        return nil
    }
}
