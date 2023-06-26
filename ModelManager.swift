//
//  ModelManager.swift
//  Starhaven
//
//  Created by JxR on 6/16/23.
//

import Foundation
import SceneKit

class ModelManager {
    static func createShip(scale: CGFloat = 0.01) -> SCNNode {
        // Load the spaceship model
        if let modelNode = loadOBJModel(named: "Raider") {
            modelNode.scale = SCNVector3(scale, scale, scale)
            modelNode.position = SCNVector3(0, -2.5, 0)
            let containerNode = SCNNode()
            containerNode.addChildNode(modelNode)
            return containerNode
        }
        else {
            print("failed")
            return SCNNode()
        }
    }
    static func createMoon(scale: CGFloat = 10000) -> SCNNode {
        // Load the moon model
        if let modelNode = loadOBJModel(named: "Luna", materials: false) {
            modelNode.scale = SCNVector3(scale, scale, scale)
            modelNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
            modelNode.position = SCNVector3(0, 0, 0)
            let containerNode = SCNNode()
            containerNode.addChildNode(modelNode)
            return containerNode
        }
        else {
            print("failed")
            return SCNNode()
        }
    }

    static func loadOBJModel(named name: String, materials: Bool = true) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else { return nil }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return nil }
        let node = SCNNode(mdlObject: object)
        return materials ? self.applyHullMaterials(to: node) : node
    }
    static func applyHullMaterials(to node: SCNNode) -> SCNNode {
        // Create a material for the hull
        let hullMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = UIColor.darkGray
        hullMaterial.metalness.contents = 0.5
        hullMaterial.roughness.contents = 1
        
        // Create a material for the white lines
        let linesMaterial = SCNMaterial()
        linesMaterial.diffuse.contents = UIColor.cyan
        
        // Create a material for the hull
        let tertiaryMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = UIColor.darkGray
        hullMaterial.metalness.contents = 0.5
        hullMaterial.roughness.contents = 1
        // Apply the materials to the geometry of the node
        node.geometry?.materials = [hullMaterial, linesMaterial, tertiaryMaterial]
        return node
    }
}
