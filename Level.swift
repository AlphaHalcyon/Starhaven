//
//  Level.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

// Level
class Level {
    var objects: [SceneObject]
    var collisionHandler: CollisionHandler
    // Collision Handler
    class DefaultCollisionHandler: CollisionHandler {
        func handleCollision(objectA: SceneObject, objectB: SceneObject) {
        }
    }
    init(objects: [SceneObject], collisionHandler: CollisionHandler) {
        self.objects = objects
        self.collisionHandler = collisionHandler
    }
}
