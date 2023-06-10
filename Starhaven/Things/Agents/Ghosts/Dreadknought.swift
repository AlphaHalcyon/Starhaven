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
    var spacegroundViewModel: SpacegroundViewModel
    var shipNode: SCNNode = SCNNode()
    var rearEmitterNode = SCNNode()
    var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    var containerNode: SCNNode = SCNNode()
    var currentTime: TimeInterval = 0.0
    var timer: Timer = Timer()
    var faction: Faction
    var scale: CGFloat = 0
    var reactorCoreNode: SCNNode = SCNNode()
    // INIT
    init(spacegroundViewModel: SpacegroundViewModel, faction: Faction = .Wraith) {
        self.spacegroundViewModel = spacegroundViewModel
        self.faction = faction
    }
    func createReactorCore(parentNode: SCNNode) {
        // Create reactor core geometry and material
        let coreGeometry = SCNSphere(radius: 100.0) // Modify radius as needed
        let coreMaterial = SCNMaterial()
        coreMaterial.diffuse.contents = UIColor.red
        coreGeometry.materials = [coreMaterial]

        // Create reactor core node
        self.reactorCoreNode = SCNNode(geometry: coreGeometry)
        self.reactorCoreNode.name = "ReactorCore"

        // Position core at the center of the ship
        self.reactorCoreNode.position = SCNVector3(0, 0, 0) // Adjust position as needed

        // Create physics body for collision detection
        let physicsShape = SCNPhysicsShape(geometry: coreGeometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        physicsBody.categoryBitMask = 1 << 1 // Define category for collision detection
        self.reactorCoreNode.physicsBody = physicsBody

        // Add reactor core node to ship node
        parentNode.addChildNode(self.reactorCoreNode)
    }
    func createShip(scale: CGFloat = 0.1) -> SCNNode {
        // Load the spaceship model
        // Usage:
        if let modelNode = loadOBJModel(named: "HeavyBattleship") {
            modelNode.scale = SCNVector3(scale, scale, scale)
            self.createReactorCore(parentNode: modelNode)
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
