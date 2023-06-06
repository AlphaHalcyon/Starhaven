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
        fireParticleSystem.birthRate = 10_000
        fireParticleSystem.particleSize = 5
        fireParticleSystem.particleIntensity = 1
        fireParticleSystem.particleLifeSpan = 0.5
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 50
        fireParticleSystem.emitterShape = coronaGeo
        // Make the particle system surface-based
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg", in: Bundle.main, compatibleWith: nil)
        self.starNode.geometry?.firstMaterial = material
        
        // Add the particle system to the star node
        self.starNode.addParticleSystem(fireParticleSystem)
    }
}
