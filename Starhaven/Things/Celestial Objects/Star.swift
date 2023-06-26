//
//  Star.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

class Star: SceneObject {
    required init(node: SCNNode) {
        self.node = node
        self.camera = SCNNode()
    }
    @Published var node: SCNNode
    @Published var camera: SCNNode
    init(radius: CGFloat, color: UIColor, camera: SCNNode) {
        let coronaGeo = SCNSphere(radius: radius + 150)
        self.camera = camera
        self.node = SCNNode(geometry: SCNSphere(radius: radius))
        // Create the particle system programmatically
        let fireParticleSystem = SCNParticleSystem()
        fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
        fireParticleSystem.birthRate = 10_000
        fireParticleSystem.particleSize = 1
        fireParticleSystem.particleIntensity = 0.90
        fireParticleSystem.particleLifeSpan = 0.3
        fireParticleSystem.spreadingAngle = 180
        fireParticleSystem.particleAngularVelocity = 50
        fireParticleSystem.emitterShape = coronaGeo
        // Make the particle system surface-based
        fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg", in: Bundle.main, compatibleWith: nil)
        
        // Update the material's properties
        material.emission.contents = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg", in: Bundle.main, compatibleWith: nil)
        material.lightingModel = .physicallyBased

        self.node.geometry?.firstMaterial = material
        
        // Add the particle system to the star node
        self.node.addParticleSystem(fireParticleSystem)
    }
    public func update() {
    }
    func destroy() {
    }
}
