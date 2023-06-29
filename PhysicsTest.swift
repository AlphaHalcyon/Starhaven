//
//  PhysicsTest.swift
//  Starhaven
//
//  Created by JxR on 6/16/23.
//

import Foundation
import SceneKit

class SpacegroundCollisionHandler: CollisionHandler {
    var physicsManager: PhysicsManager
    init(manager: PhysicsManager) {
        self.physicsManager = manager
    }
    func handleCollision(objectA: SceneObject, objectB: SceneObject) {
        self.destroyMissileAndEnemy(missile: objectA, enemy: objectB)
    }
    
    // Inside the CollisionHandler:

    func destroyMissileAndEnemy(missile: SceneObject, enemy: SceneObject) {
        physicsManager.destroy(object: missile)
        physicsManager.destroy(object: enemy)
    }
}
