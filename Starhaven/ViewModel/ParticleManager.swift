//
//  ParticleManager.swift
//  Starhaven
//
//  Created by JxR on 6/10/23.
//

import Foundation
import SceneKit

class ParticleManager {
    // Explosions!
    static let explosionParticleSystem: SCNParticleSystem = {
        let coronaGeo = SCNSphere(radius: 200)
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 400_000
        fireParticleSystem.particleSize = 1
        fireParticleSystem.particleIntensity = 1
        fireParticleSystem.particleLifeSpan = 0.4
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 90
        fireParticleSystem.emitterShape = coronaGeo
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        return fireParticleSystem
    }()
    // Missile Explosion
    static func createMissileExplosion() -> SCNParticleSystem {
        let coronaGeo = SCNSphere(radius: 50)
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 100_000
        fireParticleSystem.particleSize = 1
        fireParticleSystem.particleIntensity = 1
        fireParticleSystem.particleLifeSpan = 0.30
        fireParticleSystem.emitterShape = coronaGeo
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        return fireParticleSystem
    }
    // Missile Trails
    static func createMissileTrail(color: UIColor) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()
        particleSystem.particleColor = color
        particleSystem.particleSize = 1
        particleSystem.birthRate = 150_000
        particleSystem.emissionDuration = 1
        particleSystem.particleLifeSpan = 0.1
        particleSystem.emissionDurationVariation = particleSystem.emissionDuration
        return particleSystem
    }
    // Wraith Lasers
    static let laserPhantomParticleSystem: SCNParticleSystem = {
        let laser = SCNParticleSystem()
        laser.birthRate = 15_000
        laser.particleLifeSpan = 0.05
        laser.spreadingAngle = 0
        laser.particleSize = 5
        return laser
    }()
    
    // Phantom Lasers
    static let laserWraithParticleSystem: SCNParticleSystem = {
        let laser = SCNParticleSystem()
        laser.birthRate = 15_000
        laser.particleLifeSpan = 0.05
        laser.spreadingAngle = 0
        laser.particleSize = 5
        return laser
    }()
}