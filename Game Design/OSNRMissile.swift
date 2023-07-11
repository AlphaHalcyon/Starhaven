//
//  OSNRMissile.swift
//  Starhaven
//
//  Created by Jared on 7/10/23.
//

import Foundation
import SceneKit

class OSNRMissile: SceneObject {
    var node: SCNNode
    var velocity: SCNVector3 = SCNVector3Zero
    var isAI: Bool = false
    var missileNode: SCNNode = SCNNode()
    var target: SCNNode?
    var particleSystem: SCNParticleSystem = SCNParticleSystem()
    var explosionNode: SCNNode = SCNNode()
    var timer: Timer = Timer()
    var sceneManager: SceneManager
    var faction: Faction = .OSNR
    init(target: SCNNode? = nil, particleSystemColor: UIColor, sceneManager: SceneManager, faction: Faction = .OSNR) {
        self.node = ModelManager.missileGeometry.flattenedClone()
        self.faction = faction
        self.target = target
        self.sceneManager = sceneManager
        self.node.physicsBody = self.addPhysicsBody()
        self.missileNode = node
        // Create missile trail particle system
        self.particleSystem = ParticleManager.createMissileTrail(color: particleSystemColor)
        
        // Attach red particle system to the tail of the missile
        self.missileNode.addParticleSystem(self.particleSystem)
        self.fire()
    }
    required init(node: SCNNode = SCNNode(), sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        self.target = nil
        self.node = node
    }
    func fire() {
        if let target = self.target {
            self.missileNode.look(at: target.presentation.position)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.destroy()
        }
    }
    func update(updateAtTime time: TimeInterval) {
        // Manually update the missile's position based on its velocity
        self.missileNode.position = self.missileNode.position + self.velocity
    }
    func destroy() {
        let pos = self.missileNode.presentation.worldPosition
        self.sceneManager.createExplosion(at: pos)
        self.missileNode.removeFromParentNode()
        DispatchQueue.main.async {
            self.sceneManager.missiles.append(self)
        }
    }
    func setPosition(at position: SCNVector3, towards target: SCNNode, faction: Faction) {
        self.node.position = position
        self.target = target
        self.particleSystem.particleColor = faction == .OSNR ? .red : .cyan
        self.fire()
    }
    
    // PHYSICS INIT
    private func addPhysicsBody() -> SCNPhysicsBody {
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.celestial
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip | CollisionCategory.celestial
        physicsBody.isAffectedByGravity = false
        physicsBody.friction = 0
        physicsBody.damping = 0
        return physicsBody
    }
    func setLookAtConstraint() {
        guard let target = self.target else { return }
        let lookAtConstraint = SCNLookAtConstraint(target: target)
        lookAtConstraint.isGimbalLockEnabled = true // This prevents the missile from flipping upside down
        self.missileNode.constraints = [lookAtConstraint]
    }
}
