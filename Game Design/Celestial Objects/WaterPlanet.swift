//
//  WaterPlanet.swift
//  Starhaven
//
//  Created by Jared on 7/10/23.
//

import Foundation
import SceneKit

class WaterPlanet {
    let node: SCNNode = SCNNode(geometry: SCNSphere(radius: 10_000))
    let pos: SCNVector3 = SCNVector3(5_000, -10_000, 40_000)
    init() {
        self.node.position = self.pos
        let blueMaterial: SCNMaterial = SCNMaterial()
        blueMaterial.diffuse.contents = UIColor.blue
        let darkBlue: SCNMaterial = SCNMaterial()
        self.node.geometry?.materials = [blueMaterial, darkBlue]
        
        let shape = SCNPhysicsShape(node: self.node, options: [.keepAsCompound: true])
        self.node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        self.node.physicsBody?.categoryBitMask = CollisionCategory.celestial
    }
}
