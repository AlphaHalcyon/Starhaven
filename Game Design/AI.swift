//
//  AI.swift
//  Starhaven
//
//  Created by JxR on 6/20/23.
//

import Foundation
import SceneKit
import SwiftUI

class AI: SceneObject {
    var node: SCNNode
    var faction: Faction
    var target: SCNNode? = nil
    var isAI: Bool = true
    var offset: SCNVector3 = SCNVector3(0,0,0)
    var sceneManager: SceneManager
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.node = node
        self.sceneManager = sceneManager
        self.faction = .OSNR
    }
    init(node: SCNNode, faction: Faction, sceneManager: SceneManager) {
        self.node = node
        self.faction = faction
        self.sceneManager = sceneManager
        let shape = SCNPhysicsShape(node: self.node, options: [.keepAsCompound: true])
        self.node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.node.physicsBody?.isAffectedByGravity = false
        // Set the category, collision, and contact test bit masks
        self.node.physicsBody?.categoryBitMask = CollisionCategory.enemyShip
        self.node.physicsBody?.collisionBitMask = CollisionCategory.missile
        self.node.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile
        self.node.physicsBody?.collisionBitMask &= ~CollisionCategory.laser
        let system = SCNParticleSystem()
        system.particleColor = faction == .OSNR ? .systemPink : .cyan
        system.emitterShape = self.node.geometry
        system.particleSize = 5
        system.birthRate = 30
        system.particleAngularVelocity = 0
        system.particleLifeSpan = 0.1
        let particleNode = SCNNode()
        particleNode.addParticleSystem(system)
        particleNode.position = SCNVector3(0, 30, 0)
        self.node.addChildNode(particleNode)
    }
    func destroy() {
    }
    func update(updateAtTime time: TimeInterval) {
        // Check if the current target is still valid
        if let target = self.target { if !self.sceneManager.sceneObjects.contains(where: {$0.node == target}) { self.selectNewTarget() }
            let pos = self.node.worldPosition
            let targetPos = target.worldPosition
            // Update the enemy ship's behavior based on the current target
            // Create and apply a SCNLookAtConstraint to make the enemy ship always face the current target's position
            let constraint = SCNLookAtConstraint(target: target)
            constraint.isGimbalLockEnabled = true
            // Move the enemy ship towards the current target's position by a fixed amount on each frame
            let direction = targetPos - pos
            let distance = direction.length()
            let normalizedDirection = SCNVector3(direction.x / distance, direction.y / distance, direction.z / distance)
            
            // Set a minimum distance between the enemy and player ships
            let minDistance: Float = 35_000
            
            DispatchQueue.main.async {
                self.node.constraints = [constraint]
                let speed: Float = 8 * Float.random(in: 0.5...1.05)
                
                if distance < minDistance {
                    // Complex chase
                    let chaseOffset = self.getChaseOffset(updateAtTime: time)
                    self.node.worldPosition = SCNVector3(
                        self.node.worldPosition.x + chaseOffset.x * speed,
                        self.node.worldPosition.y + chaseOffset.y * speed,
                        self.node.worldPosition.z + chaseOffset.z * speed
                    )
                } else if distance > minDistance {
                    self.node.worldPosition = SCNVector3(
                        self.node.worldPosition.x + normalizedDirection.x * speed,
                        self.node.worldPosition.y + normalizedDirection.y * speed,
                        self.node.worldPosition.z + normalizedDirection.z * speed
                    )
                }
                if Float.random(in: 0...1) < 1/500 {
                    self.fireMissile(target: self.target, particleSystemColor: self.faction == .OSNR ? .red : .cyan)
                }
            }
        } else {
            self.selectNewTarget()
        }
    }
    // OPERATIONS
    func getChaseOffset(updateAtTime time: TimeInterval) -> SCNVector3 {
        // Define the scale of the sinusoidal chase
        let chaseScale: Float = 0.025

        // Combine multiple sinusoids for a more complex chase pattern
        let chaseSpiralOffset = SCNVector3(
            chaseScale * cos(Float(time) / 3),
            chaseScale * sin(Float(time) / 1.5),
            chaseScale * cos(Float(time) / 2)
        )

        return chaseSpiralOffset
    }
    func selectNewTarget() {
        let targets = self.sceneManager.sceneObjects.filter { $0.isAI && $0.faction != self.faction }
        if let target = targets.randomElement() {
            self.target = target.node
        }
        self.target = targets.randomElement()?.node
    }
    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil, particleSystemColor: UIColor) {
        let missile: OSNRMissile
        if self.sceneManager.missiles.isEmpty {
            missile = OSNRMissile(target: target, particleSystemColor: particleSystemColor, sceneManager: self.sceneManager)
            self.fire(missile: missile.missileNode)
        } else if let missile = self.sceneManager.missiles.popLast() {
            missile.target = target
            missile.faction = faction
            missile.particleSystem.particleColor = particleSystemColor
            self.fire(missile: missile.missileNode)
            missile.fire()
        }
        
    }
    func fire(missile: SCNNode) {
        missile.position = self.node.position
        missile.physicsBody?.velocity = SCNVector3(0,0,0)
        let direction = self.node.presentation.worldFront
        let missileMass = missile.physicsBody?.mass ?? 1
        missile.orientation = self.node.presentation.orientation
        missile.eulerAngles.x += Float.pi / 2
        let missileForce = 650 * missileMass
        self.sceneManager.addNode(missile)
        DispatchQueue.main.async {
            missile.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        }
    }
}
