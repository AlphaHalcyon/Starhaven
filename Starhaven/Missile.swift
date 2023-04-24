//
//  Missile.swift
//  Starhaven
//
//  Created by JxR on 4/12/23.
//

import Foundation
import SceneKit
import SwiftUI

class Missile {
    var missileNode: SCNNode
    var target: SCNNode?
    var redParticleSystem: SCNParticleSystem
    var explosionNode: SCNNode = SCNNode()
    init(target: SCNNode? = nil) {
        self.target = target
        
        // Create missile geometry and node
        let missileGeometry = SCNCylinder(radius: 0.5, height: 2)
        missileGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray
        missileNode = SCNNode(geometry: missileGeometry)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.missile
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        missileNode.physicsBody = physicsBody
        // Create red particle system
        redParticleSystem = SCNParticleSystem()
        redParticleSystem.particleColor = UIColor.red
        redParticleSystem.particleSize = 0.1
        redParticleSystem.birthRate = 10000
        redParticleSystem.emissionDuration = 1
        redParticleSystem.particleLifeSpan = 1
        redParticleSystem.spreadingAngle = 180
        redParticleSystem.emitterShape = missileGeometry
        redParticleSystem.emissionDurationVariation = redParticleSystem.emissionDuration
        // Attach red particle system to the tail of the missile
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, -1, 0)
        emitterNode.addParticleSystem(redParticleSystem)
        missileNode.addChildNode(emitterNode)
        self.missileNode.physicsBody?.isAffectedByGravity = false
        self.missileNode.physicsBody?.friction = 0
        self.missileNode.physicsBody?.damping = 0
        let detonationTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { _ in
            self.detonate()
            print("boom")
        }
        self.setLookAtConstraint()
        let trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.updateTracking()
        }
    }
    func updateTracking() {
        guard let target = self.target else { return }
        let direction = target.position - missileNode.position
        let directionNormalized = direction.normalized()

        // Update missile's velocity
        missileNode.physicsBody?.applyForce(directionNormalized * 10, asImpulse: true)
        missileNode.physicsBody?.applyForce(directionNormalized, asImpulse: true)
    }
    func setLookAtConstraint() {
        guard let target = self.target else { return }
        print(target)
        let lookAtConstraint = SCNLookAtConstraint(target: target)
        lookAtConstraint.isGimbalLockEnabled = true // This prevents the missile from flipping upside down
        self.missileNode.constraints = [lookAtConstraint]
    }

    func handleCollision() {
        detonate()
    }
    func detonate() {
        let coronaGeo = SCNSphere(radius: 50)
        
        // Create the particle system programmatically
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 500000
        fireParticleSystem.particleSize = 0.75
        fireParticleSystem.particleIntensity = 1
        fireParticleSystem.particleLifeSpan = 0.5
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 50
        fireParticleSystem.emitterShape = coronaGeo
        // Make the particle system surface-based
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        // Add the particle system to the warhead
        
        
        let implodeAction = SCNAction.scale(to: 10, duration: 0.5)
        let implodeActionStep = SCNAction.scale(to: 5, duration: 0.25)
        let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
        self.explosionNode.addParticleSystem(fireParticleSystem)
        self.missileNode.addChildNode(self.explosionNode)
        self.explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))
        // Remove the missile node from the scene after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.missileNode.removeFromParentNode()
        }
    }
    // In the Missile class, add the following function:
    func getMissileNode() -> SCNNode {
        return self.missileNode
    }

}
