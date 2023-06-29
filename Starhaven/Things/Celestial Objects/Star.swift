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
    var sceneManager: SceneManager
    
    var isAI: Bool = false
    
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        self.node = node
        self.camera = SCNNode()
    }
    @Published var node: SCNNode
    @Published var camera: SCNNode
    init(radius: CGFloat, color: UIColor, camera: SCNNode, sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        let coronaGeo = SCNSphere(radius: radius + 150)
        self.camera = camera
        let image = UIImage(named: "tex/Sun.jpg", in: Bundle.main, compatibleWith: nil)
        let geo = SCNSphere(radius: radius)
        
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
        // Update the material's properties
        material.emission.contents = image
        material.lightingModel = .physicallyBased
        material.diffuse.contents = image
        material.isDoubleSided = false
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        let imageFiery = UIImage(named: "tex/b3.jpg")
        let materialFiery = SCNMaterial()
        // Update the material's properties
        materialFiery.emission.contents = imageFiery
        materialFiery.lightingModel = .physicallyBased
        materialFiery.diffuse.contents = imageFiery
        materialFiery.isDoubleSided = false
        materialFiery.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        materialFiery.diffuse.wrapS = .repeat
        materialFiery.diffuse.wrapT = .repeat
        geo.materials = [material, materialFiery]
        self.node = SCNNode(geometry: geo)
        // Add the particle system to the star node
        self.node.addParticleSystem(fireParticleSystem)
        self.node.light?.color = image
    }
    public func update() {
    }
    func destroy() {
    }
}
