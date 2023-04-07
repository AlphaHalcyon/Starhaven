//
//  SpaceViewModel.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//

import Foundation
import SwiftUI
import SceneKit

@MainActor class SpaceViewModel: ObservableObject {
    @Published var scene: SCNScene = SCNScene()
    @Published var blackHoles: [BlackHole] = []
    @Published var pilot: Pilot = Pilot()
    
    func initializeSpace() {
        Task {
            scene.background.contents = [
                UIImage(named: "stars7"),
                UIImage(named: "stars7"),
                UIImage(named: "stars7"),
                UIImage(named: "stars7"),
                UIImage(named: "stars7"),
                UIImage(named: "stars7")
                
            ]
            scene.background.intensity = 0.33
            self.blackHoles.append(self.addBlackHole(radius: 20, ringCount: 26, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 50, ringCount: 25, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 40, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 3, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 5, ringCount: 2, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 60, ringCount: 30, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 5, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.addPilot()
        }
    }
    
    func addPilot() {
        scene.rootNode.addChildNode(pilot.containerNode)
        pilot.containerNode.position = SCNVector3(x: 0, y:0, z: 500)
        pilot.containerNode.addChildNode(pilot.cameraNode)
    }
    
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, radius: radius, camera: pilot.pilotNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe)
        self.scene.rootNode.addChildNode(blackHole.blackHoleNode)
        blackHole.blackHoleNode.worldPosition = SCNVector3(x: Float.random(in: -1000...1000), y:Float.random(in: -1000...1000), z: Float.random(in: -1000...1000))
        blackHole.blackHoleNode.renderingOrder = 0
        return blackHole
    }
    
    // Add other space-related methods here
}
