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
            DispatchQueue.main.async {
                self.centralNode.addChildNode(halcyon.createShip(scale: 1))
            }
        }
    }
    private let droneLimit = 10
    func createDrones() {
        for droneNum in 0...self.droneLimit {
            let raider: Raider = Raider(spacegroundViewModel: self.spacegroundViewModel, faction: self.faction)
            let offsetX: Float = 10 * Float(self.droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
            let offsetZ: Float = 10 * Float(droneNum) * self.scale * (self.faction == .Phantom ? -1 : 1)
            let raiderNode = raider.createShip(scale: CGFloat.random(in: 15...65))
            self.spacegroundViewModel.view.prepare(raiderNode)
            DispatchQueue.main.async {
                raiderNode.position = SCNVector3(x: offsetX, y: Float.random(in:0...11 * Float(self.droneLimit/5) * self.scale), z: offsetZ)
                self.spacegroundViewModel.scene.rootNode.addChildNode(raiderNode)
                self.spacegroundViewModel.ghosts.append(raider)
            }
        }
    }
}
