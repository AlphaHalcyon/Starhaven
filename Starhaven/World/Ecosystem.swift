//
//  Ecosystem.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//

import Foundation
import SwiftUI
import SceneKit

@MainActor class Ecosystem: ObservableObject  {
    @Published var spacegroundViewModel: SpacegroundViewModel
    @Published var centralNode: SCNNode = SCNNode()
    @Published var peripheralBlackHoles: [BlackHole] = []
    @Published var debris: [SCNNode] = []
    @Published var id: UUID = UUID()
    @Published var offset: CGFloat
    init(spacegroundViewModel: SpacegroundViewModel, offset: CGFloat) {
        self.offset = offset
        self.spacegroundViewModel = spacegroundViewModel
        self.createEcosystem()
    }
    // LAYOUT central BH and array its satellites and debris fields at random but reasonably
    private var centralBlackHoleRadius = CGFloat.random(in: 750...1250)
    private var centralBlackHoleRingCount = Int.random(in: 16...24)
    @MainActor func createEcosystem() {
        self.createPeripheralBlackHoles(num: 5)
        let wraithSystem = self.addFactionSystem(faction: .Wraith)
        let phantomSystem = self.addFactionSystem(faction: .Phantom)
        DispatchQueue.main.async {
            self.spacegroundViewModel.scene.rootNode.addChildNode(wraithSystem)
            self.spacegroundViewModel.scene.rootNode.addChildNode(phantomSystem)
        }
    }
    @MainActor func createPeripheralBlackHoles(num: Int) {
        var blackHoles: [SCNNode] = []
        let minDistance: CGFloat = 15_000 // Set the minimum distance between black holes
        var attempts = 0
        for _ in 0..<num {
            while attempts < 100 { // Limit the number of attempts to prevent an infinite loop
                attempts += 1
                let radius = CGFloat.random(in: 200...3_000)
                let ringCount = Int.random(in: 5...16)
                let blackHole = BlackHole(scene: self.spacegroundViewModel.scene, view: self.spacegroundViewModel.view, radius: radius, camera: self.spacegroundViewModel.cameraNode, ringCount: ringCount, vibeOffset: Int.random(in: 1...2), bothRings: false, vibe: ShaderVibe.discOh, period: 1.5, shipNode: self.spacegroundViewModel.ship.shipNode)
                let position: SCNVector3 = SCNVector3(CGFloat.random(in: -80_000...80_000) + self.offset, CGFloat.random(in: -40_000...40_000) + self.offset, CGFloat.random(in: 10_000...100_000) + self.offset)
                let isTooClose = blackHoles.contains { existingBlackHole in
                    let distance = existingBlackHole.position.distance(to: position)
                    return distance < minDistance
                }
                if !isTooClose {
                    blackHoles.append(blackHole.containerNode)
                    blackHole.blackHoleNode.position = position
                    self.spacegroundViewModel.view.prepare(blackHole.blackHoleNode)
                    DispatchQueue.main.async {
                        self.spacegroundViewModel.blackHoles.append(blackHole)
                        self.spacegroundViewModel.scene.rootNode.addChildNode(blackHole.blackHoleNode)
                    }
                    break
                }
            }
            attempts = 0
        }
    }
    
    // GHOST CREATION
    func addFactionSystem(faction: Faction) -> SCNNode {
        let factionSystem = FactionSystem(spacegroundViewModel: self.spacegroundViewModel, faction: faction)
        factionSystem.centralNode.position = faction == .Wraith ? SCNVector3(x: -5000, y: 0, z: 0) : SCNVector3(x: 5000, y: 0, z: 1000)
        return factionSystem.centralNode
    }
}
