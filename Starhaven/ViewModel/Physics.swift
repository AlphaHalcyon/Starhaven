//
//  PhysicsManager.swift
//  Starhaven
//
//  Created by JxR on 6/9/23.
//

import Foundation
import SceneKit

class Physics: NSObject, SCNPhysicsContactDelegate {
    var scene: SCNScene
    var ghosts: [Raider]
    var missiles: [Missile]
    var view: SCNView
    init(scene: SCNScene, ghosts: [Raider], missiles: [Missile], view: SCNView) {
        self.scene = scene
        self.ghosts = ghosts
        self.missiles = missiles
        self.view = view
    }
    // CONTACT HANDLING
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if let contactBodyA = contact.nodeA.physicsBody, let contactBodyB = contact.nodeB.physicsBody {
            let contactMask = contactBodyA.categoryBitMask | contactBodyB.categoryBitMask
            switch contactMask {
            case CollisionCategory.laser | CollisionCategory.enemyShip:
                self.handleLaserEnemyCollision(contact: contact)
            case CollisionCategory.missile | CollisionCategory.enemyShip:
                self.handleMissileEnemyCollision(contact: contact)
            default:
                return
            }
        }
    }
    func death(node: SCNNode, enemyNode: SCNNode) {
        self.createExplosion(at: enemyNode.position)
        DispatchQueue.main.async {
            node.removeFromParentNode()
            enemyNode.removeFromParentNode()
            self.ghosts = self.ghosts.filter { $0.shipNode != enemyNode }
        }
    }
    func handleLaserEnemyCollision(contact: SCNPhysicsContact) {
        if let contactBody = contact.nodeA.physicsBody {
            let laserNode = contactBody.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
            let enemyNode = contactBody.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            // call functions
        }
    }
    func handleMissileEnemyCollision(contact: SCNPhysicsContact) {
        // Determine which node is the missile and which is the enemy ship
        let missileNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.missile ? contact.nodeA : contact.nodeB
        let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
        
        // call functions
    }
    func createExplosion(at position: SCNVector3) {
        let explosionNode = SCNNode()
        explosionNode.position = position
        explosionNode.addParticleSystem(ParticleManager.explosionParticleSystem)
        
        let implodeAction = SCNAction.scale(to: 5, duration: 0.40)
        let implodeActionStep = SCNAction.scale(to: 2.5, duration: 1)
        let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
        
        DispatchQueue.main.async {
            self.view.prepare([explosionNode]) { success in
                self.scene.rootNode.addChildNode(explosionNode)
                explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    explosionNode.removeFromParentNode()
                }
            }
        }
    }
    func setupPhysics() {
        self.scene.physicsWorld.contactDelegate = self
    }
}
