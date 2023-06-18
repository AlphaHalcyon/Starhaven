//
//  ModelManager.swift
//  Starhaven
//
//  Created by JxR on 6/16/23.
//

import Foundation
import SceneKit

class ModelManager {
    static func createShip(scale: CGFloat = 0.1) -> SCNNode {
        // Load the spaceship model
        if let modelNode = loadOBJModel(named: "Raider")?.flattenedClone() {
            modelNode.scale = SCNVector3(scale, scale, scale)
            modelNode.position = SCNVector3(0, -15, -15)
            modelNode.eulerAngles.x = -.pi/12
            modelNode.geometry?.firstMaterial?.lightingModel = .physicallyBased
            return modelNode
        }
        else {
            print("failed")
            return SCNNode()
        }
    }
    static func loadOBJModel(named name: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else { return nil }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return nil }
        let node = SCNNode(mdlObject: object)
        return self.applyHullMaterials(to: node)
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
        
        // Apply the materials to the geometry of the node
        node.geometry?.materials = [hullMaterial, linesMaterial]
        return node
    }
}
