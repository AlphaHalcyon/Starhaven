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
    init(spacegroundViewModel: SpacegroundViewModel) {
        self.spacegroundViewModel = spacegroundViewModel
        self.createEcosystem()
    }
    // LAYOUT central BH and array its satellites and debris fields at random but reasonably
    private var centralBlackHoleRadius = CGFloat.random(in: 750...1250)
    private var centralBlackHoleRingCount = Int.random(in: 16...24)
    @MainActor func createEcosystem() {
        DispatchQueue.main.async {
            print("CALL")
            let holes = self.createPeripheralBlackHoles(num: 5)
            let wraithSystem = self.addFactionSystem(faction: .Wraith)
            let phantomSystem = self.addFactionSystem(faction: .Phantom)
            var objects: [SCNNode] = holes; objects.append(wraithSystem); objects.append(phantomSystem)
            self.spacegroundViewModel.view.prepare(objects) { success in
                if success {
                    print("success!")
                    for object in objects {
                        DispatchQueue.main.async {
                            self.centralNode.addChildNode(object)
                        }
                    }
                }
            }
        }
    }
    @MainActor func createPeripheralBlackHoles(num: Int) -> [SCNNode] {
        var blackHoles: [SCNNode] = []
        for _ in 0...num {
            print("bh\(num)")
            let radius = CGFloat.random(in: 100...250)
            let ringCount = Int.random(in: 8...24)
            let blackHole = BlackHole(scene: self.spacegroundViewModel.scene, view: self.spacegroundViewModel.view, radius: radius, camera: self.spacegroundViewModel.cameraNode, ringCount: ringCount, vibeOffset: Int.random(in: 1...2), bothRings: false, vibe: ShaderVibe.discOh, period: 3, shipNode: self.spacegroundViewModel.ship.shipNode)
            let position: SCNVector3 = SCNVector3(CGFloat.random(in: -10_000...10_000), CGFloat.random(in: -5_000...5_000), CGFloat.random(in: -10_000...10_000))
            blackHoles.append(blackHole.containerNode)
            blackHole.blackHoleNode.position = position
            DispatchQueue.main.async {
                self.spacegroundViewModel.blackHoles.append(blackHole)
            }
        }
        return blackHoles
    }
    
    // GHOST CREATION
    func addFactionSystem(faction: Faction) -> SCNNode {
        let factionSystem = FactionSystem(spacegroundViewModel: self.spacegroundViewModel, faction: faction)
        factionSystem.centralNode.position = faction == .Wraith ? SCNVector3(x: -5000, y: 0, z: 0) : SCNVector3(x: 5000, y: 0, z: 0)
        return factionSystem.centralNode
    }
}
