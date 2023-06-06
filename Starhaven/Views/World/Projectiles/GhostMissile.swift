//
//  GhostMissile.swift
//  Starhaven
//
//  Created by JxR on 5/3/23.
//

import Foundation
import SceneKit
import SwiftUI

class GhostMissile {
    var missileNode: SCNNode = SCNNode()
    var target: SCNNode?
    var particleSystem: SCNParticleSystem = SCNParticleSystem()
    var explosionNode: SCNNode = SCNNode()
    var timer: Timer = Timer()
    init(target: SCNNode? = nil, particleSystemColor: UIColor) {
        self.target = target
        // Create missile geometry and node
        // Load the missile model
        self.missileNode = loadOBJModel(named: "dh10") ?? SCNNode()
        self.missileNode.scale = SCNVector3(25, 25, 25)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        self.missileNode.physicsBody = physicsBody
        // Create red particle system
        self.particleSystem.particleColor = particleSystemColor
        self.particleSystem.particleSize = 2
        self.particleSystem.birthRate = 10_000
        self.particleSystem.emissionDuration = 1
        self.particleSystem.particleLifeSpan = 0.1
        self.particleSystem.spreadingAngle = 180
        self.particleSystem.emitterShape = missileNode.geometry
        self.particleSystem.emissionDurationVariation = self.particleSystem.emissionDuration
        
        // Attach red particle system to the tail of the missile
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, 0, -25)
        emitterNode.addParticleSystem(self.particleSystem)
        DispatchQueue.main.async {
            self.missileNode.addChildNode(emitterNode)
            self.missileNode.physicsBody?.isAffectedByGravity = false
            self.missileNode.physicsBody?.friction = 0
            self.missileNode.physicsBody?.damping = 0
            if self.target != nil {
                self.updateTracking()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.missileNode.physicsBody?.velocity = SCNVector3(0, 0, 0)
                self.detonate()
            }
        }
    }
    func updateTracking() {
        if let target = self.target {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.trackTarget()
            })
        } else { return }
    }
    func trackTarget() {
        if let target = self.target {
            let direction = target.position - self.missileNode.position
            _ = direction.normalized()
            // Predict the future position of the target
            let predictionTime: TimeInterval = 5
            let targetVelocity = target.physicsBody?.velocity ?? SCNVector3Zero
            let predictedTargetPosition = target.position + (targetVelocity * Float(predictionTime))
            // Update missile's velocity
            let newDirection = predictedTargetPosition - self.missileNode.position
            DispatchQueue.main.async {
                self.missileNode.physicsBody?.velocity.x = newDirection.x/1.5
                self.missileNode.physicsBody?.velocity.y = newDirection.y/1.5
                self.missileNode.physicsBody?.velocity.z = newDirection.z/1.5
            }
        }
    }
    func setLookAtConstraint() {
        guard let target = self.target else { return }
        let lookAtConstraint = SCNLookAtConstraint(target: target)
        lookAtConstraint.isGimbalLockEnabled = true // This prevents the missile from flipping upside down
        self.missileNode.constraints = [lookAtConstraint]
    }

    func handleCollision() {
        self.detonate() // boom
    }
    func detonate() {
        self.timer.invalidate()
        let coronaGeo = SCNSphere(radius: 100)
        
        // Create the particle system programmatically
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 1000000
        fireParticleSystem.particleSize = 0.5
        fireParticleSystem.particleIntensity = 0.90
        fireParticleSystem.particleLifeSpan = 0.30
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 90
        fireParticleSystem.emitterShape = coronaGeo
        // Make the particle system surface-based
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        // Add the particle system to the warhead
        let implodeAction = SCNAction.scale(to: 10, duration: 0.20)
        let implodeActionStep = SCNAction.scale(to: 5, duration: 1)
        let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
        DispatchQueue.main.async {
            self.explosionNode.addParticleSystem(fireParticleSystem)
            self.missileNode.addChildNode(self.explosionNode)
            self.explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))
            // Remove the missile node from the scene after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                self.missileNode.removeFromParentNode()
            }
        }
    }
    // In the Missile class, add the following function:
    func getMissileNode() -> SCNNode {
        return self.missileNode
    }
    func loadOBJModel(named name: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else { return nil }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return nil }
        let node = SCNNode(mdlObject: object)
        return self.applyHullMaterials(to: node)
    }
    func applyHullMaterials(to node: SCNNode) -> SCNNode {
        // Create a material for the hull
        let hullMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = UIColor.white
        hullMaterial.lightingModel = .physicallyBased
        hullMaterial.metalness.contents = 1.0
        hullMaterial.roughness.contents = 0.2
        
        // Create a material for the handprint
        //let handprintMaterial = SCNMaterial()
        //handprintMaterial.diffuse.contents = UIImage(named: "handprint.png")
        
        // Create a material for the white lines
        let linesMaterial = SCNMaterial()
        linesMaterial.diffuse.contents = UIColor.white
        
        // Apply the materials to the geometry of the node
        node.geometry?.materials = [hullMaterial, linesMaterial]
        return node
    }
}
