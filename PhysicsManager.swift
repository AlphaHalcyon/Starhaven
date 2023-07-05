//
//  PhysicsManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

// Physics Manager
class PhysicsManager: NSObject, ObservableObject, SCNPhysicsContactDelegate {
    let sceneManager: SceneManager
    init(sceneManager: SceneManager) {
        self.sceneManager = sceneManager
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
        self.sceneManager.createExplosion(at: enemyNode.position)
        enemyNode.removeFromParentNode()
        print(self.sceneManager.sceneObjects.count)
        self.sceneManager.sceneObjects = self.sceneManager.sceneObjects.filter { $0.node != enemyNode }
        print(self.sceneManager.sceneObjects.count)
    }
    func handleLaserEnemyCollision(contact: SCNPhysicsContact) {
        if let contactBody = contact.nodeA.physicsBody {
            let laserNode = contactBody.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
            let enemyNode = contactBody.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            if let sceneObject = self.sceneManager.sceneObjects.first(where: { $0.node == enemyNode }), let ai = sceneObject as? AI, let color = laserNode.particleSystems?.first?.particleColor {
                //Assuming color is a property of SceneObject
                if ai.faction == .OSNR && color == UIColor.cyan {
                    if Float.random(in: 0...1) > 0.1 {
                        print("AI death")
                        self.death(node: laserNode, enemyNode: enemyNode)
                    }
                    else {
                        //ai.isEvading = true
                    }
                } else if ai.faction == .Wraith && color != UIColor.cyan {
                    if Float.random(in: 0...1) > 0.1 {
                        print("AI death")
                        self.death(node: laserNode, enemyNode: enemyNode)
                    }
                    else {
                        //ai.isEvading = true
                    }
                }
            }
        }
    }
    func handleMissileEnemyCollision(contact: SCNPhysicsContact) {
        // Determine which node is the missile and which is the enemy ship
        let missileNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.missile ? contact.nodeA : contact.nodeB
        let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
        
        self.missileContact(missileNode: missileNode, enemyNode: enemyNode)
    }
    func missileContact(missileNode: SCNNode, enemyNode: SCNNode) {
        // Find the corresponding missile object and call the handleCollision function
        if let missile = self.sceneManager.sceneObjects.first(where: { $0.node == missileNode }) {
            if missile.faction != .OSNR {
                return
            }
            // self.playSound(name: "snatchHiss")
            // missile.detonate()
            self.sceneManager.createExplosion(at: missile.node.position)
        }
        // Remove the missile and enemy ship from the scene
        DispatchQueue.main.async {
            self.sceneManager.createExplosion(at: enemyNode.position)
            enemyNode.removeFromParentNode()
            self.sceneManager.cameraManager.trackingState = CameraTrackState.player(ship: self.sceneManager.shipManager.ship)
            // Add logic for updating the score or other game state variables
            // For example, you could call a function in the SpacegroundViewModel to increase the score:
            // self.incrementScore(killsOrBlackHoles: 2)
            self.sceneManager.sceneObjects = self.sceneManager.sceneObjects.filter { $0.node != enemyNode }
        }
    }
}
// Physics protocols
protocol CollisionHandler {
    func handleCollision(objectA: SceneObject, objectB: SceneObject)
}
