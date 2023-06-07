//
//  Ship.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit

class Ship: ObservableObject {
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var containerNode: SCNNode = SCNNode()
    @Published var view: SCNView
    @Published var cameraNode: SCNNode
    init(view: SCNView, cameraNode: SCNNode) {
        self.view = view
        self.cameraNode = cameraNode
    }
    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil) -> Missile {
        print("fire!")
        let missile = Missile(target: target, particleSystemColor: .red, viewModel: SpacegroundViewModel(view: SCNView(), cameraNode: SCNNode()))
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -15, 5), to: containerNode.parent)
        
        missile.missileNode.position = worldPosition
        missile.missileNode.orientation = shipNode.presentation.orientation
        missile.missileNode.eulerAngles.x += Float.pi / 2
        let direction = shipNode.presentation.worldFront
        let missileMass = missile.missileNode.physicsBody?.mass ?? 1
        let missileForce = CGFloat(abs(throttle) + 1) * 2 * missileMass
        missile.missileNode.physicsBody?.velocity = self.shipNode.physicsBody!.velocity
        missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        containerNode.parent!.addChildNode(missile.missileNode)
        return missile
    }
    func fireLaser(target: SCNNode? = nil) {
        print("fire laser!")
        let laser = Laser(target: target, color: .purple)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(0, -10, -1), to: containerNode.parent)
        
        laser.laserNode.position = worldPosition
        laser.laserNode.orientation = shipNode.presentation.orientation
        laser.laserNode.eulerAngles.x += Float.pi / 2
        let direction = shipNode.presentation.worldFront
        let laserMass = laser.laserNode.physicsBody?.mass ?? 1
        let laserForce = CGFloat(abs(throttle) + 1) * 750 * laserMass
        laser.laserNode.physicsBody?.applyForce(direction * Float(laserForce), asImpulse: true)
        containerNode.parent!.addChildNode(laser.laserNode)
    }
    func createShip(scale: CGFloat = 0.1) -> SCNNode {
        // Load the spaceship model
        // Usage:
        if let modelNode = loadOBJModel(named: "Raider") {
            modelNode.scale = SCNVector3(scale, scale, scale)
            modelNode.position = SCNVector3(0, -15, 0)
            modelNode.eulerAngles.x = -.pi/12
            self.shipNode = modelNode
            let containerNode = SCNNode()
            containerNode.geometry = SCNGeometry()
            containerNode.addChildNode(modelNode)
            self.containerNode = containerNode
            return containerNode
        }
        else {
            print("failed")
            return SCNNode()
        }
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
        hullMaterial.metalness.contents = 1.0
        hullMaterial.roughness.contents = 1
        
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
