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
    var laserParticleSystem: SCNParticleSystem = SCNParticleSystem()
    init(target: SCNNode? = nil, color: UIColor) {
        self.target = target
        let laserGeometry = SCNCylinder(radius: 0.12, height: 1.5)
        laserGeometry.firstMaterial?.diffuse.contents = UIColor.red
        self.laserNode = SCNNode(geometry: laserGeometry)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: laserGeometry, options: nil))
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        self.laserNode.physicsBody = physicsBody      // Create laser particle system
        self.laserParticleSystem = self.createLaser(color: color)
        self.laserParticleSystem.emitterShape = laserGeometry
        // Attach laser particle system to the tail of the laser
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, 5, 0)
        emitterNode.addParticleSystem(self.laserParticleSystem)
        self.laserNode.physicsBody?.isAffectedByGravity = false
        DispatchQueue.main.async {
            self.laserNode.addChildNode(emitterNode)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
                self.laserNode.removeFromParentNode()
            })
        }
    }
    func createLaser(color: UIColor) -> SCNParticleSystem {
        let laser = SCNParticleSystem()
        laser.birthRate = 50
        laser.particleLifeSpan = 0.1
        laser.spreadingAngle = 0
        laser.particleSize = 5
        laser.particleColor = color
        return laser
    }
}
