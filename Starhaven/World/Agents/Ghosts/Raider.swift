//
//  Raider.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//
import Foundation
import SwiftUI
import SceneKit
import GLKit
import simd

class Raider: ObservableObject {
    @Published var spacegroundViewModel: SpacegroundViewModel
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
    @Published var rearEmitterNode = SCNNode()
    @Published var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    @Published var containerNode: SCNNode = SCNNode()
    @Published var currentTime: TimeInterval = 0.0
    @Published var currentTarget: SCNNode? = nil
    @Published var faction: Faction
    @Published var scale: CGFloat = 0
    @Published var ghostGhount: Int = 0
    @Published var targets: [SCNNode] = []
    @Published var centralOffset: CGFloat = 0
    init(spacegroundViewModel: SpacegroundViewModel, faction: Faction) {
        self.faction = faction
        self.spacegroundViewModel = spacegroundViewModel
        self.selectNewTarget()
    }
    // GHOST MOVEMENTS
    @MainActor func updateAI() {
        DispatchQueue.main.async {
            // Check if the current target is still valid
            if self.ghostGhount != self.spacegroundViewModel.ghosts.count {
                if self.currentTarget != nil {
                    if !self.spacegroundViewModel.ghosts.contains(where: { $0.shipNode == self.currentTarget! }) { self.selectNewTarget() }
                    self.ghostGhount = self.spacegroundViewModel.ghosts.count
                }
                else {
                    DispatchQueue.main.async { self.selectNewTarget() }
                }
            }
            
            // Update the enemy ship's behavior based on the current target
            if let target = self.currentTarget {
                // Create and apply a SCNLookAtConstraint to make the enemy ship always face the current target's position
                let constraint = SCNLookAtConstraint(target: target)
                constraint.isGimbalLockEnabled = true
                self.shipNode.constraints = [constraint]

                // Move the enemy ship towards the current target's position by a fixed amount on each frame
                let direction = target.worldPosition - self.shipNode.worldPosition
                let distance = direction.length()
                let normalizedDirection = SCNVector3(direction.x / distance, direction.y / distance, direction.z / distance)
                
                // Set a minimum distance between the enemy and player ships
                let minDistance: Float = 15_000
                var speed: Float = 10
                
                // If the enemy ship is closer than the minimum distance, move it away from the player
                if distance > minDistance {
                    speed *= Float.random(in: 0.5...1.05)
                    self.shipNode.worldPosition = SCNVector3(self.shipNode.worldPosition.x + normalizedDirection.x * speed, self.shipNode.worldPosition.y + normalizedDirection.y * speed, self.shipNode.worldPosition.z + normalizedDirection.z * speed)
                }
                if Float.random(in: 0...1) > 0.9993 {
                    DispatchQueue.main.async { self.fireLaser(color: self.faction == .Wraith ? .red : .green) }
                }
                if Float.random(in: 0...1) > 0.995 {
                    DispatchQueue.main.async {
                        self.fireMissile(target: self.currentTarget, particleSystemColor: self.faction == .Wraith ? .systemPink : .cyan)
                    }
                }
            }
        }
    }
    func selectNewTarget() {
        DispatchQueue.main.async {
            // Filter out the current ship from the list of available targets
            let availableTargets = self.spacegroundViewModel.ghosts.filter { $0.shipNode != self.shipNode && $0.faction != self.faction }
            
            // Select a new target from the list of available targets
            if let newTarget = availableTargets.randomElement() {
                self.currentTarget = newTarget.shipNode
                //print("target acquired!")
            } else {
                // No targets available
                self.currentTarget = self.spacegroundViewModel.ship.shipNode
                print("no one left to kill :(")
            }
        }
    }

    // WEAPONS MECHANICS
    func fireMissile(target: SCNNode? = nil, particleSystemColor: UIColor) {
        DispatchQueue.main.async {
            let missile = GhostMissile(target: target, particleSystemColor: particleSystemColor)
            // Convert shipNode's local position to world position
            let worldPosition = self.shipNode.convertPosition(SCNVector3(0, -10, 5 * self.scale), to: self.containerNode.parent)
            
            missile.missileNode.position = worldPosition
            missile.missileNode.orientation = self.shipNode.presentation.orientation
            let direction = self.shipNode.presentation.worldFront
            let missileMass = missile.missileNode.physicsBody?.mass ?? 1
            let missileForce = CGFloat(self.throttle + 1) * 125 * missileMass
            missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
            self.spacegroundViewModel.view.prepare([missile.missileNode]) { success in
                self.spacegroundViewModel.scene.rootNode.addChildNode(missile.missileNode)
            }
        }
        
    }
    func fireLaser(target: SCNNode? = nil, color: UIColor) {
        DispatchQueue.main.async {
            let laser = Laser(color: color)
            // Convert shipNode's local position to world position
            let worldPosition = self.shipNode.convertPosition(SCNVector3(Bool.random() == true ? -4 * self.scale : 4 * self.scale, -10, 2), to: self.containerNode.parent)
            
            laser.laserNode.position = worldPosition
            laser.laserNode.orientation = self.shipNode.presentation.orientation
            laser.laserNode.eulerAngles.x += Float.pi / 2
            let direction = self.shipNode.presentation.worldFront
            let laserMass = laser.laserNode.physicsBody?.mass ?? 1
            let laserForce = CGFloat(abs(self.throttle) + 1) * 10_000 * laserMass
            laser.laserNode.physicsBody?.applyForce(direction * Float(laserForce), asImpulse: true)
            self.spacegroundViewModel.view.prepare([laser.laserNode]) { success in
                self.spacegroundViewModel.scene.rootNode.addChildNode(laser.laserNode)
            }
        }
    }

    func createShip(scale: CGFloat = 0.1) -> SCNNode {
        // Load the spaceship model
        // Usage:
        if let modelNode = loadOBJModel(named: "Raider") {
            modelNode.scale = SCNVector3(scale, scale, scale)
            self.shipNode = modelNode
            // Create the physics body for the enemy ship using its geometry
            let shape = SCNPhysicsShape(node: shipNode, options: [.keepAsCompound: true])
            shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
            shipNode.physicsBody?.isAffectedByGravity = false
            // Set the category, collision, and contact test bit masks
            self.shipNode.physicsBody?.categoryBitMask = CollisionCategory.enemyShip
            self.shipNode.physicsBody?.collisionBitMask = CollisionCategory.missile
            self.shipNode.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile
            shipNode.physicsBody?.collisionBitMask &= ~CollisionCategory.laser
            return modelNode
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
