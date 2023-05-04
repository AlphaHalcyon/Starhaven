//
//  HalcyonDreadknought.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
import Foundation
import SwiftUI
import SceneKit
import GLKit
import simd

class Dreadknought: ObservableObject {
    @State var spacegroundViewModel: SpacegroundViewModel
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
        // Initialize new properties
        self.faction = faction // Faction.allCases.randomElement()!
    }
    // CREATION
    func createShip(scale: CGFloat = 0.1) -> SCNNode {
        let node = SCNNode()
        self.scale = scale
        node.geometry = SCNGeometry()
        // Create the ship's hull
        let hull = SCNBox(width: 1171 * scale, height: 398 * scale, length: 352 * scale, chamferRadius: 0)
        let hullNode = SCNNode(geometry: hull)
        hullNode.position = SCNVector3(x: 0, y: 0, z: 0)
        node.addChildNode(hullNode)

        // Create the ship's engines
        let engine = SCNCylinder(radius: 50, height: 100)
        let engineNode = SCNNode(geometry: engine)
        engineNode.position = SCNVector3(x: 0, y: -200, z: 0)
        hullNode.addChildNode(engineNode)

        // Create the ship's guns
        let gun = SCNBox(width: 10, height: 10, length: 50, chamferRadius: 0)
        let gunNode = SCNNode(geometry: gun)
        gunNode.position = SCNVector3(x: 100, y: 0, z: 0)
        hullNode.addChildNode(gunNode)
        return node
    }
}
