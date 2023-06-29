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
    var sceneManager: SceneManager
    var isAI: Bool = false
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.node = node
        self.sceneManager = sceneManager
    }
    init(image: UIImage, radius: CGFloat, view: SCNView, asteroidBeltImage: UIImage? = nil, sceneManager: SceneManager) {
        self.view = view
        self.sphere.radius = radius
        self.sceneManager = sceneManager
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.isDoubleSided = false
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        self.sphere.materials = [material]
        self.sphere.segmentCount = 120

        self.node = SCNNode(geometry: sphere)
        
        self.addMoonbase(moonbase: Moonbase(sceneManager: self.sceneManager, planet: self), atLatitude: 0, longitude: 0)
    }
    // Inside Planet class
    func addMoonbase(moonbase: Moonbase, atLatitude latitude: Double, longitude: Double) {
        moonbase.node.scale = SCNVector3(50,50,50)
        self.addObject(object: moonbase.node, atLatitude: 90, longitude: 0, offset: 0)
        let ship = ModelManager.createShip(scale: 100)
        self.addObject(object: ship, atLatitude: 85, longitude: 10, offset: 0)
        let base: SCNNode = moonbase.node.clone()
        self.addObject(object: base, atLatitude: -45, longitude: 0, offset: 0)
    }
    func addObject(object: SCNNode, atLatitude latitude: Double, longitude: Double, offset: CGFloat) {
        let latitudeInRadians = latitude * .pi / 180
        let longitudeInRadians = longitude * .pi / 180

        let radius = self.sphere.radius + offset
        let x = radius * cos(latitudeInRadians) * cos(longitudeInRadians)
        let y = radius * sin(latitudeInRadians)
        let z = radius * cos(latitudeInRadians) * sin(longitudeInRadians)

        let position = SCNVector3(x, y, z)
        object.position = position

        // Convert SCNVector3 to simd_float3
        let simdPosition = simd_float3(x: Float(x), y: Float(y), z: Float(z))

        // Compute the direction vector pointing towards the center of the planet
        let downDirection = -normalize(simdPosition)

        // Rotate the object to align its "down" direction with the direction towards the planet's center
        let rotation = simd_quatf(from: simd_float3(0, -1, 0), to: downDirection)

        object.simdOrientation = rotation

        node.addChildNode(object)
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
