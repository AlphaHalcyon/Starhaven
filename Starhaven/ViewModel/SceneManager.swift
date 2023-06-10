//
//  SceneManager.swift
//  Starhaven
//
//  Created by JxR on 6/9/23.
//

import Foundation
import SceneKit

class SceneManager: NSObject, SCNSceneRendererDelegate {
    let view: SCNView
    let scene: SCNScene
    let cameraNode: SCNNode

    init(view: SCNView, cameraNode: SCNNode) {
        self.view = view
        self.cameraNode = cameraNode
        self.scene = SCNScene()
        super.init()
        self.setupScene()
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
        self.view.autoenablesDefaultLighting = true
        self.view.pointOfView?.light = SCNLight()
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
        // Camera update code...
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // General scene update code...
    }
    
    // More methods to manage scene...
}
