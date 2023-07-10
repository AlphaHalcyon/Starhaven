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
    var followDistance: Float = 1
    init(trackingState: CameraTrackState, scene: SCNScene) {
        self.cameraNode = SCNNode()
        self.trackingState = trackingState
        self.setupCamera(scene: scene)
    }
    public func updateCamera(deltaTime: Float) {
        switch self.trackingState {
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
        let newOrientation = ship.presentation.simdOrientation
        let normalizedWorldFront = simd_normalize(ship.simdWorldFront)
        let cameraPosition = ship.simdPosition - (normalizedWorldFront * self.followDistance)
        self.cameraNode.simdPosition = cameraPosition
        self.cameraNode.simdOrientation = newOrientation // set the interpolated orientation
        //print(cameraNode.presentation.position, ship.presentation.position)
    }

    public func updateCameraTarget(target: SCNNode? = nil) {
        // Track missile from target
    }
    func map(value: Float, inMin: Float, inMax: Float, outMin: Float, outMax: Float) -> Float {
        return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
    }
    
    public func updateCameraMissile(node: SCNNode) {
        // Track missile
        let newOrientation = node.simdOrientation
        let cameraPosition = node.presentation.simdPosition - (node.simdWorldFront * self.followDistance)
        let distance = simd_distance(cameraPosition, node.presentation.simdPosition)
        let mixFactor = map(value: distance, inMin: followDistance/2, inMax: followDistance, outMin: 0.1, outMax: 1)
        
        let mixedX = simd_mix(self.cameraNode.simdPosition.x, cameraPosition.x, mixFactor)
        let mixedY = simd_mix(self.cameraNode.simdPosition.y, cameraPosition.y, mixFactor)
        let mixedZ = simd_mix(self.cameraNode.simdPosition.z, cameraPosition.z, mixFactor)
        self.cameraNode.simdPosition = SIMD3<Float>(mixedX, mixedY, cameraPosition.z)
        self.cameraNode.simdOrientation = simd_slerp(self.cameraNode.simdOrientation, newOrientation, 0.5)
        // Update the look-at constraint target
        self.cameraNode.constraints = [self.createLookAtConstraintForNode(node: node)]
    }
    private func setupCamera(scene: SCNScene) {
        // Create a camera
        let camera = SCNCamera()
        camera.zFar = 200_000
        camera.zNear = 1
        // Create a camera node and attach the camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        
        // Position the camera node relative to the spacecraft
        self.cameraNode.camera?.fieldOfView = 90
        self.addCameraToScene(for: scene)
        self.cameraNode.physicsBody = nil
        self.cameraNode.camera?.categoryBitMask = 1
    }
    public func addCameraToScene(for scene: SCNScene) {
        scene.rootNode.addChildNode(self.cameraNode)
    }
    private func createLookAtConstraintForNode(node: SCNNode) -> SCNConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: node)
        return lookAtConstraint
    }
}
