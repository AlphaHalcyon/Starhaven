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
    @Published var containerNode: SCNNode = SCNNode()
    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil) -> Missile {
        print("fire!")
        let missile = Missile(target: target)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -10, 0), to: containerNode.parent)
        
        missile.missileNode.position = worldPosition
        missile.missileNode.orientation = shipNode.presentation.orientation
        missile.missileNode.eulerAngles.x += Float.pi / 2
        let direction = shipNode.presentation.worldFront
        let missileMass = missile.missileNode.physicsBody?.mass ?? 1
        let missileForce = CGFloat(abs(throttle) + 1) * 125 * missileMass
        missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        containerNode.parent!.addChildNode(missile.missileNode)
        return missile
    }
    func fireLaser(target: SCNNode? = nil) {
        print("fire laser!")
        let laser = Laser(target: target)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -10, -1), to: containerNode.parent)
        
        laser.laserNode.position = worldPosition
        laser.laserNode.orientation = shipNode.presentation.orientation
        laser.laserNode.eulerAngles.x += Float.pi / 2
        let direction = shipNode.presentation.worldFront
        let laserMass = laser.laserNode.physicsBody?.mass ?? 1
        let laserForce = CGFloat(abs(throttle) + 1) * 750 * laserMass
        laser.laserNode.physicsBody?.applyForce(direction * Float(laserForce), asImpulse: true)
        containerNode.parent!.addChildNode(laser.laserNode)
    }
    // CREATION
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
        let wing1 = SCNBox(width: 2.0, height: 0.1, length: 5, chamferRadius: 0)
        wing1.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing1Node = SCNNode(geometry: wing1)
        wing1Node.position = SCNVector3(-3, 1, 0)
        node.addChildNode(wing1Node)

        let wing2 = SCNBox(width: 2.0, height: 0.1, length: 5, chamferRadius: 0)
        wing2.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing2Node = SCNNode(geometry: wing2)
        wing2Node.position = SCNVector3(3, 1, 0)
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
        self.shipNode = node
        self.containerNode = containerNode
        return containerNode
    }
}
