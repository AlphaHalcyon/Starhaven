//
//  CameraManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

// Enum to replace missileTrackingState
enum CameraTrackState {
    case player(ship: SCNNode)
    case missile(missile: SCNNode) // Assuming you have a Missile class
    case target(target: SCNNode) // Assuming you have an Enemy class
}

class CameraManager {
    var cameraNode: SCNNode
    var trackingState: CameraTrackState
    var followDistance: Float = 100.0
    init(trackingState: CameraTrackState, scene: SCNScene) {
        self.cameraNode = SCNNode()
        self.trackingState = trackingState
        self.setupCamera(scene: scene)
    }
    public func updateCamera(for state: CameraTrackState) {
        switch state {
        case .player(let ship):
            updateCameraForShip(ship: ship)
        case .missile(let missile):
            updateCameraMissile(node: missile)
        case .target(let target):
            updateCameraTarget(target: target)
        }
    }
    
    private func updateCameraForShip(ship: SCNNode) {
        // Track player ship
        let newOrientation = ship.simdOrientation
        let cameraPosition = ship.presentation.simdPosition - (ship.simdWorldFront * self.followDistance)
        let mixFactor: Float = 1/30
        let mixedX = simd_mix(self.cameraNode.simdPosition.x, cameraPosition.x, mixFactor)
        let mixedY = simd_mix(self.cameraNode.simdPosition.y, cameraPosition.y, mixFactor)
        let mixedZ = simd_mix(self.cameraNode.simdPosition.z, cameraPosition.z, mixFactor)
        DispatchQueue.main.async {
            self.cameraNode.simdPosition = SIMD3<Float>(mixedX, mixedY, mixedZ)
            self.cameraNode.simdOrientation = newOrientation
            // Update the look-at constraint target
            self.cameraNode.constraints = [self.createLookAtConstraintForNode(node: ship)]
        }
    }

    public func updateCameraTarget(target: SCNNode? = nil) {
        // Track missile from target
    }
    
    public func updateCameraMissile(node: SCNNode) {
        // Track missile
        let newOrientation = node.simdOrientation
        let cameraPosition = node.presentation.simdPosition - (node.simdWorldFront * self.followDistance)
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
    private func setupCamera(scene: SCNScene) {
        // Create a camera
        let camera = SCNCamera()
        camera.zFar = 1_500_000
        camera.zNear = 1
        // Create a camera node and attach the camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        
        // Position the camera node relative to the spacecraft
        self.cameraNode.position = SCNVector3(x: 0, y: 5, z: 25)
        self.cameraNode.camera?.fieldOfView = 120
        self.addCameraToScene(for: scene)
    }
    public func addCameraToScene(for scene: SCNScene) {
        scene.rootNode.addChildNode(self.cameraNode)
    }
    private func createLookAtConstraintForNode(node: SCNNode) -> SCNConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: node)
        lookAtConstraint.isGimbalLockEnabled = true
        return lookAtConstraint
    }
}
