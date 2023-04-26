//
//  Ecosystem.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//

import Foundation
import SwiftUI
import SceneKit

class Ecosystem: ObservableObject, Identifiable {
    @Published var spacegroundViewModel: SpacegroundViewModel
    @Published var centralNode: SCNNode = SCNNode()
    @Published var centralBlackHoles: [BlackHole] = []
    @Published var satellites: [Any] = []
    @Published var wraiths: [AssaultDrone] = []
    @Published var phantoms: [AssaultDrone] = []
    @Published var debris: [SCNNode] = []
    @Published var id: UUID = UUID()
    init(spacegroundViewModel: SpacegroundViewModel) {
        self.spacegroundViewModel = spacegroundViewModel
    }
    private var centralBlackHoleRadius = CGFloat.random(in: 750...1250)
    private var centralBlackHoleRingCount = Int.random(in: 16...24)
    // LAYOUT central BH and array its satellites and debris fields at random but reasonably
    @MainActor func createCentralBlackHole() -> BlackHole {
        let blackHole = self.createBlackHole(radius: centralBlackHoleRadius, ringCount: centralBlackHoleRingCount)
        DispatchQueue.main.async {
            self.spacegroundViewModel.blackHoles.append(blackHole)
        }
        return blackHole
    }
    @MainActor func createPeripheralBlackHoles(num: Int) -> [BlackHole] {
        var blackHoles: [BlackHole] = []
        for _ in 0...num {
            let radius = CGFloat.random(in: 100...250)
            let ringCount = Int.random(in: 8...24)
            blackHoles.append(self.createBlackHole(radius: radius, ringCount: ringCount))
        }
        return blackHoles
    }
    @MainActor func createBlackHole(radius: CGFloat, ringCount: Int) -> BlackHole {
        return BlackHole(scene: self.spacegroundViewModel.scene, view: self.spacegroundViewModel.view, radius: radius, camera: self.spacegroundViewModel.cameraNode, ringCount: ringCount, vibeOffset: Int.random(in: 1...2), bothRings: false, vibe: ShaderVibe.discOh, period: 3, shipNode: self.spacegroundViewModel.ship.shipNode)
    }
    
    // GHOST CREATION
    func createGhosts(scnView: SCNView) {
        for _ in 0...25 {
            let ghost = AssaultDrone(spacegroundViewModel: spacegroundViewModel)
            let enemyShipNode = ghost.createShip(scale: CGFloat.random(in: 20.0...80.0))
            enemyShipNode.position = SCNVector3(Int.random(in: -5000...5000), Int.random(in: 1000...5000), Int.random(in: -5000...5000))
            scnView.scene?.rootNode.addChildNode(ghost.containerNode)
        }
    }
}
