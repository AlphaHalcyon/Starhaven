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
    var faction: Faction = .Celestial
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
        
        let startLatitude: Double = 50
        let endLatitude: Double = 160
        let latitudes: [Double] = Array(stride(from: startLatitude, through: endLatitude, by: 5))
        let longitudes: [Double] = Array(repeating: 0.0, count: latitudes.count)
        let lights: [Bool] = latitudes.map { $0 >= 60 && $0 <= 80 }

        self.addMoonbase(latitudes: latitudes, longitudes: longitudes, lights: lights)
    }
    // Inside Planet class
    func addMoonbase(latitudes: [Double], longitudes: [Double], lights: [Bool]) {
        for i in 0..<latitudes.count {
            let moonbase = Moonbase(sceneManager: self.sceneManager, planet: self, hasLight: lights[i])
            moonbase.node.scale = SCNVector3(25,25,25)
            let base: SCNNode = moonbase.node
            self.addObject(object: base, atLatitude: latitudes[i], longitude: longitudes[i])
        }
    }

    func addObject(object: SCNNode, atLatitude latitude: Double, longitude: Double) {
        let latitudeInRadians = latitude * .pi / 180
        let longitudeInRadians = longitude * .pi / 180

        let radius = self.sphere.radius
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
        node.simdOrientation = simd_quatf(angle: .pi/2, axis: simd_float3(x: 0, y: 1, z: 0))
        self.sceneManager.view.prepare([self.node]) { success in
            scene.rootNode.addChildNode(self.node)
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
