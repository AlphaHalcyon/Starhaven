//
//  PhysicsObject.swift
//  Starhaven
//
//  Created by JxR on 6/15/23.
//

import Foundation
import SceneKit
import SwiftUI

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
    var ship: SCNNode = SCNNode()
    var throttle: Float = 0
    var blackHoles: [BlackHole] // Assuming you have a BlackHole class
    var closestBlackHole: BlackHole?
    var missiles: [Missile] = [] // Assuming you have a Missile class
    // Navigation
    var currentRotation = simd_quatf(angle: 0, axis: simd_float3(x: 0, y: 1, z: 0))
    var rotationDeltaX: Float = 0
    var rotationDeltaY: Float = 0
    var rotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    var isRotationActive: Bool = false
    var isDragging: Bool = false
    var isPressed: Bool = false
    var isInverted: Bool = false
    var dampingFactor: Float = 0.666
    var previousTranslation: CGSize = CGSize.zero
    init(blackHoles: [BlackHole]) {
        self.ship = ModelManager.createShip()
        self.blackHoles = blackHoles
    }
    func update() {
        self.updateRotation()
        self.updateShipPosition()
        self.findClosestHole()
    }
    func updateShipPosition() {
        // Update the ship's position by its front face and throttle
        ship.simdPosition += ship.simdWorldFront * throttle
    }
    // Update the ship's orientation by the controller's rotation values
    func updateRotation() {
        print("Here")
        // Apply damping to the rotation velocity
        if !self.isDragging { self.rotationVelocity *= self.dampingFactor }
        let adjustedDeltaX = self.rotationVelocity.x
        let rotationY = simd_quatf(angle: adjustedDeltaX, axis: self.ship.simdWorldUp)
        let cameraRight = self.ship.simdWorldRight
        let rotationX = simd_quatf(angle: self.rotationVelocity.y, axis: cameraRight)

        let totalRotation = simd_mul(rotationY, rotationX)
        self.currentRotation = simd_mul(totalRotation, self.currentRotation)
        print(totalRotation)
        self.ship.simdOrientation = self.currentRotation
        // Stop the rotation when the velocity is below a certain threshold
        if length(self.rotationVelocity) < 0.01 {
            self.isPressed = false
            self.isRotationActive = false
            self.rotationVelocity = .zero
        }
    }
    func dragChanged(value: DragGesture.Value) {
        // Your dragChanged code here
        let translation = value.translation
        print(translation.width, translation.height)
        let deltaX = Float(translation.width - previousTranslation.width) * 0.005
        let deltaY = Float(translation.height - previousTranslation.height) * 0.005
        // Update the averageRotationVelocity
        self.rotationVelocity = SIMD2<Float>(Float(deltaX), Float(deltaY))
        self.previousTranslation = translation
        self.isRotationActive = true
    }
    
    func dragEnded() {
        // Your dragEnded code here
        self.isDragging = false
        self.previousTranslation = CGSize.zero
    }
    
    func findClosestHole() {
        // Find the closest black hole and its distance
    }
    
    func throttle(value: Float) {
        // Your throttle code here
    }
    
    func fireMissile(target: SCNNode? = nil) {
        // Your fireMissile code here
    }

    func hitTest() -> SCNNode? {
        // Your hitTest code here
        return nil
    }
}
