//
//  IntroCutscene.swift
//  Starhaven
//
//  Created by JxR on 6/4/23.
//

import Foundation
import SwiftUI
import SceneKit

class IntroCutscene: NSObject, ObservableObject, SCNSceneRendererDelegate {
    // Step 1: Initialization
    @Published var scene: SCNScene = SCNScene()
    @Published var cameraNode: SCNNode = SCNNode()
    func setupScene() {
        // Setup camera
        let camera = SCNCamera()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 1500) // set your position
        scene.rootNode.addChildNode(cameraNode)
        // Start the intro cutscene
        startIntroCutscene()
    }
    func createSkybox(scnView: SCNView) {
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.pointOfView?.light = SCNLight()
        scnView.backgroundColor = UIColor.black
        scnView.scene?.background.contents = [
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky")
        ]
        scnView.scene?.background.intensity = 0.25
    }

    // Step 2: Camera Movement
    func startIntroCutscene() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 10.0 // Modify the duration as needed

        // Update camera position and orientation here for a smooth transition
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10) // Set to desired end position
        // ...

        SCNTransaction.commit()

        // Show introductory text
        DispatchQueue.main.async {
            self.showIntroText = true
        }

        // Launch missile after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.launchMissile()
        }
    }

    // Step 3: Text Overlays
    @Published var showIntroText = false

    // SwiftUI View
    var body: some View {
        ZStack {
            SceneView(scene: scene)
            if showIntroText {
                Text("The scene opens with a large ship cruising through space...")
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 2.0))
            }
        }.onAppear {
            self.setupScene()
        }
    }

    func launchMissile() {
        // Assuming you've loaded the larger ship like this:
        guard let largerShip = loadOBJModel(named: "HeavyBattleship") else {
            print("Failed to load missile model")
            return
        }
        // Load the missile model
        guard let missileNode = loadOBJModel(named: "dh10") else {
            print("Failed to load missile model")
            return
        }
        // Position the missile somewhere far away to start (adjust as needed)
        missileNode.position = SCNVector3(x: 1000, y: 1000, z: 1000)
        largerShip.scale = SCNVector3(0.1,0.1,0.1)
        // Add the missile to the scene
        scene.rootNode.addChildNode(largerShip)
        scene.rootNode.addChildNode(missileNode)
        // Make sure largerShip has been loaded and added to the scene
        let target = largerShip
        // Set the missile's destination to be the larger ship's position
        let destination = target.position
        
        // Create an action to move the missile to the larger ship
        let moveAction = SCNAction.move(to: destination, duration: 5.0)
        
        // Create an action to remove the missile from the scene after it reaches its destination
        let removeAction = SCNAction.removeFromParentNode()
        
        // Create an action to perform these two actions in sequence
        let sequenceAction = SCNAction.sequence([moveAction, removeAction])
        
        // Run the action on the missile
        missileNode.runAction(sequenceAction)
    }
    func loadOBJModel(named name: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else { return nil }
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at: 0) as? MDLMesh else { return nil }
        let node = SCNNode(mdlObject: object)
        return self.applyHullMaterials(to: node)
    }
    func applyHullMaterials(to node: SCNNode) -> SCNNode {
        // Create a material for the hull
        let hullMaterial = SCNMaterial()
        hullMaterial.diffuse.contents = UIColor.darkGray
        hullMaterial.lightingModel = .physicallyBased
        hullMaterial.metalness.contents = 1.0
        hullMaterial.roughness.contents = 0.2
        
        // Create a material for the handprint
        //let handprintMaterial = SCNMaterial()
        //handprintMaterial.diffuse.contents = UIImage(named: "handprint.png")
        
        // Create a material for the white lines
        let linesMaterial = SCNMaterial()
        linesMaterial.diffuse.contents = UIColor.white
        
        // Apply the materials to the geometry of the node
        node.geometry?.materials = [hullMaterial, linesMaterial]
        return node
    }
}
