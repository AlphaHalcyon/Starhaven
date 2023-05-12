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
        self.faction = faction
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
        let engine = SCNCylinder(radius: 50 * scale, height: 100 * scale)
        let engineNode = SCNNode(geometry: engine)
        engineNode.position = SCNVector3(x: 0, y: -200 * Float(scale), z: 0)
        hullNode.addChildNode(engineNode)

        // Create the ship's guns
        let gun = SCNBox(width: 10 * scale, height: 10 * scale, length: 50 * scale, chamferRadius: 0)
        let gunNode = SCNNode(geometry: gun)
        gunNode.position = SCNVector3(x: 100 * Float(scale), y: 0, z: 0)
        hullNode.addChildNode(gunNode)

        // Add additional weapons and components to the ship
        // You can create additional geometry for the various weapon systems and components mentioned in the description
        // such as the nuclear missiles, missile pods, point defense guns, coilgun batteries, and autocannon turrets.
        // Adjust the size, position, and orientation of each component as needed to match the ship's design.

        return node
    }
}
