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

@MainActor class EnemyShip: ObservableObject {
    @State var spacegroundViewModel: SpacecraftViewModel
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var containerNode: SCNNode = SCNNode()
    @Published var currentTime: TimeInterval = 0.0
    @Published var currentTarget: SCNNode? = nil
    @Published var belligerentCount: Int = 0
    private var minimumFiringRange: Float = 0.0
    private var pursuitRange: Float = 0.0
    private var lastFiringTime: TimeInterval = 0.0
    private var firingInterval: TimeInterval = 0.0
    private var angle: Float = 0.0
    private let loiteringSpeed: Float = 1.0
    private let loiteringRadius: Float = 10.0

    // INIT
    init(spacegroundViewModel: SpacecraftViewModel) {
        self.spacegroundViewModel = spacegroundViewModel
        // Initialize new properties
        self.selectNewTarget()
    }
    // GHOST MOVEMENTS
    @MainActor func updateAI() {
        // Check if the current target is still valid
        if self.belligerentCount != self.spacegroundViewModel.belligerents.count {
            if currentTarget != nil {
                if !self.spacegroundViewModel.belligerents.contains(where: { $0 == currentTarget! }) { selectNewTarget() }
                self.belligerentCount = self.spacegroundViewModel.belligerents.count
            }
            else {
                selectNewTarget()
            }
        }
        
        // Update the enemy ship's behavior based on the current target
        if let target = currentTarget {
            // Create and apply a SCNLookAtConstraint to make the enemy ship always face the current target's position
            let constraint = SCNLookAtConstraint(target: target)
            constraint.isGimbalLockEnabled = true
            self.shipNode.constraints = [constraint]

            // Move the enemy ship towards the current target's position by a fixed amount on each frame
            let direction = target.worldPosition - self.shipNode.worldPosition
            let distance = direction.length()
            let normalizedDirection = SCNVector3(direction.x / distance, direction.y / distance, direction.z / distance)
            
            // Set a minimum distance between the enemy and player ships
            let minDistance: Float = 1000
            var speed: Float = 5
            
            // If the enemy ship is closer than the minimum distance, move it away from the player
            if distance > minDistance {
                speed *= Float.random(in: 0.5...1.05)
                self.shipNode.worldPosition = SCNVector3(self.shipNode.worldPosition.x + normalizedDirection.x * speed, self.shipNode.worldPosition.y + normalizedDirection.y * speed, self.shipNode.worldPosition.z + normalizedDirection.z * speed)
            }
            // Check if the target is within the specified range
            if distance > minDistance - 50 && distance < minDistance + 150 {
                // Engaging the target, fire weapons
                if Float.random(in: 0...1) > 1/30 { fireLaser() }
                //if Float.random(in: 0...1) > 0.95 { fireMissile() }
            }
        }
    }
    @MainActor func selectNewTarget() {
        // Filter out the current ship from the list of available targets
        let availableTargets = self.spacegroundViewModel.belligerents.filter { $0 != self.shipNode  }

        // Select a new target from the list of available targets
        if let newTarget = availableTargets.randomElement() {
            currentTarget = newTarget
            //print("target acquired!")
        } else {
            // No targets available
            currentTarget = nil
            print("no one left to kill :(")
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
    }
    func fireLaser(target: SCNNode? = nil) {
        print("fire!")
        let missile = Laser(target: target, color: .green)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -10, 0), to: containerNode.parent)
        
        missile.laserNode.position = worldPosition
        missile.laserNode.orientation = shipNode.presentation.orientation
        let direction = shipNode.presentation.worldFront
        let missileMass = missile.laserNode.physicsBody?.mass ?? 1
        let missileForce = CGFloat(throttle + 1) * 1000 * missileMass
        missile.laserNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        containerNode.parent!.addChildNode(missile.laserNode)
        
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
        self.shipNode.physicsBody?.collisionBitMask = CollisionCategory.laser | CollisionCategory.missile
        self.shipNode.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile

        return self.shipNode
    }
}
