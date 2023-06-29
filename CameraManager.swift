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
    var followDistance: Float = 15
    var throttle: Float
    init(trackingState: CameraTrackState, scene: SCNScene, throttle: Float) {
        self.throttle = throttle
        self.cameraNode = SCNNode()
        self.trackingState = trackingState
        self.setupCamera(scene: scene)
    }
    public func updateCamera(for state: CameraTrackState, deltaTime: Float) {
        switch state {
        case .player(let ship):
            updateCameraForShip(ship: ship)
        case .missile(let missile):
            updateCameraMissile(node: missile)
        case .target(let target):
            updateCameraTarget(target: target)
        }
    }
    var pGain: SIMD3<Float> = SIMD3<Float>(0.5, 0.5, 0.5)
    var iGain: SIMD3<Float> = SIMD3<Float>(0.1, 0.1, 0.1)
    var dGain: SIMD3<Float> = SIMD3<Float>(0.2, 0.2, 0.2)
    
    var iMax: Float = 1
    var iMin: Float = -1
    var setPoint: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var integral: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var lastError: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    private func updateCameraForShip(ship: SCNNode) {
        // Track player ship
        let newOrientation = ship.presentation.simdOrientation
        let normalizedWorldFront = simd_normalize(ship.simdWorldFront)
        let cameraPosition = ship.simdPosition - (normalizedWorldFront * self.followDistance)
        let length = simd_length(ship.simdWorldFront)
        
        let mixFactor: Float = 0.1
        let t = simd_smoothstep(0.0, 1.0, mixFactor)
        let mixedX = simd_mix(self.cameraNode.presentation.simdPosition.x, cameraPosition.x, t)
        let mixedY = simd_mix(self.cameraNode.presentation.simdPosition.y, cameraPosition.y, t)
        let mixedZ = simd_mix(self.cameraNode.presentation.simdPosition.z, cameraPosition.z, t)
        
        self.cameraNode.simdPosition = cameraPosition
        self.cameraNode.simdOrientation = newOrientation // set the interpolated orientation
        //print(cameraNode.presentation.position, ship.presentation.position)
    }

    
    public func updateCameraTarget(target: SCNNode? = nil) {
        // Track missile from target
    }
    func throttle(value: Float) {
        // Your throttle code here
        self.throttle = value
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
        camera.zFar = 16_000_000
        camera.zNear = 1
        // Create a camera node and attach the camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        
        // Position the camera node relative to the spacecraft
        self.cameraNode.camera?.fieldOfView = 120
        
        self.addCameraToScene(for: scene)
        self.cameraNode.physicsBody = nil
    }
    public func addCameraToScene(for scene: SCNScene) {
        scene.rootNode.addChildNode(self.cameraNode)
    }
    private func createLookAtConstraintForNode(node: SCNNode) -> SCNConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: node)
        return lookAtConstraint
    }
}
