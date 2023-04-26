//
//  Star.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

class Star {
    @Published var starNode: SCNNode
    @Published var camera: SCNNode
    init(radius: CGFloat, color: UIColor, camera: SCNNode) {
        let coronaGeo = SCNSphere(radius: radius + 50)
        self.camera = camera
        self.starNode = SCNNode(geometry: SCNSphere(radius: radius))
        
        // Create the particle system programmatically
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 500000
        fireParticleSystem.particleSize = 0.75
        fireParticleSystem.particleIntensity = 0.3
        fireParticleSystem.particleLifeSpan = 0.5
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 50
        fireParticleSystem.emitterShape = coronaGeo
        fireParticleSystem.stretchFactor = 0.2
        // Make the particle system surface-based
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        let material = SCNMaterial()
        material.emission.contents = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg", in: Bundle.main, compatibleWith: nil)
        material.diffuse.contents = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg", in: Bundle.main, compatibleWith: nil)
        self.starNode.geometry?.firstMaterial = material
        
        // Add the particle system to the star node
        self.starNode.addParticleSystem(fireParticleSystem)
        // Create a pulsing animation for the star node
        let pulseInAction = SCNAction.scale(to: 0.95, duration: 1.0)
        pulseInAction.timingMode = .easeInEaseOut
        let pulseOutAction = SCNAction.scale(to: 1.05, duration: 1.0)
        let finalPulse = SCNAction.scale(to: 1.5, duration: 1.0)
        let implodeAction = SCNAction.scale(to: 0.1, duration: 0.5)
        let implosionPause = SCNAction.scale(to: 0.1, duration: 0.25)
        let explosionAction = SCNAction.scale(to: 100, duration: 2.5)
        _ = SCNAction.scale(to: 100, duration: 5)
        pulseOutAction.timingMode = .easeInEaseOut
        let pulseSequence = SCNAction.sequence([pulseInAction, pulseOutAction])
        _ = SCNAction.sequence([pulseInAction, pulseOutAction, pulseInAction, pulseOutAction, pulseInAction, pulseOutAction, pulseInAction, pulseOutAction, pulseInAction, pulseOutAction, finalPulse, implodeAction, implosionPause, explosionAction])
        
        self.starNode.runAction(SCNAction.repeatForever(pulseSequence))
    }
}
