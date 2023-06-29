//
//  Planet.swift
//  Starhaven
//
//  Created by JxR on 5/9/23.
//

import Foundation
import SwiftUI
import SceneKit

class Planet: SceneObject {
    public var node: SCNNode
    public var sphere: SCNSphere = SCNSphere()
    public var view: SCNView = SCNView()
    
    required init(node: SCNNode) {
        self.node = node
    }
    
    init(image: UIImage, radius: CGFloat, view: SCNView, asteroidBeltImage: UIImage? = nil) {
        self.view = view
        self.sphere.radius = radius
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = false
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        self.sphere.materials = [material]
        self.sphere.segmentCount = 120

        self.node = SCNNode(geometry: sphere)
        
        self.addMoonbase(moonbase: Moonbase(), atLatitude: 0, longitude: 0)
    }
    // Inside Planet class
    func addMoonbase(moonbase: Moonbase, atLatitude latitude: Double, longitude: Double) {
        moonbase.node.position = SCNVector3(0, self.sphere.radius - 150, 0)
        moonbase.node.scale = SCNVector3(50,50,50)
        //moonbase.node.eulerAngles.x = -90
        node.addChildNode(moonbase.node)
    }
    func addToScene(scene: SCNScene) {
        node.position = SCNVector3(x: 0, y: -500_000, z: 0)
        node.simdOrientation = simd_quatf(angle: .pi/2, axis: simd_float3(x: 0, y: 1, z: 0))
        self.view.prepare([node]) { success in
            DispatchQueue.main.async {
                scene.rootNode.addChildNode(self.node)
            }
        }
        //node.eulerAngles.x = 90
    }
    func setPosition(x: CGFloat, y: CGFloat, z: CGFloat) {
        node.position = SCNVector3(x, y, z)
    }
    func update() {
    }
    func destroy() {
    }
}
