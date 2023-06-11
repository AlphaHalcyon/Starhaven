//
//  GhostMissile.swift
//  Starhaven
//
//  Created by JxR on 5/3/23.
//

import Foundation
import SceneKit
import SwiftUI

@MainActor class GhostMissile {
    var missileNode: SCNNode = SCNNode()
    var target: SCNNode?
    var particleSystem: SCNParticleSystem = SCNParticleSystem()
    var explosionNode: SCNNode = SCNNode()
    var timer: Timer = Timer()
    unowned var viewModel: SpacegroundViewModel
    static let missileGeometry: SCNNode = {
        guard let url = Bundle.main.url(forResource: "dh10", withExtension: "obj") else { return SCNNode() }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return SCNNode() }
        let node = SCNNode(mdlObject: object)
        return node
    }()
    init(target: SCNNode? = nil, particleSystemColor: UIColor, viewModel: SpacegroundViewModel) {
        self.target = target
        self.viewModel = viewModel
        // Create missile geometry and node
        // Load the missile model
        self.missileNode = ParticleManager.missileGeometry.flattenedClone()
        self.missileNode.scale = SCNVector3(15, 15, 15)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        self.missileNode.physicsBody = physicsBody
        // Create missile trail particle system
        self.particleSystem = ParticleManager.createMissileTrail(color: particleSystemColor)

        // Attach red particle system to the tail of the missile
        self.missileNode.addParticleSystem(self.particleSystem)
        DispatchQueue.main.async {
            self.missileNode.physicsBody?.isAffectedByGravity = false
            self.missileNode.physicsBody?.friction = 0
            self.missileNode.physicsBody?.damping = 0
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
        if Float.random(in: 0...1) > 0.10 { self.viewModel.createExplosion(at: pos) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.missileNode.removeFromParentNode()
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
