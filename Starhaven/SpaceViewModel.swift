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
            scene.background.intensity = 0.5
            self.blackHoles.append(self.addBlackHole(radius: 4, ringCount: 15, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 5, ringCount: 25, vibeOffset: 1, bothRings: false, vibe: ShaderVibe.discOh))
            self.addPilot()
        }
    }
    
    func addPilot() {
        scene.rootNode.addChildNode(pilot.containerNode)
        pilot.containerNode.position = SCNVector3(x: 0, y:0, z: 300)
    }
    
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, radius: radius, camera: pilot.cameraNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe)
        self.scene.rootNode.addChildNode(blackHole.blackHoleNode)
        blackHole.blackHoleNode.worldPosition = SCNVector3(x: Float.random(in: -500...500), y:Float.random(in: -500...500), z: Float.random(in: -500...500))
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.castsShadow = true
        lightNode.light!.type = .omni
        lightNode.light!.intensity = 10
        blackHole.blackHoleNode.addChildNode(lightNode)
        blackHole.blackHoleNode.renderingOrder = 0
        return blackHole
    }
    
    // Add other space-related methods here
}
