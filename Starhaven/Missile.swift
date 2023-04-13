//
//  Missile.swift
//  Starhaven
//
//  Created by JxR on 4/12/23.
//

import Foundation
import SceneKit
import SwiftUI

class Missile {
    var missileNode: SCNNode
    var target: SCNNode?
    var redParticleSystem: SCNParticleSystem

    init(target: SCNNode? = nil) {
        self.target = target

        // Create missile geometry and node
        let missileGeometry = SCNCylinder(radius: 1, height: 1)
        missileGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray
        missileNode = SCNNode(geometry: missileGeometry)
        // Adjust the physicsBody
                let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
                missileNode.physicsBody = physicsBody
        // Create red particle system
        redParticleSystem = SCNParticleSystem()
        redParticleSystem.particleColor = UIColor.red
        redParticleSystem.particleSize = 0.005
        redParticleSystem.birthRate = 10000
        redParticleSystem.emissionDuration = 1
        redParticleSystem.particleLifeSpan = 4
        redParticleSystem.spreadingAngle = 180
        redParticleSystem.emitterShape = missileGeometry

        // Attach red particle system to the tail of the missile
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, -0.25, 0)
        emitterNode.addParticleSystem(redParticleSystem)
        missileNode.addChildNode(emitterNode)
        self.missileNode.physicsBody?.isAffectedByGravity = false
        self.missileNode.physicsBody?.friction = 0
        self.missileNode.physicsBody?.damping = 0
    }
}
class Laser {
    var laserNode: SCNNode

    init() {
        // Create laser geometry and node
        let laserGeometry = SCNCylinder(radius: 0.02, height: 2)
        laserGeometry.firstMaterial?.diffuse.contents = UIColor.green
        laserNode = SCNNode(geometry: laserGeometry)
    }
}

