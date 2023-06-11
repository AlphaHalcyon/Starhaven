//
//  Ghosts.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//

import Foundation
import SwiftUI
import SceneKit

@MainActor class FactionSystem: ObservableObject {
    @Published var spacegroundViewModel: SpacegroundViewModel
    @Published var faction: Faction
    @Published var centralNode: SCNNode = SCNNode()
    @Published var centralHalcyon: Dreadknought? = nil
    @Published var scale: Float = 100
    init(spacegroundViewModel: SpacegroundViewModel, faction: Faction) {
        self.spacegroundViewModel = spacegroundViewModel
        self.faction = faction
        self.createCentralHalcyon()
        self.createDrones()
    }
    func createCentralHalcyon() {
        self.centralHalcyon = Dreadknought(spacegroundViewModel: self.spacegroundViewModel)
        if let halcyon = self.centralHalcyon {
            print("ghost")
            let dreadknought = halcyon.createShip(scale: 2)
            let offsetX: Float = 30 * Float(self.droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
            dreadknought.position = SCNVector3(x: offsetX, y: 0, z: 200)
            self.spacegroundViewModel.view.prepare([dreadknought]) { success in
                self.spacegroundViewModel.scene.rootNode.addChildNode(dreadknought)
            }
        }
    }
    private let droneLimit = 15
    func createDrones() {
        // Load the model once before the loop
        if let modelNode = loadOBJModel(named: "Raider") {
            for droneNum in 0...self.droneLimit {
                let raider: Raider = Raider(spacegroundViewModel: self.spacegroundViewModel, faction: self.faction, modelNode: modelNode.flattenedClone())
                let offsetX: Float = Float(10 * droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
                let offsetZ: Float = 35 * Float(droneNum) * self.scale
                // Pass the modelNode as a parameter to the createShip function
                self.spacegroundViewModel.view.prepare([raider.shipNode]) { success in
                    raider.shipNode.position = SCNVector3(x: offsetX + Float.random(in:-200...200), y: Float.random(in:-5000...5000), z: offsetZ)
                    DispatchQueue.main.async {
                        self.spacegroundViewModel.scene.rootNode.addChildNode(raider.shipNode)
                        self.spacegroundViewModel.ghosts.append(raider)
                    }
                }
            }
        } else {
            print("bad!")
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
        hullMaterial.metalness.contents = 1
        hullMaterial.roughness.contents = 1
        
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
