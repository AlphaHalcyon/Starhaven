//
//  Ship.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit

class Ship: ObservableObject {
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
    @Published var leftEmitterNode = SCNNode()
    @Published var rightEmitterNode = SCNNode()
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    func createEmitterNode() {
        self.rearEmitterNode.position = SCNVector3(0, 2.5, 7.5)
        self.rearEmitterNode.addParticleSystem(self.waterParticleSystem)
        self.rearEmitterNode.addParticleSystem(self.fireParticleSystem)
        self.shipNode.addChildNode(self.rearEmitterNode)
    }
    func createWaterParticles() {
        let geoMap = shipNode.geometry
        // Create the particle system programmatically
        self.fireParticleSystem.particleColor = UIColor.cyan
        self.fireParticleSystem.birthRate = CGFloat(5 * throttle * 2)
        self.fireParticleSystem.particleSize = 0.02
        self.fireParticleSystem.particleIntensity = 0.8
        self.fireParticleSystem.particleLifeSpan = 2.5
        self.fireParticleSystem.spreadingAngle = 180
        self.fireParticleSystem.particleAngularVelocity = 50
        self.fireParticleSystem.particleAngularVelocity = 50
        self.fireParticleSystem.emitterShape = geoMap
        self.fireParticleSystem.stretchFactor = CGFloat(0.05 * throttle)
        // Make the particle system surface-based
        self.fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
    }
    func createFireParticles() {
        let geoMap = shipNode.geometry
        // Create the particle system programmatically
        self.waterParticleSystem.particleColor = UIColor.white
        self.waterParticleSystem.birthRate = CGFloat(5 * (throttle))
        self.waterParticleSystem.particleSize = 0.02
        self.waterParticleSystem.particleIntensity = 0.8
        self.waterParticleSystem.particleLifeSpan = 2.5
        self.waterParticleSystem.spreadingAngle = 180
        self.waterParticleSystem.particleAngularVelocity = 50
        self.waterParticleSystem.emitterShape = geoMap
        self.waterParticleSystem.stretchFactor = CGFloat(0.05 * throttle)
        // Make the particle system surface-based
        self.waterParticleSystem.emissionDurationVariation = self.waterParticleSystem.emissionDuration
        self.shipNode.addParticleSystem(self.waterParticleSystem)
    }
}
