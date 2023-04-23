//
//  Ship.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit
import GLKit
import simd

class EnemyShip: ObservableObject {
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var containerNode: SCNNode = SCNNode()
    // Add new properties
    private var minimumFiringRange: Float = 0.0
    private var pursuitRange: Float = 0.0
    private var lastFiringTime: TimeInterval = 0.0
    private var firingInterval: TimeInterval = 0.0
    private var angle: Float = 0.0
    private let loiteringSpeed: Float = 1.0
    private let loiteringRadius: Float = 10.0
    @Published var currentTime: TimeInterval = 0.0
    // INIT
    init() {
        // Initialize new properties
        minimumFiringRange = Float.random(in: 25...50)
        pursuitRange = Float.random(in: 200...300)
        firingInterval = TimeInterval.random(in: 1.0...3.0)
    }
    // GHOST MOVEMENTS
    func updateAI(playerShip: Ship) {
        // Create and apply a SCNLookAtConstraint to make the enemy ship always face the player's position
        let constraint = SCNLookAtConstraint(target: playerShip.shipNode)
        constraint.isGimbalLockEnabled = true
        self.shipNode.constraints = [constraint]

        // Move the enemy ship towards the player's position by a fixed amount on each frame
        let direction = playerShip.shipNode.worldPosition - self.shipNode.worldPosition
        let distance = direction.length()
        let normalizedDirection = SCNVector3(direction.x / distance, direction.y / distance, direction.z / distance)
        
        // Set a minimum distance between the enemy and player ships
        let minDistance: Float = 300
        var speed: Float = 10
        
        // If the enemy ship is closer than the minimum distance, move it away from the player
        if distance > minDistance {
            print(distance)
            speed *= Float.random(in: 0.5...1.5)
            self.shipNode.worldPosition = SCNVector3(self.shipNode.worldPosition.x + normalizedDirection.x * speed, self.shipNode.worldPosition.y + normalizedDirection.y * speed, self.shipNode.worldPosition.z + normalizedDirection.z * speed)
        }
    }
    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil) {
        print("fire!")
        let missile = Missile(target: target)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -10, 0), to: containerNode.parent)
        
        missile.missileNode.position = worldPosition
        missile.missileNode.orientation = shipNode.presentation.orientation
        let direction = shipNode.presentation.worldFront
        let missileMass = missile.missileNode.physicsBody?.mass ?? 1
        let missileForce = CGFloat(throttle + 1) * 60 * missileMass
        missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        containerNode.parent!.addChildNode(missile.missileNode)
        
        print(missile.missileNode.position)
        print(containerNode.position)
        print(shipNode.position)
    }
    func fireLaser(target: SCNNode? = nil) {
        print("fire!")
        let missile = Laser(target: target)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -10, 0), to: containerNode.parent)
        
        missile.laserNode.position = worldPosition
        missile.laserNode.orientation = shipNode.presentation.orientation
        let direction = shipNode.presentation.worldFront
        let missileMass = missile.laserNode.physicsBody?.mass ?? 1
        let missileForce = CGFloat(throttle + 1) * 60 * missileMass
        missile.laserNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        containerNode.parent!.addChildNode(missile.laserNode)
        
        print(missile.laserNode.position)
        print(containerNode.position)
        print(shipNode.position)
    }

    // CREATION
    func createShip(scale: CGFloat = 1.0) -> SCNNode {
        let node = SCNNode()
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
        node.eulerAngles.x = 25
        node.position = SCNVector3(0, -10, 0)
        let containerNode = SCNNode()
        containerNode.geometry = SCNGeometry()
        containerNode.addChildNode(node)
        self.shipNode = node
        self.containerNode = containerNode
        // Create the physics body for the enemy ship using its geometry
        let nodes = [shipNode] + shipNode.childNodes
        let shape = SCNPhysicsShape(node: shipNode, options: [.keepAsCompound: true])
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        // Set the category, collision, and contact test bit masks
        self.shipNode.physicsBody?.categoryBitMask = CollisionCategory.enemyShip
        self.shipNode.physicsBody?.collisionBitMask = CollisionCategory.laser | CollisionCategory.missile
        self.shipNode.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile

        return containerNode
    }
    func createEmitterNode() {
        self.rearEmitterNode.position = SCNVector3(0, 0, 5)
        self.rearEmitterNode.addParticleSystem(self.waterParticleSystem)
        self.rearEmitterNode.addParticleSystem(self.fireParticleSystem)
        //self.shipNode.childNodes.first!.addChildNode(self.rearEmitterNode)
        
        // Create emitters for each wing
        let leftWingEmitterNode = SCNNode()
        let rightWingEmitterNode = SCNNode()
        leftWingEmitterNode.position = SCNVector3(-5, 0, 0)
        rightWingEmitterNode.position = SCNVector3(5, 0, 0)
        // Configure particle systems for each wing
        self.createWaterParticles()
        // Add particle systems to the wing emitter nodes
        leftWingEmitterNode.addParticleSystem(waterParticleSystem)
        rightWingEmitterNode.addParticleSystem(waterParticleSystem)

        // Add wing emitter nodes to the wings
        let leftWingNode = self.shipNode.childNodes.first!.childNodes[3] // Assuming wing1Node is at index 3
        let rightWingNode = self.shipNode.childNodes.first!.childNodes[4] // Assuming wing2Node is at index 4
        leftWingNode.addChildNode(leftWingEmitterNode)
        rightWingNode.addChildNode(rightWingEmitterNode)
    }
    func createWaterParticles() {
        let geoMap = shipNode.childNodes.first!.childNodes.first!.geometry
        // Create the particle system programmatically
        self.waterParticleSystem.particleColor = UIColor.cyan
        self.waterParticleSystem.particleSize = 0.005
        self.waterParticleSystem.birthRate = 100000
        self.waterParticleSystem.particleIntensity = 0.3
        self.waterParticleSystem.emissionDuration = 1
        self.waterParticleSystem.particleLifeSpan = 0.1
        self.waterParticleSystem.emitterShape = shipNode.childNodes.first?.geometry
        self.waterParticleSystem.particleAngularVelocity = 50
        self.waterParticleSystem.emittingDirection = SCNVector3(x: 0, y: 0, z: 0)
        // Make the particle system surface-based
        self.waterParticleSystem.emissionDurationVariation = waterParticleSystem.emissionDuration
        self.waterParticleSystem.emitterShape = geoMap
    }
}
