//
//  Laser.swift
//  Starhaven
//
//  Created by JxR on 4/22/23.
//

import Foundation
import SwiftUI
import SceneKit

class Laser {
    var laserNode: SCNNode
    var target: SCNNode?
    var laserParticleSystem: SCNParticleSystem
    static let laserGeo: SCNGeometry = {
        let laserGeometry = SCNCylinder(radius: 0.1, height: 1)
        return laserGeometry
    }()
    static let laserNode: SCNNode = {
        let node = SCNNode(geometry: Laser.laserGeo)
        return node.flattenedClone()
    }()
    init(target: SCNNode? = nil, color: UIColor) {
        self.target = target
        self.laserParticleSystem = color == .red ? ParticleManager.laserWraithParticleSystem : ParticleManager.laserPhantomParticleSystem
        self.laserNode = Laser.laserNode
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: Laser.laserGeo, options: nil))
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        self.laserNode.physicsBody = physicsBody      // Create laser particle system
        self.laserParticleSystem.particleColor = color
        self.laserParticleSystem.emitterShape = Laser.laserGeo
        // Attach laser particle system to the tail of the laser
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, 5, 0)
        emitterNode.addParticleSystem(self.laserParticleSystem)
        self.laserNode.physicsBody?.isAffectedByGravity = false
        DispatchQueue.main.async {
            self.laserNode.addChildNode(emitterNode)
            if let target = target { self.laserNode.look(at: target.position) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                self.laserNode.removeFromParentNode()
            })
        }
    }
    func createLaser(color: UIColor) -> SCNParticleSystem {
        let laser = SCNParticleSystem()
        laser.birthRate = 15_000
        laser.particleLifeSpan = 0.05
        laser.spreadingAngle = 0
        laser.particleSize = 5
        laser.particleColor = color
        return laser
    }
}
