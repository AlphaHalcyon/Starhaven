//
//  WaterPlanet.swift
//  Starhaven
//
//  Created by Jared on 7/10/23.
//

import Foundation
import SceneKit

class WaterPlanet {
    let node: SCNNode = SCNNode(geometry: SCNSphere(radius: 15000))
    let pos: SCNVector3 = SCNVector3(40_000, -40_000, 40_000)
    class CloudLayer {
        let node: SCNNode
        
        init(planetRadius: CGFloat) {
            let sphere = SCNSphere(radius: planetRadius + 100) // Adjust this value to get the desired cloud altitude
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white // The image of the clouds
            material.transparency = 0.22 // Adjust this value to get the desired cloud transparency
            sphere.materials = [material]
            node = SCNNode(geometry: sphere)
        }
    }
    
    let cloudLayer: CloudLayer
    init() {
        self.cloudLayer = CloudLayer(planetRadius: 15000)
        self.node.addChildNode(self.cloudLayer.node)
        
        let rotateAction = SCNAction.rotate(by: 2.0 * CGFloat.pi, around: SCNVector3(0, 1, 0), duration: 10000) // Adjust these values to get the desired cloud rotation
        let repeatForever = SCNAction.repeatForever(rotateAction)
        self.cloudLayer.node.runAction(repeatForever)
        self.node.position = self.pos
        let blueMaterial: SCNMaterial = SCNMaterial()
        blueMaterial.diffuse.contents = UIColor.blue
        let darkBlue: SCNMaterial = SCNMaterial()
        self.node.geometry?.materials = [blueMaterial, darkBlue]
        
        let shape = SCNPhysicsShape(node: self.node, options: [.keepAsCompound: true])
        self.node.physicsBody?.categoryBitMask = CollisionCategory.celestial
    }
}
