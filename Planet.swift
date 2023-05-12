//
//  Planet.swift
//  Starhaven
//
//  Created by JxR on 5/9/23.
//

import Foundation
import SwiftUI
import SceneKit

class Planet {
    private let sphere: SCNSphere
    private let node: SCNNode
    public var view: SCNView
    
    init(image: UIImage, radius: CGFloat, view: SCNView) {
        self.view = view
        self.sphere = SCNSphere(radius: radius)
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = false
        sphere.materials = [material]
        
        node = SCNNode(geometry: sphere)
    }
    
    func addToScene(scene: SCNScene) {
        node.position = SCNVector3(x: 0, y: -50_000, z: 120_000)
        node.simdOrientation = simd_quatf(angle: .pi/2, axis: simd_float3(x: 0, y: 1, z: 0))
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni // Omnidirectional light
        lightNode.light?.color = UIColor.white
        lightNode.position = SCNVector3(x: 0, y: 0, z: -100_000) // Adjust the position of the light source
        
        self.view.prepare([node]) { success in
            DispatchQueue.main.async {
                scene.rootNode.addChildNode(self.node)
                scene.rootNode.addChildNode(lightNode) // Add the light node to the scene
            }
        }
    }
    
    func setPosition(x: CGFloat, y: CGFloat, z: CGFloat) {
        node.position = SCNVector3(x, y, z)
    }
}
