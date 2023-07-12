//
//  GameManager.swift
//  Starhaven
//
//  Created by JxR on 6/9/23.
//

import Foundation
import SceneKit
import SwiftUI
import SwiftUI
import ARKit

class GameManager: ObservableObject {
    @Published var sceneManager: SceneManager
    let cameraManager: CameraManager
    let shipManager: ShipManager
    let audioManager: AudioManager = AudioManager()
    @Published var points: Int = 0
    @Published var kills: Int = 0
    @Published var fireCooldown: Bool = false
    @Published var showKillIncrement: Bool = false
    @Published var showScoreIncrement: Bool = false
    @Published var gear: Int = 1
    @Published var viewLoaded: Bool = false
    @Published var userSelectedContinue: Bool = false
    init() {
        // Initialize the SCNScene
        let scene = SCNScene()
        self.audioManager.playMusic(resourceName: "HVN2")
        // Initialize the managers
        self.shipManager = ShipManager()
        self.cameraManager = CameraManager(trackingState: CameraTrackState.player(ship: self.shipManager.ship), scene: scene)
        self.sceneManager = SceneManager(cameraManager: cameraManager, shipManager: shipManager, scene: scene)
        self.sceneManager.gameManager = self
    }
    
    func handleDragChange(value: DragGesture.Value) {
        self.shipManager.dragChanged(value: value)
    }
    
    func handleDragEnd() {
        self.shipManager.dragEnded()
    }
    
    func handleThrottle(value: Float) {
        self.shipManager.throttle(value: value)
    }
    func handleFireMissile() {
        // Fire a missile at the current target
        self.fireMissile(target: self.shipManager.hitTest(), particleSystemColor: UIColor.systemPink)
    }
    // Weapons
    func fireMissile(target: SCNNode? = nil, particleSystemColor: UIColor) {
        print(self.sceneManager.missiles.count)
        let missile: OSNRMissile
        if self.sceneManager.missiles.isEmpty {
            missile = OSNRMissile(target: target, particleSystemColor: particleSystemColor, sceneManager: self.sceneManager)
            self.fire(missile: missile.missileNode, target: target)
        }
        else {
            if let missile = self.sceneManager.missiles.popLast() {
                missile.target = target
                missile.particleSystem.particleColor = particleSystemColor
                self.fire(missile: missile.missileNode, target: target)
                missile.fire()
            }
        }
    }
    func fire(missile: SCNNode, target: SCNNode? = nil) {
        DispatchQueue.main.async {
            missile.position = self.shipManager.ship.position - SCNVector3(0, -10, 10)
            missile.physicsBody?.velocity = SCNVector3(0,0,0)
            missile.simdOrientation = self.shipManager.ship.simdOrientation
            let direction = self.shipManager.ship.presentation.worldFront
            let missileMass = missile.physicsBody?.mass ?? 1
            missile.eulerAngles.x += Float.pi / 2
            let missileForce = 600 * missileMass
            self.sceneManager.addNode(missile)
            missile.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
            //self.sceneManager.cameraManager.trackingState = CameraTrackState.missile(missile: missile)
        }
    }
    // Points
    func addPoints(points: Int) {
        self.points += points
    }
}
