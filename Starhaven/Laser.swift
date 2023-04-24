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
    init(target: SCNNode? = nil) {
        self.target = target

        // Create laser geometry and node
        let laserGeometry = SCNCylinder(radius: 0.1, height: 2)
        laserGeometry.firstMaterial?.diffuse.contents = UIColor.red
        laserNode = SCNNode(geometry: laserGeometry)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: laserGeometry, options: nil))
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.laser
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        laserNode.physicsBody = physicsBody      // Create laser particle system
        laserParticleSystem = self.createLaser()
        laserParticleSystem.emitterShape = laserGeometry
        laserNode.opacity = 0.90
        // Attach laser particle system to the tail of the laser
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, 5, 0)
        emitterNode.addParticleSystem(laserParticleSystem)
        laserNode.addChildNode(emitterNode)

        self.laserNode.physicsBody?.isAffectedByGravity = false
    }
    func createLaser() -> SCNParticleSystem {
        let laser = SCNParticleSystem()
        laser.birthRate = 10000
        laser.particleLifeSpan = 0.1
        laser.emissionDuration = 0.2
        laser.spreadingAngle = 0
        laser.particleSize = 0.05
        laser.particleColor = UIColor.green
        laser.particleVelocity = 50
        laser.particleVelocityVariation = 5
        return laser
    }
}