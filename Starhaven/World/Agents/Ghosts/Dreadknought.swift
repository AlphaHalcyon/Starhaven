//
//  HalcyonDreadknought.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//

import Foundation
import SwiftUI
import SceneKit
import GLKit
import simd
import SceneKit.ModelIO
class Dreadknought: ObservableObject {
    @Published var spacegroundViewModel: SpacegroundViewModel
    @Published var shipNode: SCNNode = SCNNode()
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var containerNode: SCNNode = SCNNode()
    @Published var currentTime: TimeInterval = 0.0
    @Published var timer: Timer = Timer()
    @Published var faction: Faction
    @Published var scale: CGFloat = 0
    
    // INIT
    init(spacegroundViewModel: SpacegroundViewModel, faction: Faction = .Wraith) {
        self.spacegroundViewModel = spacegroundViewModel
        self.faction = faction
    }
    func createShip(scale: CGFloat = 0.1) -> SCNNode {
        // Load the spaceship model
        // Usage:
        if let modelNode = loadOBJModel(named: "HeavyBattleship") {
            modelNode.scale = SCNVector3(scale, scale, scale)
            return modelNode
        }
        else {
            print("failed")
            return SCNNode()
        }
    }
    func loadOBJModel(named name: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else { return nil }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return nil }
        let node = SCNNode(mdlObject: object)
        return self.applyHullMaterials(to: node)
    }
    func applyHullMaterials(to node: SCNNode) -> SCNNode {
        // Create a material for the hull
        let hullMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = UIColor.darkGray
        hullMaterial.lightingModel = .physicallyBased
        hullMaterial.metalness.contents = 1.0
        hullMaterial.roughness.contents = 0.2
        
        // Create a material for the handprint
        //let handprintMaterial = SCNMaterial()
        //handprintMaterial.diffuse.contents = UIImage(named: "handprint.png")
        
        // Create a material for the white lines
        let linesMaterial = SCNMaterial()
        linesMaterial.diffuse.contents = UIColor.white
        
        // Apply the materials to the geometry of the node
        node.geometry?.materials = [hullMaterial, linesMaterial]
        return node
    }
}
