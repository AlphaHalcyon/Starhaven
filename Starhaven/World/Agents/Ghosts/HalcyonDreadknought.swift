//
//  HalcyonDreadknought.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
import Foundation
import SwiftUI
import SceneKit
import GLKit
import simd

class HalcyonDreadknought: ObservableObject {
    @State var spacegroundViewModel: SpacegroundViewModel
    @Published var shipNode: SCNNode = SCNNode()
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var containerNode: SCNNode = SCNNode()
    @Published var currentTime: TimeInterval = 0.0
    @Published var timer: Timer = Timer()
    @Published var faction: Faction
    @Published var scale: CGFloat = 0
    // INIT
    init(spacegroundViewModel: SpacegroundViewModel, faction: Faction = .Wraith) {
        self.spacegroundViewModel = spacegroundViewModel
        // Initialize new properties
        self.faction = faction // Faction.allCases.randomElement()!
        self.timer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            self.updateAI()
        }
    }
    // GHOST MOVEMENTS
    func updateAI() {
        DispatchQueue.main.async {
        }
    }
    // CREATION
    func createShip(scale: CGFloat = 1.0) -> SCNNode {
        let node = SCNNode()
        self.scale = scale
        node.geometry = SCNGeometry()
        // Create the main body of the spaceship
        let body = SCNCylinder(radius: 1.0 * scale, height: 10.0 * scale)
        body.firstMaterial?.diffuse.contents = UIColor.gray
        let bodyNode = SCNNode(geometry: body)
        bodyNode.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(bodyNode)

        // Create the rocket boosters
        let booster1 = SCNCylinder(radius: 0.5 * scale, height: 2.5 * scale)
        booster1.firstMaterial?.diffuse.contents = UIColor.darkGray
        let booster1Node = SCNNode(geometry: booster1)
        booster1Node.position = SCNVector3(-1.2 * scale, -1.0, 0)
        booster1Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(booster1Node)

        let booster2 = SCNCylinder(radius: 0.5 * scale, height: 2.5 * scale)
        booster2.firstMaterial?.diffuse.contents = UIColor.darkGray
        let booster2Node = SCNNode(geometry: booster2)
        booster2Node.position = SCNVector3(1.2 * scale, -1.0, 0)
        booster2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(booster2Node)

        // Create the wings
        let wing1 = SCNBox(width: 2.0 * scale, height: 0.1 * scale, length: 5 * scale, chamferRadius: 0)
        wing1.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing1Node = SCNNode(geometry: wing1)
        wing1Node.position = SCNVector3(-3 * scale, 1 * scale, 0)
        node.addChildNode(wing1Node)

        let wing2 = SCNBox(width: 2.0 * scale, height: 0.1 * scale, length: 5 * scale, chamferRadius: 0)
        wing2.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing2Node = SCNNode(geometry: wing2)
        wing2Node.position = SCNVector3(3 * scale, 1 * scale, 0)
        node.addChildNode(wing2Node)

        // Create missile tubes under the wings
        let missileTube1 = SCNCylinder(radius: 0.5 * scale, height: 3.5 * scale)
        missileTube1.firstMaterial?.diffuse.contents = UIColor.darkGray
        let missileTube1Node = SCNNode(geometry: missileTube1)
        missileTube1Node.position = SCNVector3(-1.5 * scale, 1.0 * scale, -1.2 * scale)
        missileTube1Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(missileTube1Node)

        let missileTube2 = SCNCylinder(radius: 0.5 * scale, height: 3.5 * scale)
        missileTube2.firstMaterial?.diffuse.contents = UIColor.darkGray
        let missileTube2Node = SCNNode(geometry: missileTube2)
        missileTube2Node.position = SCNVector3(1.5 * scale, 1.0 * scale, -1.2 * scale)
        missileTube2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(missileTube2Node)
        node.eulerAngles.x = 40
        node.position = SCNVector3(0, -10, 0)
        let containerNode = SCNNode()
        containerNode.geometry = SCNGeometry()
        containerNode.addChildNode(node)
        self.shipNode = node
        self.containerNode = containerNode
        // Create the physics body for the enemy ship using its geometry
        let shape = SCNPhysicsShape(node: shipNode, options: [.keepAsCompound: true])
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        shipNode.physicsBody?.isAffectedByGravity = false
        // Set the category, collision, and contact test bit masks
        self.shipNode.physicsBody?.categoryBitMask = CollisionCategory.enemyShip
        self.shipNode.physicsBody?.collisionBitMask = CollisionCategory.missile
        self.shipNode.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile
        shipNode.physicsBody?.collisionBitMask &= ~CollisionCategory.laser
        return self.shipNode
    }
}
