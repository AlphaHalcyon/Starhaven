//
//  ModelManager.swift
//  Starhaven
//
//  Created by JxR on 6/16/23.
//

import Foundation
import SceneKit

class ModelManager {
    static func createShip(scale: CGFloat = 0.0001) -> SCNNode {
        // Load the spaceship model
        do {
            if let modelNode = try loadOBJModel(named: "Raider") {
                modelNode.scale = SCNVector3(scale, scale, scale)
                modelNode.position = SCNVector3(0, -0.0025, 0)
                let containerNode = SCNNode()
                containerNode.addChildNode(modelNode)
                return containerNode
            }
            else {
                print("failed")
                return SCNNode()
            }
        } catch {
            print("Failed to load ship model!")
            return SCNNode()
        }
    }
    static func createMoon(scale: CGFloat = 10000) -> SCNNode {
        // Load the moon model
        do {
            if let modelNode = try loadOBJModel(named: "Luna", materials: false) {
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
        } catch {
            print("Failed to load moon")
            return SCNNode()
        }
    }
    enum ModelLoadingError: Error {
        case modelNotFound(String)
        case failedToCastToMDLMesh
    }
    static let missileGeometry: SCNNode = {
        return SCNNode(geometry: SCNCapsule(capRadius: 0.5, height: 1))
    }()
    static func loadOBJModel(named name: String, materials: Bool = true) throws -> SCNNode? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else {
            throw ModelLoadingError.modelNotFound(name)
        }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else {
            throw ModelLoadingError.failedToCastToMDLMesh
        }
        let node = SCNNode(mdlObject: object)
        return materials ? self.applyHullMaterials(to: node) : node
    }
    static func applyHullMaterials(to node: SCNNode) -> SCNNode {
        // Create a material for the hull
        let hullMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = UIColor.darkGray
        hullMaterial.metalness.contents = 1
        hullMaterial.roughness.contents = 1
        // Apply the materials to the geometry of the node
        node.geometry?.materials = [hullMaterial]
        return node
    }
}
