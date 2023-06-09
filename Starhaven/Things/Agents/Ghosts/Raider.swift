//
//  Raider.swift
//  Starhaven
//
//  Created by JxR on 4/26/23.
//
import Foundation
import SwiftUI
import SceneKit
import simd

@MainActor class Raider {
    unowned var spacegroundViewModel: SpacegroundViewModel
    var shipNode: SCNNode = SCNNode()
    var throttle: Float = 0
    var rearEmitterNode = SCNNode()
    var fireParticleSystem: SCNParticleSystem = SCNParticleSystem()
    var waterParticleSystem: SCNParticleSystem = SCNParticleSystem()
    var containerNode: SCNNode = SCNNode()
    var currentTime: TimeInterval = 0.0
    var currentTarget: SCNNode? = nil
    var faction: Faction
    var scale: CGFloat = 0
    var ghostGhount: Int = 0
    var targets: [SCNNode] = []
    var centralOffset: CGFloat = 0
    var isEvading: Bool = false
    var isChasing: Bool = false
    var isEngaging: Bool = false
    var barrelRollStartTime: TimeInterval = 0
    var barrelRollDuration: TimeInterval = 0
    var modelNode: SCNNode // Add a new property to store the shared modelNode
    init(spacegroundViewModel: SpacegroundViewModel, faction: Faction, modelNode: SCNNode) {
        self.faction = faction
        self.spacegroundViewModel = spacegroundViewModel
        self.modelNode = modelNode // Store the passed in modelNode
        self.createShip()
        self.selectNewTarget()
    }

    // GHOST MOVEMENTS
    public func updateAI() {
        Task {
            // Check if the current target is still valid
            if self.ghostGhount != self.spacegroundViewModel.ghosts.count {
                if self.currentTarget != nil && Float.random(in: 0...1) < 0.99 {
                    if !self.spacegroundViewModel.ghosts.contains(where: { $0.shipNode == self.currentTarget! }) { self.selectNewTarget() }
                    self.ghostGhount = self.spacegroundViewModel.ghosts.count
                }
                else {
                    self.selectNewTarget()
                }
            }
            if let target = self.currentTarget {
                let pos = self.shipNode.worldPosition
                let targetPos = target.worldPosition
                // Update the enemy ship's behavior based on the current target
                // Create and apply a SCNLookAtConstraint to make the enemy ship always face the current target's position
                let constraint = SCNLookAtConstraint(target: target)
                constraint.isGimbalLockEnabled = true
                // Move the enemy ship towards the current target's position by a fixed amount on each frame
                let direction = targetPos - pos
                let distance = direction.length()
                let normalizedDirection = SCNVector3(direction.x / distance, direction.y / distance, direction.z / distance)
                
                // Set a minimum distance between the enemy and player ships
                let minDistance: Float = 35_000
                
                DispatchQueue.main.async {
                    self.shipNode.constraints = [constraint]
                    let speed: Float = 8 * Float.random(in: 0.5...1.05)
                    
                    if distance < minDistance {
                        // Complex chase
                        let chaseOffset = self.getChaseOffset()
                        self.shipNode.worldPosition = SCNVector3(
                            self.shipNode.worldPosition.x + chaseOffset.x * speed,
                            self.shipNode.worldPosition.y + chaseOffset.y * speed,
                            self.shipNode.worldPosition.z + chaseOffset.z * speed
                        )
                    } else if distance > minDistance {
                        self.shipNode.worldPosition = SCNVector3(
                            self.shipNode.worldPosition.x + normalizedDirection.x * speed,
                            self.shipNode.worldPosition.y + normalizedDirection.y * speed,
                            self.shipNode.worldPosition.z + normalizedDirection.z * speed
                        )
                    }
                    if Float.random(in: 0...1) > 0.998 {
                        //self.fireLaser(color: self.faction == .Wraith ? .red : .green)
                    }
                    if Float.random(in: 0...1) > 0.998 {
                        self.fireMissile(target: self.currentTarget, particleSystemColor: self.faction == .Wraith ? .systemPink : .cyan)
                    }
                }
            }
        }
    }
    func getChaseOffset() -> SCNVector3 {
        // Define the scale of the sinusoidal chase
        let chaseScale: Float = 0.5

        // Combine multiple sinusoids for a more complex chase pattern
        let chaseSpiralOffset = SCNVector3(
            chaseScale * cos(Float(self.spacegroundViewModel.currentTime) / 3),
            chaseScale * sin(Float(self.spacegroundViewModel.currentTime) / 1.5),
            chaseScale * cos(Float(self.spacegroundViewModel.currentTime) / 2)
        )

        return chaseSpiralOffset
    }
    func getEvasionOffset() -> SCNVector3 {
        // Define the scale of the sinusoidal evasion
        let evasionScale: Float = 0.5
        let sign: Float = self.faction == .Wraith ? -1.0 : 1.0
        // Combine multiple sinusoids for a more organic evasion pattern
        let evasionSpiralOffset = SCNVector3(
            evasionScale * sin(Float(self.currentTime)) * sign,
            evasionScale * sin(Float(self.currentTime) / 2) * sign,
            evasionScale * cos(Float(self.currentTime) / 3 * sign)
        )

        return evasionSpiralOffset
    }
    func selectNewTarget() {
        Task {
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
        Task {
            let missile = GhostMissile(target: target, particleSystemColor: particleSystemColor, viewModel: self.spacegroundViewModel)
            // Convert shipNode's local position to world position
            let worldPosition = self.shipNode.convertPosition(SCNVector3(0, -10, 5 * self.scale), to: self.containerNode.parent)
            
            missile.missileNode.position = worldPosition
            let direction = self.shipNode.presentation.worldFront
            let missileMass = missile.missileNode.physicsBody?.mass ?? 1
            missile.missileNode.orientation = self.shipNode.presentation.orientation
            missile.missileNode.eulerAngles.x += Float.pi / 2
            let missileForce = CGFloat(self.throttle + 1) * 12_500 * missileMass
            missile.missileNode.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
            self.spacegroundViewModel.view.prepare([missile.missileNode]) { success in
                DispatchQueue.main.async {
                    self.spacegroundViewModel.scene.rootNode.addChildNode(missile.missileNode)
                }
            }
        }
    }
    @MainActor func fireLaser(target: SCNNode? = nil, color: UIColor) {
        Task {
            let laser = Laser(color: color)
            // Convert shipNode's local position to world position
            let worldPosition = self.shipNode.convertPosition(SCNVector3(Bool.random() == true ? -4 * self.scale : 4 * self.scale, -10, 2), to: self.containerNode.parent)
            
            laser.laserNode.position = worldPosition
            laser.laserNode.orientation = self.shipNode.presentation.orientation
            laser.laserNode.eulerAngles.x += Float.pi / 2
            let direction = self.shipNode.presentation.worldFront
            let laserMass = laser.laserNode.physicsBody?.mass ?? 1
            let laserForce = CGFloat(abs(self.throttle) + 1) * 14_000 * laserMass
            laser.laserNode.physicsBody?.applyForce(direction * Float(laserForce), asImpulse: true)
            self.spacegroundViewModel.view.prepare([laser.laserNode]) { success in
                self.spacegroundViewModel.scene.rootNode.addChildNode(laser.laserNode)
            }
        }
    }
    func createShip(scale: CGFloat = 5) {
        // Use the stored modelNode property instead of loading the model again
        self.modelNode.scale = SCNVector3(scale, scale, scale)
        self.shipNode = self.modelNode
        // Create the physics body for the enemy ship using its geometry
        let shape = SCNPhysicsShape(node: shipNode, options: [.keepAsCompound: true])
        shipNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        shipNode.physicsBody?.isAffectedByGravity = false
        // Set the category, collision, and contact test bit masks
        self.shipNode.physicsBody?.categoryBitMask = CollisionCategory.enemyShip
        self.shipNode.physicsBody?.collisionBitMask = CollisionCategory.missile
        self.shipNode.physicsBody?.contactTestBitMask = CollisionCategory.laser | CollisionCategory.missile
        shipNode.physicsBody?.collisionBitMask &= ~CollisionCategory.laser
    }
}
