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
    init(target: SCNNode? = nil, particleSystemColor: UIColor, viewModel: SpacegroundViewModel) {
        self.target = target
        self.viewModel = viewModel
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
        if Float.random(in: 0...1) > 0.10 { self.viewModel.createExplosion(at: pos) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.missileNode.removeFromParentNode()
        }
    }
    func getMissileNode() -> SCNNode {
        return self.missileNode
    }
}
