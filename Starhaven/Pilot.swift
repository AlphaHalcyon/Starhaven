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
import GLKit

class Pilot: ObservableObject {
    @Published var pilotNode: SCNNode = SCNNode()
    @Published var cameraNode: SCNNode = SCNNode()
    @Published var throttleValue: Float = 0
    @Published var joystickAngle: Float = 0
    @Published var containerNode = SCNNode()
    
    init() {
        let modelPath = Bundle.main.path(forResource: "fish", ofType: "obj", inDirectory: "SceneKit Asset Catalog.scnassets")!
        let url = NSURL (fileURLWithPath: modelPath)
        let asset = MDLAsset(url:url as URL)
        let object = asset.object(at: 0)
        var node = SCNNode(mdlObject: object)
        let whiteMaterial = SCNMaterial()
        let size = CGSize(width: 256, height: 256)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor.black.cgColor, UIColor.white.cgColor, UIColor(red: 0.678, green: 0.847, blue: 0.902, alpha: 1.0).cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        whiteMaterial.diffuse.contents = image
        node.geometry?.materials = [whiteMaterial]
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 10000
        particleSystem.particleLifeSpan = 0.5
        particleSystem.particleVelocity = 1000
        particleSystem.particleVelocityVariation = 5
        particleSystem.particleSize = 0.1
        particleSystem.particleColor = .cyan
        particleSystem.emitterShape = SCNTorus()
        particleSystem.emittingDirection = SCNVector3(x: 0, y: 0, z: 1)

        let particleNode = SCNNode()
        particleNode.addParticleSystem(particleSystem)
        particleNode.position = SCNVector3(x: 0, y: 0, z: -5)
        particleNode.particleSystems?.first?.blendMode = SCNParticleBlendMode(rawValue: 0)!
        let particleNode2 = SCNNode()
        particleNode.addParticleSystem(particleSystem)
        particleNode.position = SCNVector3(x: 1, y: 0, z: -5)
        particleNode.particleSystems?.first?.blendMode = SCNParticleBlendMode(rawValue: 0)!
        //node.addChildNode(particleNode)
        //node.addChildNode(particleNode2)
        pilotNode = node
        // Create a container node
        // Add the pilot node to the container node
        containerNode.addChildNode(pilotNode)
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.light!.intensity = 200.0
        lightNode.light?.zFar = 10000.0
        lightNode.position = SCNVector3(x: 0, y: 0, z: 0)
        self.pilotNode.addChildNode(lightNode)
        // Create a camera and attach it to the container node
        let camera = SCNCamera()
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        containerNode.addChildNode(cameraNode)
        self.cameraNode.camera?.zFar = 10000.0
        // Add the container node to the scene
        pilotNode.renderingOrder = 0
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.all]
        pilotNode.constraints = [billboardConstraint]
    }
    func update(throttleValue: Float, joystickAngle: Float) {
        print(self.throttleValue)
        self.throttleValue = throttleValue
        self.joystickAngle = joystickAngle
        updateCameraVelocity()
    }
    
    public func updateCameraVelocity() {
        let maxSpeed: Float = 100
        let speed = throttleValue * maxSpeed
        let forwardDirection = cameraNode.simdWorldFront
        let velocity = speed * forwardDirection
        var vector = SCNVector3(velocity.x, velocity.y, velocity.z)
        let velocityInWorldSpace = containerNode.presentation.convertVector(vector, to: nil)
        let newPosition = containerNode.position + velocityInWorldSpace
        let moveAction = SCNAction.move(to: newPosition, duration: 1)
        containerNode.runAction(moveAction)
        
        // Calculate angle between camera's world up vector and y-axis
        let yAxis = GLKVector3Make(0, 1, 0)
        let cameraUp = GLKVector3Make(cameraNode.worldUp.x, cameraNode.worldUp.y, cameraNode.worldUp.z)
        let angle = acos(GLKVector3DotProduct(GLKVector3Normalize(cameraUp), GLKVector3Normalize(yAxis)))
        
        // Adjust distanceFromCamera based on angle
        let minDistance: Float = 5
        let maxDistance: Float = 10
        let distanceFromCamera = minDistance + (maxDistance - minDistance) * (1-angle / .pi)
        
        // Update pilot node position based on camera node orientation
        let cameraAngles = cameraNode.eulerAngles
        let offsetX = -sin(cameraAngles.y) * distanceFromCamera
        let offsetY = sin(cameraAngles.x) * distanceFromCamera
        let offsetZ = -cos(cameraAngles.y) * distanceFromCamera
        let newPositionOfPilotNode = SCNVector3(cameraNode.position.x + offsetX, cameraNode.position.y + offsetY, cameraNode.position.z + offsetZ)
        
        // Animate pilot node's position change
        let movePilotNodeAction = SCNAction.move(to: newPositionOfPilotNode, duration: 0.1)
        pilotNode.runAction(movePilotNodeAction)
    }
}
