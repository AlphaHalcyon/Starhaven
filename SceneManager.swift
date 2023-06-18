//
//  SceneManager.swift
//  Starhaven
//
//  Created by JxR on 6/17/23.
//

import Foundation
import SceneKit

class SceneManager: NSObject, SCNSceneRendererDelegate {
    let view: SCNView
    let scene: SCNScene
    let cameraManager: CameraManager
    var shipManager: ShipManager
    let sceneObjects: [SceneObject] = []
    init(cameraManager: CameraManager, shipManager: ShipManager) {
        self.scene = SCNScene()
        self.view = SCNView()
        self.cameraManager = cameraManager
        self.shipManager = shipManager
        super.init()
        self.setupScene()
        self.addNode(self.shipManager.ship)
        self.view.play(nil)
    }
    deinit {
        print("SceneManager is being deallocated")
    }

    func setupScene() {
        self.view.scene = self.scene
        self.view.rendersContinuously = true
        self.createSkybox()
        self.view.delegate = self
        self.view.prepare(self.scene, shouldAbortBlock: nil)
    }

    func createSkybox() {
        self.view.allowsCameraControl = false
        let light = SCNLight()
        light.type = .spot
        self.view.pointOfView?.light = light
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
    func updateCamera() {
        self.cameraManager.updateCamera(for: self.cameraManager.trackingState)
    }
    func updateShip() {
        self.shipManager.update()
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Update the game state
        self.updateShip()
        self.updateCamera()
        print("in the rendering loop")
    }
    // More methods to manage scene...
}
protocol Updateable {
    func update()
}
class SceneObject: Updateable {
    var node: SCNNode
    init(node: SCNNode) {
        self.node = node
    }
    func update() {
    }
    func destroy() {
    }
}
