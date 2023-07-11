//
//  CelestialManager.swift
//  Starhaven
//
//  Created by Jared on 7/10/23.
//

import Foundation
import SceneKit

class CelestialManager {
    let manager: SceneManager
    init(manager: SceneManager) {
        self.manager = manager
        self.createStar()
        self.createPlanet(name: "base.jpg")
        self.createBlackHoles()
        self.createWaterPlanet()
        self.createSkybox()
        if let pos = self.blackHoles.first?.position {
            self.manager.shipManager.ship.look(at: pos - SCNVector3(0,800,0))
        } else {
            self.manager.shipManager.ship.look(at: SCNVector3(0,0,0))
        }
    }
    public func createWaterPlanet() {
        let planet: WaterPlanet = WaterPlanet()
        self.manager.addNode(planet.node)
    }
    public func createStar() {
        let star = Star(radius: 5_000, color: .orange, sceneManager: self.manager)
        star.node.position = SCNVector3(0, 1_500, 150_000)
        self.manager.sceneObjects.append(star)
        self.manager.addNode(star.node)
    }
    public func createPlanet(name: String) {
        guard let image = UIImage(named: name) else {
            print("Failed to create planet from imagename \(name)")
            return
        }
        let planet = Planet(image: image, radius: 2000, view: self.manager.view, asteroidBeltImage: image, sceneManager: manager)
        planet.node.castsShadow = true
        self.manager.sceneObjects.append(planet)
        planet.addToScene(scene: self.manager.scene)
        //self.createBlackHoles(around: planet, count: 10)
        self.manager.shipManager.ship.look(at: planet.node.position)
        self.manager.shipManager.currentRotation = self.manager.shipManager.ship.simdOrientation
    }
    public func createEarth() {
        guard let image = UIImage(named: "Earth.jpg") else {
            return
        }
        let planet = Planet(image: image, radius: 10_000, view: self.manager.view, asteroidBeltImage: image, sceneManager: manager)
        planet.node.castsShadow = true
        planet.node.position = SCNVector3(-5_000, -15_000, 15000)
        self.manager.sceneObjects.append(planet)
        planet.addToScene(scene: self.manager.scene)
    }
    func createSkybox() {
        self.manager.view.allowsCameraControl = false
        self.manager.view.backgroundColor = UIColor.black
        self.manager.view.scene?.background.contents = [
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky")
        ]
        self.manager.view.scene?.background.intensity = 0.5
    }
    var blackHoles: [SCNNode] = []
    let blackHoleCount: Int = 15
    func createBlackHoles() {
        let blackHole: SCNNode = BH.blackHole(pov: self.manager.cameraManager.cameraNode)
        for _ in 0...self.blackHoleCount {
            self.createBlackHole(blackHole: blackHole)
        }
    }
    func createBlackHole(blackHole: SCNNode) {
        let node = blackHole.clone()
        self.blackHoles.append(node)
        self.manager.view.prepare([node]) { success in
            self.manager.addNode(node)
        }
    }
    func distributeBlackHoles() {
        for blackHole in blackHoles {
            let pos = self.manager.generateRandomPointInSphere(with: 15_000)
            blackHole.position = pos
        }
    }
}
