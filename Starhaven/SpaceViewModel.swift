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
        scene.background.contents = [
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7")
            
        ]
        self.blackHoles.append(self.addBlackHole(radius: 30, ringCount: 30, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
        //self.blackHoles.append(self.addBlackHole(radius: 2, ringCount: 15, vibeOffset: 2, bothRings: true, vibe: ShaderVibe.discOh))
        //self.blackHoles.append(self.addBlackHole(radius: 10, ringCount: 25, vibeOffset: 2, bothRings: true, vibe: ShaderVibe.discOh))
        //self.blackHoles.append(self.addBlackHole(radius: 10, ringCount: 25, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
        //self.blackHoles.append(self.addBlackHole(radius: 5, ringCount: 35, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
        self.addPilot()
    }
    
    func addPilot() {
        scene.rootNode.addChildNode(pilot.pilotNode)
        pilot.pilotNode.position = SCNVector3(x: 0, y:2, z: 200)
        pilot.pilotNode.physicsBody?.velocity = SCNVector3(x: 0, y: 0, z: -1)
    }
    
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, radius: radius, camera: pilot.cameraNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe)
        self.scene.rootNode.addChildNode(blackHole.blackHoleNode)
        blackHole.blackHoleNode.worldPosition = SCNVector3(x: Float.random(in: -500...500), y:Float.random(in: -500...500), z: Float.random(in: -100...100))
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.castsShadow = true
        lightNode.light!.type = .omni
        lightNode.light!.intensity = 12000
        blackHole.blackHoleNode.addChildNode(lightNode)
        return blackHole
    }
    
    // Add other space-related methods here
}
