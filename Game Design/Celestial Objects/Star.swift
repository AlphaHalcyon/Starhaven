//
//  Star.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

class Star: SceneObject {
    var node: SCNNode
    var faction: Faction = .Celestial
    var sceneManager: SceneManager
    var isAI: Bool = false
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        self.node = node
    }
    init(radius: CGFloat, color: UIColor, sceneManager: SceneManager) {
        self.isAI = false
        self.sceneManager = sceneManager
        let geo = SCNSphere(radius: radius)
        
        let material = SCNMaterial()
        // Update the material's properties
        material.emission.contents = UIColor.orange
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor.orange
        material.isDoubleSided = false
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        geo.materials = [material]
        self.node = SCNNode(geometry: geo)
        
        let lightNode = SCNNode()
        let light = SCNLight()
        light.intensity = 2_000
        light.type = .omni
        light.color = UIColor.orange
        light.categoryBitMask = 1

        lightNode.light = light
        let lightNode2 = SCNNode()
        let light2 = SCNLight()
        light2.intensity = 2_000
        light2.type = .omni
        light2.color = UIColor.white
        light2.categoryBitMask = 1

        lightNode2.light = light2
        lightNode.position = SCNVector3(10,10,10)
        lightNode2.position = SCNVector3(-10,10,10)
        self.node.categoryBitMask = 1

        self.node.addChildNode(lightNode)
        self.node.addChildNode(lightNode2)
        
    }
    public func update() {
    }
    func destroy() {
    }
}
