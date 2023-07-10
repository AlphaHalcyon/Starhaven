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
        let coronaGeo = SCNSphere(radius: 5)
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleColor = .orange
        fireParticleSystem.birthRate = 21_000
        fireParticleSystem.particleSize = 0.25
        fireParticleSystem.particleIntensity = 1
        fireParticleSystem.particleLifeSpan = 0.4
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 90
        fireParticleSystem.emitterShape = coronaGeo
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        return fireParticleSystem
    }()
    // Missile Explosion
    static let createMissileExplosion: SCNParticleSystem = {
        let coronaGeo = SCNSphere(radius: 75)
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleColor = .orange
        fireParticleSystem.birthRate = 50_000
        fireParticleSystem.particleSize = 1
        fireParticleSystem.particleIntensity = 1
        fireParticleSystem.particleLifeSpan = 0.30
        fireParticleSystem.emitterShape = coronaGeo
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        return fireParticleSystem
    }()
    // Missile Trails
    static func createMissileTrail(color: UIColor) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()
        particleSystem.particleColor = color
        particleSystem.particleIntensity = 1
        particleSystem.particleSize = 0.5
        particleSystem.birthRate = 35_000
        particleSystem.emissionDuration = particleSystem.emissionDurationVariation
        particleSystem.particleLifeSpan = 0.025
        particleSystem.emitterShape = ModelManager.missileGeometry.geometry
        return particleSystem
    }
    static let missileGeometry: SCNNode = {
        return SCNNode(geometry: SCNCapsule(capRadius: 0.5, height: 2.5))
    }()
    static func createShipMissileTrail(color: UIColor) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()
        particleSystem.particleColor = color
        particleSystem.particleSize = 2
        particleSystem.birthRate = 55_000
        particleSystem.emissionDuration = 1
        particleSystem.particleLifeSpan = 0.1
        particleSystem.spreadingAngle = 40
        particleSystem.emitterShape = self.missileGeometry.geometry
        return particleSystem
    }
    // Wraith Lasers
    static let laserPhantomParticleSystem: SCNParticleSystem = {
        let laser = SCNParticleSystem()
        laser.birthRate = 25_000
        laser.particleLifeSpan = 0.05
        laser.spreadingAngle = 0
        laser.particleSize = 5
        laser.blendMode = .additive
        return laser
    }()
    
    // Phantom Lasers
    static let laserWraithParticleSystem: SCNParticleSystem = {
        let laser = SCNParticleSystem()
        laser.birthRate = 25_000
        laser.particleLifeSpan = 0.05
        laser.spreadingAngle = 0
        laser.particleSize = 5
        laser.blendMode = .additive
        return laser
    }()
}
