//
//  Missile.swift
//  Starhaven
//
//  Created by JxR on 4/12/23.
//

import Foundation
import SceneKit
import SwiftUI

@MainActor class Missile {
    var missileNode: SCNNode = SCNNode()
    var target: SCNNode?
    var particleSystem: SCNParticleSystem = SCNParticleSystem()
    var explosionNode: SCNNode = SCNNode()
    var timer: Timer = Timer()
    unowned var viewModel: SpacegroundViewModel
    init(target: SCNNode? = nil, particleSystemColor: UIColor, viewModel: SpacegroundViewModel) {
        self.viewModel = viewModel
        self.target = target
        // Create missile geometry and node
        self.missileNode = ParticleManager.missileGeometry.clone()
        self.missileNode.scale = SCNVector3(4, 4, 4)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.missile
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        // Create red particle system
        self.particleSystem = ParticleManager.createShipMissileTrail(color: .cyan)
        // Attach red particle system to the tail of the missile
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, 0, -25)
        emitterNode.addParticleSystem(self.particleSystem)
        DispatchQueue.main.async {
            self.missileNode.physicsBody = physicsBody
            self.missileNode.addChildNode(emitterNode)
            self.missileNode.physicsBody?.isAffectedByGravity = false
            self.missileNode.physicsBody?.friction = 0
            self.missileNode.physicsBody?.damping = 0
            self.missileNode.simdOrientation = self.viewModel.ship.shipNode.simdOrientation
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.missileNode.removeFromParentNode()
                if let node = self.viewModel.cameraMissile?.missileNode {
                    if node == self.missileNode {
                        self.viewModel.cameraMissile = nil
                        self.viewModel.inMissileView = false
                    }
                }
            }
        }
    }
    public func trackTarget() {
        if let target = self.target {
            // Predict the future position of the target
            let predictionTime: TimeInterval = 2
            let targetVelocity = target.physicsBody?.velocity ?? SCNVector3Zero
            let predictedTargetPosition = target.presentation.position + (targetVelocity * Float(predictionTime))
            // Update missile's velocity
            let newDirection = (predictedTargetPosition - self.missileNode.presentation.position).normalized()
            let missileSpeed: Float = 1_000 // Set the speed of the missile
            DispatchQueue.main.async {
                self.missileNode.physicsBody?.applyForce(newDirection * missileSpeed, asImpulse: true)
                //self.missileNode.look(at: newDirection)
            }
        }
        else {
            DispatchQueue.main.async {
                self.missileNode.physicsBody?.applyForce(self.missileNode.worldFront * 500, asImpulse: true)
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
        // Add the particle system to the warhead
        let implodeAction = SCNAction.scale(to: 5, duration: 0.25)
        let implodeActionStep = SCNAction.scale(to: 0, duration: 1)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep])
        DispatchQueue.main.async {
            self.explosionNode.addParticleSystem(ParticleManager.explosionParticleSystem)
            self.missileNode.physicsBody?.velocity = SCNVector3(0,0,0)
            self.viewModel.view.prepare([self.explosionNode]) { success in
                self.missileNode.addChildNode(self.explosionNode)
                self.explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))
                // Remove the missile node from the scene after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    self.missileNode.removeFromParentNode()
                    if let cameraMissile = self.viewModel.cameraMissile {
                        if cameraMissile.missileNode == self.missileNode {
                            self.viewModel.inMissileView = false
                            self.viewModel.cameraMissile = nil
                        }
                    }
                }
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
        hullMaterial.roughness.contents = 1
        
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
enum MissileTrackingState {
    case player
    case missile
    case target
}
