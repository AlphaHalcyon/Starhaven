//
//  DustParticleSystem.swift
//  starHaven x JxR
//
import SceneKit
import SwiftUI
import Foundation

class DustParticleSystem {
    static func create() -> SCNNode {
        let dustNode = SCNNode()
        
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 500000
        particleSystem.emissionDuration = .greatestFiniteMagnitude
        //particleSystem.loops = true
        particleSystem.particleLifeSpan = 10
        particleSystem.particleLifeSpanVariation = 5
        particleSystem.particleSize = 2
        particleSystem.particleSizeVariation = 1
        particleSystem.particleVelocity = 1001
        particleSystem.particleVelocityVariation = 1.3
        particleSystem.emitterShape = SCNTube(innerRadius: 10, outerRadius: 15, height: 2)
        particleSystem.emittingDirection = SCNVector3(1, 1, 1)
        particleSystem.spreadingAngle = 360
        particleSystem.particleAngularVelocity = 1
        particleSystem.particleAngularVelocityVariation = 1
        particleSystem.blendMode = .alpha
        
        // Configure the particle appearance
        particleSystem.particleColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        particleSystem.particleColorVariation = SCNVector4(0, 0, 0, 0.3)
        
        dustNode.addParticleSystem(particleSystem)
        
        return dustNode
    }
}



