//
//  Ship.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit

class Ship: ObservableObject {
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    func createShip() -> SCNNode {
        let node = SCNNode()
        node.geometry = SCNGeometry()
        // Create the main body of the spaceship
        let body = SCNCylinder(radius: 1.0, height: 4.0)
        body.firstMaterial?.diffuse.contents = UIColor.gray
        let bodyNode = SCNNode(geometry: body)
        bodyNode.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(bodyNode)

        // Create the rocket boosters
        let booster1 = SCNCylinder(radius: 0.4, height: 2.0)
        booster1.firstMaterial?.diffuse.contents = UIColor.darkGray
        let booster1Node = SCNNode(geometry: booster1)
        booster1Node.position = SCNVector3(-1.2, -1.0, 0)
        booster1Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(booster1Node)

        let booster2 = SCNCylinder(radius: 0.4, height: 2.0)
        booster2.firstMaterial?.diffuse.contents = UIColor.darkGray
        let booster2Node = SCNNode(geometry: booster2)
        booster2Node.position = SCNVector3(1.2, -1.0, 0)
        booster2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(booster2Node)

        // Create the wings
        let wing1 = SCNBox(width: 3.0, height: 0.1, length: 5, chamferRadius: 0)
        wing1.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing1Node = SCNNode(geometry: wing1)
        wing1Node.position = SCNVector3(0, 0, -1.2)
        node.addChildNode(wing1Node)

        let wing2 = SCNBox(width: 3.0, height: 0.1, length: 5, chamferRadius: 0)
        wing2.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing2Node = SCNNode(geometry: wing2)
        wing2Node.position = SCNVector3(0, 0, 1.2)
        node.addChildNode(wing2Node)

        // Create missile tubes under the wings
        let missileTube1 = SCNCylinder(radius: 0.5, height: 3.5)
        missileTube1.firstMaterial?.diffuse.contents = UIColor.darkGray
        let missileTube1Node = SCNNode(geometry: missileTube1)
        missileTube1Node.position = SCNVector3(-1.5, 1.0, -1.2)
        missileTube1Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(missileTube1Node)

        let missileTube2 = SCNCylinder(radius: 0.5, height: 3.5)
        missileTube2.firstMaterial?.diffuse.contents = UIColor.darkGray
        let missileTube2Node = SCNNode(geometry: missileTube2)
        missileTube2Node.position = SCNVector3(1.5, 1.0, -1.2)
        missileTube2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(missileTube2Node)
        node.eulerAngles.x = 25
        node.position = SCNVector3(0, -10, 0)
        let containerNode = SCNNode()
        containerNode.geometry = SCNGeometry()
        containerNode.addChildNode(node)
        return containerNode
    }
    func createEmitterNode() {
        self.rearEmitterNode.position = SCNVector3(0, 0, 0)
        self.rearEmitterNode.addParticleSystem(self.waterParticleSystem)
        self.rearEmitterNode.addParticleSystem(self.fireParticleSystem)
        self.shipNode.childNodes.first!.addChildNode(self.rearEmitterNode)
    }
    func createFireParticles() {
        let geoMap = shipNode.childNodes.first!.geometry
        // Create the particle system programmatically
        self.fireParticleSystem.particleColor = UIColor.cyan
        self.fireParticleSystem.particleSize = 0.05
        self.fireParticleSystem.particleIntensity = 0.8
        self.fireParticleSystem.particleLifeSpan = 3
        self.fireParticleSystem.particleLifeSpanVariation = 1
        self.fireParticleSystem.spreadingAngle = 180
        self.fireParticleSystem.emitterShape = geoMap
        self.fireParticleSystem.particleDiesOnCollision = true
        // Make the particle system surface-based
        self.fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
    }
    func createWaterParticles() {
        let geoMap = shipNode.childNodes.first!.childNodes.first!.geometry
        // Create the particle system programmatically
        self.waterParticleSystem.particleColor = UIColor.cyan
        self.waterParticleSystem.particleSize = 0.0725
        self.waterParticleSystem.particleIntensity = 1
        self.waterParticleSystem.particleLifeSpan = 3
        self.waterParticleSystem.particleLifeSpanVariation = 1
        self.waterParticleSystem.particleDiesOnCollision = true
        self.waterParticleSystem.spreadingAngle = 180
        self.waterParticleSystem.emitterShape = shipNode.childNodes.first?.geometry
        self.fireParticleSystem.particleAngularVelocity = 50
        // Make the particle system surface-based
        self.waterParticleSystem.emissionDurationVariation = waterParticleSystem.emissionDuration
        self.waterParticleSystem.birthRate = self.throttle > 0 ? 20000 : 0
        self.waterParticleSystem.isLocal = true
    }
}
