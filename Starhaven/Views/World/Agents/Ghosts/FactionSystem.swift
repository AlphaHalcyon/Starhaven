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
            let dreadknought = halcyon.createShip(scale: 3)
            let offsetX: Float = 30 * Float(self.droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
            dreadknought.position = SCNVector3(x: offsetX - 15_000, y: 0, z: 200)
            self.spacegroundViewModel.view.prepare([dreadknought]) { success in
                self.spacegroundViewModel.scene.rootNode.addChildNode(dreadknought)
            }
        }
    }
    private let droneLimit = 15
    func createDrones() {
        for droneNum in 0...self.droneLimit {
            let raider: Raider = Raider(spacegroundViewModel: self.spacegroundViewModel, faction: self.faction)
            let offsetX: Float = Float(10 * droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
            let offsetZ: Float = 32 * Float(droneNum) * self.scale
            let raiderNode = raider.createShip(scale: CGFloat.random(in: 4...5))
            self.spacegroundViewModel.view.prepare([raiderNode]) { sucess in
                raiderNode.position = SCNVector3(x: offsetX + Float.random(in:-200...200), y: Float.random(in:-2000...2000), z: offsetZ)
                DispatchQueue.main.async {
                    self.spacegroundViewModel.scene.rootNode.addChildNode(raiderNode)
                    self.spacegroundViewModel.ghosts.append(raider)
                }
            }
        }
    }
}
