//
//  SceneManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

class SceneManager: NSObject, SCNSceneRendererDelegate, ObservableObject {
    @Published var sceneObjects: [SceneObject] = []
    @Published var viewLoaded: Bool = false
    @Published var lastUpdateTime: TimeInterval = .zero
    let view: SCNView
    let scene: SCNScene
    let cameraManager: CameraManager
    let shipManager: ShipManager
    var objectsPlacedInCameraView: Bool = false
    init(cameraManager: CameraManager, shipManager: ShipManager, scene: SCNScene) {
        self.scene = scene
        self.view = SCNView()
        self.cameraManager = cameraManager
        self.shipManager = shipManager
        super.init()
        //self.shipManager.ship.position = SCNVector3(0, 1_500_000, -1_000_000)
        self.addNode(self.shipManager.ship)
        self.createStar()
        self.createPlanet(name: "base.jpg")
        self.setupScene()
        DispatchQueue.main.async {
            self.view.prepare([self.scene]) { success in
                print("prepared!")
                self.viewLoaded = true
                print(self.viewLoaded)
            }
        }
    }
    deinit {
        print("SceneManager is being deallocated")
    }
    func setupScene() {
        self.view.scene = self.scene
        self.createSkybox()
        self.view.delegate = self
    }
    func updateObjectPositions() {
        let playerPosition = self.shipManager.ship.position

        // Update positions of all scene objects relative to the player.
        for object in self.sceneObjects {
            object.node.position = object.node.position - playerPosition
        }
        // Don't forget to set the player's position back to the origin.
        self.shipManager.ship.position = SCNVector3Zero
    }
    
    public func createStar() {
        let star = Star(radius: 1_500_000, color: .orange, camera: self.cameraManager.cameraNode)
        star.node.position = SCNVector3(1000, 100_000, 6_000_000)
        
        let lightNode = SCNNode()
        let light = SCNLight()
        light.intensity = 4_000
        light.type = .omni
        lightNode.light = light
        self.sceneObjects.append(star)
        self.view.prepare([star.node, lightNode]) { success in
            DispatchQueue.main.async {
                star.node.addChildNode(lightNode)
                self.scene.rootNode.addChildNode(star.node)
            }
        }
    }

    public func createPlanet(name: String) {
        let planet = Planet(image: UIImage(imageLiteralResourceName: name), radius: 750_000, view: self.view)
        planet.node.castsShadow = true
        //let moon = ModelManager.createMoon(scale: 1000)
        self.view.prepare([planet.node]) { success in
            DispatchQueue.main.async {
                planet.addToScene(scene: self.scene)
                self.scene.rootNode.addChildNode(planet.node)
            }
        }
    }
    func createSkybox() {
        self.view.allowsCameraControl = false
        self.view.backgroundColor = UIColor.black
        self.view.scene?.background.contents = [
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky")
        ]
        self.view.scene?.background.intensity = 0.98
    }
    func addNode(_ node: SCNNode) {
        self.scene.rootNode.addChildNode(node)
    }
    func removeNode(_ node: SCNNode) {
        node.removeFromParentNode()
    }
    func updateCamera(deltaTime: Float) {
        self.cameraManager.updateCamera(for: CameraTrackState.player(ship: self.shipManager.ship), deltaTime: deltaTime)
    }
    func updateShip(deltaTime: TimeInterval) {
        self.shipManager.update(deltaTime: deltaTime)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update the game state
        let deltaTime = time - lastUpdateTime
        self.updateObjectPositions()
        self.lastUpdateTime = time
        self.updateShip(deltaTime: time)
        self.updateCamera(deltaTime: Float(deltaTime))
    }
    // More methods to manage scene
}
protocol Updateable {
    func update()
}
protocol SceneObject: Updateable {
    var node: SCNNode { get set }
    init(node: SCNNode)
    func update()
    func destroy()
}
