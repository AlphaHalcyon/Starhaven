//
//  Pilot.swift
//  Starhaven
//
//  Created by JxR on 3/29/23.
//

import Foundation
import SwiftUI
import Metal
import SceneKit
import SceneKit.ModelIO
class Pilot: ObservableObject {
    @Published var pilotNode: SCNNode = SCNNode()
    @Published var cameraNode: SCNNode
    @Published var throttleValue: Float = 0
    @Published var joystickAngle: Float = 0
    
    init() {
        // Init our pilot :)
        let modelPath = Bundle.main.path(forResource: "Halcyon", ofType: "obj", inDirectory: "SceneKit Asset Catalog.scnassets")!
        let url = NSURL (fileURLWithPath: modelPath)
        let asset = MDLAsset(url:url as URL)
        let object = asset.object(at: 0)
        pilotNode = SCNNode(mdlObject: object)
        // Create a camera and attach it to the pilot node
        let camera = SCNCamera()
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        self.cameraNode.position = SCNVector3(x: 0, y: 150, z: 300)
        self.pilotNode.addChildNode(cameraNode)
        self.cameraNode.camera?.zFar = 1000.0
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.isAffectedByGravity = true
        physicsBody.setResting(false)
        physicsBody.mass = 1
        pilotNode.physicsBody = physicsBody
        pilotNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        pilotNode.geometry?.firstMaterial = material

        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        pilotNode.addChildNode(lightNode)
    }
    func update(throttleValue: Float, joystickAngle: Float) {
        print(self.throttleValue)
        self.throttleValue = throttleValue
        self.joystickAngle = joystickAngle
        updateCameraVelocity()
    }
    
    public func updateCameraVelocity() {
        let maxSpeed: Float = 20
        let speed = throttleValue * maxSpeed
        let forwardDirection = cameraNode.simdWorldFront
        let velocity = speed * forwardDirection
        var vector = SCNVector3(velocity.x, velocity.y, velocity.z)
        let velocityInWorldSpace = pilotNode.presentation.convertVector(vector, to: nil)
        let newPosition = pilotNode.position + velocityInWorldSpace
        let moveAction = SCNAction.move(to: newPosition, duration: 1)
        pilotNode.runAction(moveAction)
    }
}

