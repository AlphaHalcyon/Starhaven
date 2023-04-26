//
//  Space.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

@MainActor struct Space: UIViewRepresentable {
    @EnvironmentObject var spaceViewModel: SpacegroundViewModel
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        let scnView = self.spaceViewModel.makeSpaceView()
        context.coordinator.setupPhysics()
        return scnView
    }
    func updateUIView(_ uiView: SCNView, context: Context) { }

    class Coordinator: NSObject, SCNPhysicsContactDelegate {
        var view: Space

        init(_ view: Space) {
            self.view = view
        }
        @MainActor func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
            let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
            switch contactMask {
            case CollisionCategory.laser | CollisionCategory.enemyShip:
                handleLaserEnemyCollision(contact: contact)
            case CollisionCategory.missile | CollisionCategory.enemyShip:
                handleMissileEnemyCollision(contact: contact)
            default:
                return
            }
        }
        @MainActor func hndleLaserEnemyCollision(contact: SCNPhysicsContact) {
            let laserNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            let node = self.view.spaceViewModel.ghosts.first(where: { $0.shipNode == enemyNode })
            if Float.random(in: 0...1) > 0.99 {
                createExplosion(at: enemyNode.position)
                DispatchQueue.main.async {
                    laserNode.removeFromParentNode()
                    enemyNode.removeFromParentNode()
                    node?.timer.invalidate()
                    self.view.spaceViewModel.ghosts = self.view.spaceViewModel.ghosts.filter { $0.shipNode != enemyNode }
                    print("ghosts", self.view.spaceViewModel.ghosts)
                }
            }
        }
        @MainActor func handleLaserEnemyCollision(contact: SCNPhysicsContact) {
            let laserNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            let node = self.view.spaceViewModel.ghosts.first(where: { $0.shipNode == enemyNode })
            if let color = laserNode.childNodes.first?.particleSystems?.first?.particleColor {
                switch node?.faction {
                case .Wraith:
                    if color == .green {
                        if Float.random(in: 0...1) > 0.95 {
                            node?.timer.invalidate()
                            self.death(node: laserNode, enemyNode: enemyNode)
                        }
                    }
                case .Phantom:
                    if color == .red {
                        if Float.random(in: 0...1) > 0.95 {
                            node?.timer.invalidate()
                            self.death(node: laserNode, enemyNode: enemyNode)
                        }
                    }
                default:
                    return
                }
            }
        }
        func death(node: SCNNode, enemyNode: SCNNode) {
            DispatchQueue.main.async {
                self.createExplosion(at: enemyNode.position)
                node.removeFromParentNode()
                enemyNode.removeFromParentNode()
                self.view.spaceViewModel.ghosts = self.view.spaceViewModel.ghosts.filter { $0.shipNode != enemyNode }
                print("ghosts", self.view.spaceViewModel.ghosts)
            }
        }
        @MainActor func handleMissileEnemyCollision(contact: SCNPhysicsContact) {
            // Determine which node is the missile and which is the enemy ship
            let missileNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.missile ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB
            // Find the corresponding missile object and call the handleCollision function
            if let missile = view.spaceViewModel.missiles.first(where: { $0.getMissileNode() == missileNode }) {
                print("nice!")
                DispatchQueue.main.async { missile.detonate() }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                DispatchQueue.main.async { self.createExplosion(at: enemyNode.position) }
                enemyNode.removeFromParentNode()
            }
            // Add logic for updating the score or other game state variables
            // For example, you could call a function in the SpacegroundViewModel to increase the score:
            DispatchQueue.main.async {
                 self.view.spaceViewModel.incrementScore(killsOrBlackHoles: 2)
            }
            // Remove the missile and enemy ship from the scene
            DispatchQueue.main.async {
                let node = self.view.spaceViewModel.ghosts.first(where: { $0.shipNode == enemyNode })
                node?.timer.invalidate()
                self.view.spaceViewModel.ghosts = self.view.spaceViewModel.ghosts.filter { $0.shipNode != enemyNode }
                print("ghosts", self.view.spaceViewModel.ghosts)
            }
        }
        func createExplosion(at position: SCNVector3) {
            DispatchQueue.main.async {
                let coronaGeo = SCNSphere(radius: 50)
                
                // Create the particle system programmatically
                let fireParticleSystem = SCNParticleSystem()
                fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
                fireParticleSystem.birthRate = 100000
                fireParticleSystem.particleSize = 0.5
                fireParticleSystem.particleIntensity = 0.75
                fireParticleSystem.particleLifeSpan = 0.33
                fireParticleSystem.spreadingAngle = 180
                fireParticleSystem.particleAngularVelocity = 50
                fireParticleSystem.emitterShape = coronaGeo
                // Make the particle system surface-based
                fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
                
                // Create an SCNNode to hold the particle system
                let explosionNode = SCNNode()
                
                // Set the position of the explosion
                explosionNode.position = position
                
                // Add the explosion particle system to the node
                explosionNode.addParticleSystem(fireParticleSystem)
                
                // Add the explosion node to the scene
                self.view.spaceViewModel.scene.rootNode.addChildNode(explosionNode)
                
                // Configure and run the scale actions
                let implodeAction = SCNAction.scale(to: 5, duration: 0.20)
                let implodeActionStep = SCNAction.scale(to: 2.5, duration: 1)
                let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
                let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
                explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))

                // Remove the explosion node after some time (e.g., 2 seconds)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    explosionNode.removeFromParentNode()
                }
            }
        }
        @MainActor func setupPhysics() {
            view.spaceViewModel.scene.physicsWorld.contactDelegate = self
        }
    }
}

