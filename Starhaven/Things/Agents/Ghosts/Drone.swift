//
//  GhostAssaultDrone.swift
//  Starhaven
//
//  Created by JxR on 4/25/23.
//
import Foundation
import SwiftUI
import SceneKit
import simd

class AssaultDrone: ObservableObject {
    @State var spacegroundViewModel: SpacegroundViewModel
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
    @Published var timer: Timer = Timer()
    @Published var faction: Faction
    @Published var scale: CGFloat = 0
    @Published var ghostGhount: Int = 0
    // INIT
    init(spacegroundViewModel: SpacegroundViewModel) {
        self.spacegroundViewModel = spacegroundViewModel
        // Initialize new properties
        self.faction = Faction.allCases.randomElement()!
        self.selectNewTarget()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            self.updateAI()
        }
    }
    // GHOST MOVEMENTS
    func updateAI() {
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
                let minDistance: Float = 5000
                var speed: Float = 12
                
                // If the enemy ship is closer than the minimum distance, move it away from the player
                if distance > minDistance {
                    speed *= Float.random(in: 0.5...1.05)
                    self.shipNode.worldPosition = SCNVector3(self.shipNode.worldPosition.x + normalizedDirection.x * speed, self.shipNode.worldPosition.y + normalizedDirection.y * speed, self.shipNode.worldPosition.z + normalizedDirection.z * speed)
                }
                if Float.random(in: 0...1) > 0.925 {
                    DispatchQueue.main.async { self.fireLaser(color: self.faction == .Wraith ? .red : .green) }
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
            DispatchQueue.main.async {
                self.currentTarget = Float.random(in: 0...1) > 0.95 ? self.spacegroundViewModel.ship.shipNode : self.currentTarget
            }
        }
    }

    // WEAPONS MECHANICS
    public func fireMissile(target: SCNNode? = nil) {
        print("fire!")
    }
    func fireLaser(target: SCNNode? = nil, color: UIColor) {
        let laser = Laser(color: color)
        
        // Convert shipNode's local position to world position
        let worldPosition = shipNode.convertPosition(SCNVector3(Bool.random() == true ? -3 * scale : 3 * scale, -10, 2), to: containerNode.parent)
        
        laser.laserNode.position = worldPosition
        laser.laserNode.orientation = shipNode.presentation.orientation
        laser.laserNode.eulerAngles.x += Float.pi / 2
        let direction = shipNode.presentation.worldFront
        let laserMass = laser.laserNode.physicsBody?.mass ?? 1
        let laserForce = CGFloat(abs(throttle) + 1) * 5000 * laserMass
        laser.laserNode.physicsBody?.applyForce(direction * Float(laserForce), asImpulse: true)
        if let rootNode = containerNode.parent {
            print("adding laser")
            rootNode.addChildNode(laser.laserNode)
        }
    }

    // CREATION
    func createShip(scale: CGFloat = 1.0) -> SCNNode {
        let node = SCNNode()
        self.scale = scale
        node.geometry = SCNGeometry()
        // Create the main body of the spaceship
        let body = SCNCylinder(radius: 1.0 * scale, height: 10.0 * scale)
        body.firstMaterial?.diffuse.contents = UIColor.gray
        let bodyNode = SCNNode(geometry: body)
        bodyNode.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(bodyNode)

        // Create the rocket boosters
        let booster1 = SCNCylinder(radius: 0.5 * scale, height: 2.5 * scale)
        booster1.firstMaterial?.diffuse.contents = UIColor.darkGray
        let booster1Node = SCNNode(geometry: booster1)
        booster1Node.position = SCNVector3(-1.2 * scale, -1.0, 0)
        booster1Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(booster1Node)

        let booster2 = SCNCylinder(radius: 0.5 * scale, height: 2.5 * scale)
        booster2.firstMaterial?.diffuse.contents = UIColor.darkGray
        let booster2Node = SCNNode(geometry: booster2)
        booster2Node.position = SCNVector3(1.2 * scale, -1.0, 0)
        booster2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(booster2Node)

        // Create the wings
        let wing1 = SCNBox(width: 2.0 * scale, height: 0.1 * scale, length: 5 * scale, chamferRadius: 0)
        wing1.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing1Node = SCNNode(geometry: wing1)
        wing1Node.position = SCNVector3(-3 * scale, 1 * scale, 0)
        node.addChildNode(wing1Node)

        let wing2 = SCNBox(width: 2.0 * scale, height: 0.1 * scale, length: 5 * scale, chamferRadius: 0)
        wing2.firstMaterial?.diffuse.contents = UIColor.lightGray
        let wing2Node = SCNNode(geometry: wing2)
        wing2Node.position = SCNVector3(3 * scale, 1 * scale, 0)
        node.addChildNode(wing2Node)

        // Create missile tubes under the wings
        let missileTube1 = SCNCylinder(radius: 0.5 * scale, height: 3.5 * scale)
        missileTube1.firstMaterial?.diffuse.contents = UIColor.darkGray
        let missileTube1Node = SCNNode(geometry: missileTube1)
        missileTube1Node.position = SCNVector3(-1.5 * scale, 1.0 * scale, -1.2 * scale)
        missileTube1Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(missileTube1Node)

        let missileTube2 = SCNCylinder(radius: 0.5 * scale, height: 3.5 * scale)
        missileTube2.firstMaterial?.diffuse.contents = UIColor.darkGray
        let missileTube2Node = SCNNode(geometry: missileTube2)
        missileTube2Node.position = SCNVector3(1.5 * scale, 1.0 * scale, -1.2 * scale)
        missileTube2Node.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        node.addChildNode(missileTube2Node)
        node.eulerAngles.x = 40
        node.position = SCNVector3(0, -10, 0)
        let containerNode = SCNNode()
        containerNode.geometry = SCNGeometry()
        containerNode.addChildNode(node)
        self.shipNode = node
        self.containerNode = containerNode
        // Create the physics body for the enemy ship using its geometry
        let shape = SCNPhysicsShape(node: shipNode, options: [.keepAsCompound: true])
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        shipNode.physicsBody?.isAffectedByGravity = false
        // Set the category, collision, and contact test bit masks
        self.shipNode.physicsBody?.categoryBitMask = CollisionCategory.enemyShip
        self.shipNode.physicsBody?.collisionBitMask = CollisionCategory.missile
        self.shipNode.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile
        shipNode.physicsBody?.collisionBitMask &= ~CollisionCategory.laser
        return self.shipNode
    }
}
