//
//  Ghosts.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//

import Foundation
import SwiftUI
import SceneKit

class FactionSystem: ObservableObject {
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
            let dreadknought = halcyon.createShip(scale: 2.5)
            let offsetX: Float = 20 * Float(self.droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
            dreadknought.position = SCNVector3(x: offsetX, y: 0, z: 0)
            self.spacegroundViewModel.view.prepare([dreadknought]) { success in
                self.centralNode.addChildNode(dreadknought)
            }
        }
    }
    private let droneLimit = 30
    func createDrones() {
        for droneNum in 0...self.droneLimit {
            let raider: Raider = Raider(spacegroundViewModel: self.spacegroundViewModel, faction: self.faction)
            let offsetX: Float = Float(10 * droneLimit) * self.scale * (self.faction == .Phantom ? -1 : 1)
            let offsetZ: Float = 25 * Float(droneNum) * self.scale * (self.faction == .Phantom ? -1 : 1)
            let raiderNode = raider.createShip(scale: CGFloat.random(in: 3...4))
            self.spacegroundViewModel.view.prepare([raiderNode]) { sucess in
                raiderNode.position = SCNVector3(x: offsetX, y: Float.random(in:-2...2 * Float(self.droneLimit) * self.scale), z: offsetZ)
                DispatchQueue.main.async {
                    self.spacegroundViewModel.scene.rootNode.addChildNode(raiderNode)
                    self.spacegroundViewModel.ghosts.append(raider)
                }
            }
        }
    }
}
