//
//  PhysicsManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

// Physics Manager
class PhysicsManager: NSObject, SCNPhysicsContactDelegate {
    var scene: SCNScene
    var view: SCNView
    var level: Level
    var objectMap: [SCNNode: SceneObject] = [:]
    
    init(scene: SCNScene, view: SCNView, level: Level) {
        self.scene = scene
        self.view = view
        self.level = level
    }
    // CONTACT HANDLING
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if let contactBodyA = self.objectMap[contact.nodeA], let contactBodyB = self.objectMap[contact.nodeB] {
            self.level.collisionHandler.handleCollision(objectA: contactBodyA, objectB: contactBodyB)
        }
    }
    func destroy(object: SceneObject) {
        self.createExplosion(at: object.node.position, for: object.node)
        object.node.removeFromParentNode()
        self.objectMap.removeValue(forKey: object.node)
    }
    func createExplosion(at position: SCNVector3, for object: SCNNode) {
        let explosionNode = SCNNode()
        explosionNode.geometry = object.geometry
        explosionNode.position = position
        explosionNode.addParticleSystem(ParticleManager.explosionParticleSystem)
        
        let implodeAction = SCNAction.scale(to: 5, duration: 0.50)
        let implodeActionStep = SCNAction.scale(to: 2.5, duration: 1)
        let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep])
        
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
}
// Physics protocols
protocol CollisionHandler {
    func handleCollision(objectA: SceneObject, objectB: SceneObject)
}
