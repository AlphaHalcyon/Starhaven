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
    }
    func destroy() {
    }
    func update() {
        // Check if the current target is still valid
        if let target = self.target {
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
                    let chaseOffset = self.offset
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
                if Float.random(in: 0...1) > 0.998 {
                    //self.fireLaser(color: self.faction == .Wraith ? .red : .green)
                }
                if Float.random(in: 0...1) < 1/60 * 3 { // every 3 seconds {
                    self.fireMissile(target: self.target, particleSystemColor: self.faction == .Wraith ? .systemPink : .cyan)
                }
            }
        } else {
            self.selectNewTarget()
        }
    }
    // OPERATIONS
    func selectNewTarget() {
        let targets = self.sceneManager.sceneObjects.filter { $0.isAI }
        if let target = targets.randomElement() {
            self.target = target.node
        }
        self.target = targets.randomElement()?.node
    }
    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil, particleSystemColor: UIColor) {
        let missile = OSNRMissile(target: target, particleSystemColor: particleSystemColor, sceneManager: self.sceneManager)
        // Convert shipNode's local position to world position
        let worldPosition = self.node.convertPosition(SCNVector3(0, -10, 5), to: self.node.parent)
        
        missile.missileNode.position = worldPosition
        let direction = self.node.presentation.worldFront
        let missileMass = missile.missileNode.physicsBody?.mass ?? 1
        missile.missileNode.orientation = self.node.presentation.orientation
        missile.missileNode.eulerAngles.x += Float.pi / 2
        let missileForce = 12_500 * missileMass
        missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        self.sceneManager.addNode(missile.missileNode)
    }
}

class OSNRMissile {
    var missileNode: SCNNode = SCNNode()
    var target: SCNNode?
    var particleSystem: SCNParticleSystem = SCNParticleSystem()
    var explosionNode: SCNNode = SCNNode()
    var timer: Timer = Timer()
    var sceneManager: SceneManager
    static let missileGeometry: SCNNode = {
        // Create missile geometry and node
        guard let url = Bundle.main.url(forResource: "dh10", withExtension: "obj") else { return SCNNode() }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return SCNNode() }
        let node = SCNNode(mdlObject: object)
        node.scale = SCNVector3(15, 15, 15)
        return node
    }()
    private func addPhysicsBody() -> SCNPhysicsBody {
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        physicsBody.isAffectedByGravity = false
        physicsBody.friction = 0
        physicsBody.damping = 0
        return physicsBody
    }
    init(target: SCNNode? = nil, particleSystemColor: UIColor, sceneManager: SceneManager) {
        self.target = target
        self.sceneManager = sceneManager
        let node = ParticleManager.missileGeometry.flattenedClone()
        node.physicsBody = self.addPhysicsBody()
        self.missileNode = node
        // Create missile trail particle system
        self.particleSystem = ParticleManager.createMissileTrail(color: particleSystemColor)

        // Attach red particle system to the tail of the missile
        self.missileNode.addParticleSystem(self.particleSystem)
        DispatchQueue.main.async {
            
            if let target = self.target {
                self.missileNode.look(at: target.presentation.position)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
                self.detonate()
            }
        }
    }
    func setLookAtConstraint() {
        guard let target = self.target else { return }
        let lookAtConstraint = SCNLookAtConstraint(target: target)
        lookAtConstraint.isGimbalLockEnabled = true // This prevents the missile from flipping upside down
        self.missileNode.constraints = [lookAtConstraint]
    }
    func detonate() {
        self.missileNode.physicsBody?.velocity = SCNVector3(0,0,0)
        let pos = self.missileNode.presentation.worldPosition
        if Float.random(in: 0...1) > 0.10 { self.sceneManager.createExplosion(at: pos) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.missileNode.removeFromParentNode()
        }
    }
    func getMissileNode() -> SCNNode {
        return self.missileNode
    }
}
