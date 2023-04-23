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
    @EnvironmentObject var spaceViewModel: SpacecraftViewModel
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        let scnView = self.spaceViewModel.makeSpaceView()
        context.coordinator.setupPhysics()
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // ...
    }

    class Coordinator: NSObject, SCNPhysicsContactDelegate {
        var view: Space

        init(_ view: Space) {
            self.view = view
        }

        @MainActor func setupPhysics() {
            view.spaceViewModel.scene.physicsWorld.contactDelegate = self
        }
        @MainActor func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
            let contactMask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
            print(contactMask)
            switch contactMask {
            case CollisionCategory.laser | CollisionCategory.enemyShip:
                handleLaserEnemyCollision(contact: contact)
            case CollisionCategory.missile | CollisionCategory.enemyShip:
                handleMissileEnemyCollision(contact: contact)
            default:
                return
            }
        }

        @MainActor func handleLaserEnemyCollision(contact: SCNPhysicsContact) {
            // Determine which node is the laser and which is the enemy ship
            let laserNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.laser ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB

            // Remove the laser and enemy ship from the scene
            laserNode.removeFromParentNode()
            enemyNode.removeFromParentNode()
            print("laser collision!")
            // Add logic for updating the score or other game state variables
            // For example, you could call a function in the SpacecraftViewModel to increase the score:
            // DispatchQueue.main.async {
            //     self.view.spaceViewModel.incrementScore(points: 100)
            // }
        }

        @MainActor func handleMissileEnemyCollision(contact: SCNPhysicsContact) {
            // Determine which node is the missile and which is the enemy ship
            let missileNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.missile ? contact.nodeA : contact.nodeB
            let enemyNode = contact.nodeA.physicsBody!.categoryBitMask == CollisionCategory.enemyShip ? contact.nodeA : contact.nodeB

            // Remove the missile and enemy ship from the scene
            missileNode.removeFromParentNode()
            enemyNode.removeFromParentNode()

            // Add logic for updating the score or other game state variables
            // For example, you could call a function in the SpacecraftViewModel to increase the score:
            // DispatchQueue.main.async {
            //     self.view.spaceViewModel.incrementScore(points: 200)
            // }
        }
    }
}

