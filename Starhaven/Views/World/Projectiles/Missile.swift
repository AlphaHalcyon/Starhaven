//
//  Missile.swift
//  Starhaven
//
//  Created by JxR on 4/12/23.
//

import Foundation
import SceneKit
import SwiftUI

class Missile {
    var missileNode: SCNNode
    var target: SCNNode?
    var particleSystem: SCNParticleSystem
    var explosionNode: SCNNode = SCNNode()
    var timer: Timer = Timer()
    var viewModel: SpacegroundViewModel
    init(target: SCNNode? = nil, particleSystemColor: UIColor, viewModel: SpacegroundViewModel) {
        self.viewModel = viewModel
        self.target = target
        // Create missile geometry and node
        let missileGeometry = SCNCylinder(radius: 2, height: 8)
        missileGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray
        self.missileNode = SCNNode(geometry: missileGeometry)
        // Adjust the physicsBody
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.angularVelocityFactor = SCNVector3(0, 0, 0) // Prevent rotation after being fired
        physicsBody.categoryBitMask = CollisionCategory.missile
        physicsBody.collisionBitMask = CollisionCategory.enemyShip
        physicsBody.contactTestBitMask = CollisionCategory.enemyShip
        // Create red particle system
        self.particleSystem = SCNParticleSystem()
        self.particleSystem.particleColor = particleSystemColor
        self.particleSystem.particleSize = 0.075
        self.particleSystem.birthRate = 500_000
        self.particleSystem.emissionDuration = 1
        self.particleSystem.particleLifeSpan = 0.1
        self.particleSystem.spreadingAngle = 180
        self.particleSystem.emitterShape = missileGeometry
        self.particleSystem.emissionDurationVariation = self.particleSystem.emissionDuration
        // Attach red particle system to the tail of the missile
        let emitterNode = SCNNode()
        emitterNode.position = SCNVector3(0, -1, 0)
        emitterNode.addParticleSystem(self.particleSystem)
        DispatchQueue.main.async {
            self.missileNode.physicsBody = physicsBody
            self.missileNode.addChildNode(emitterNode)
            self.missileNode.physicsBody?.isAffectedByGravity = false
            self.missileNode.physicsBody?.friction = 0
            self.missileNode.physicsBody?.damping = 0
            self.updateTracking()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.timer.invalidate()
                self.missileNode.removeFromParentNode()
                if let node = self.viewModel.cameraMissile?.missileNode {
                    if node == self.missileNode {
                        self.viewModel.cameraMissile = nil
                        self.viewModel.inMissileView = false
                    }
                }
            }
        }
    }
    func updateTracking() {
        print(self.target)
        if let target = self.target {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                self.timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.trackTarget()
                        }
                    }
                }
            })
        } else {
            print("yup")
            DispatchQueue.main.async {
                self.missileNode.simdOrientation = self.viewModel.ship.shipNode.simdOrientation
                self.missileNode.physicsBody?.applyForce(self.viewModel.ship.shipNode.worldFront * 5_000, asImpulse: true)
            }
        }
    }
    public func trackTarget() {
        if let target = self.target {
            let distanceToTarget: Float = (self.missileNode.presentation.position - target.presentation.position).length()
            let trackingThreshold: Float = 500.0  // Distance at which the missile stops adjusting its course
            
            if distanceToTarget > trackingThreshold {
                // Predict the future position of the target
                let predictionTime: TimeInterval = 1
                let targetVelocity = target.physicsBody?.velocity ?? SCNVector3Zero
                let predictedTargetPosition = target.presentation.position + (targetVelocity * Float(predictionTime))
                // Update missile's velocity
                let newDirection = (predictedTargetPosition - self.missileNode.presentation.position).normalized()
                let missileSpeed: Float = 16_000  // Set the speed of the missile
                DispatchQueue.main.async {
                    self.missileNode.physicsBody?.velocity = newDirection * missileSpeed
                }
            }
        }
    }

    func setLookAtConstraint() {
        guard let target = self.target else { return }
        let lookAtConstraint = SCNLookAtConstraint(target: target)
        lookAtConstraint.isGimbalLockEnabled = true // This prevents the missile from flipping upside down
        self.missileNode.constraints = [lookAtConstraint]
    }

    func handleCollision() {
        self.detonate() // boom
    }
    func detonate() {
        self.timer.invalidate()
        DispatchQueue.global().async {
            let coronaGeo = SCNSphere(radius: 150)
            
            // Create the particle system programmatically
            let fireParticleSystem = SCNParticleSystem()
            fireParticleSystem.particleImage = UIImage(named: "SceneKit Asset Catalog.scnassets/SunWeakMesh.jpg")
            fireParticleSystem.birthRate = 500_000
            fireParticleSystem.particleSize = 0.25
            fireParticleSystem.particleIntensity = 0.75
            fireParticleSystem.particleLifeSpan = 0.33
            fireParticleSystem.spreadingAngle = 180
            fireParticleSystem.particleAngularVelocity = 50
            fireParticleSystem.emitterShape = coronaGeo
            // Make the particle system surface-based
            fireParticleSystem.emissionDurationVariation = fireParticleSystem.emissionDuration
            // Add the particle system to the warhead
            let implodeAction = SCNAction.scale(to: 10, duration: 0.20)
            let implodeActionStep = SCNAction.scale(to: 5, duration: 1)
            let implodeActionEnd = SCNAction.scale(to: 0.1, duration: 0.125)
            let pulseSequence = SCNAction.sequence([implodeAction, implodeActionStep, implodeActionEnd])
            DispatchQueue.main.async {
                self.explosionNode.addParticleSystem(fireParticleSystem)
                self.viewModel.view.prepare([self.explosionNode]) { success in
                    self.missileNode.addChildNode(self.explosionNode)
                    self.explosionNode.runAction(SCNAction.repeat(pulseSequence, count: 1))
                    // Remove the missile node from the scene after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        self.missileNode.removeFromParentNode()
                        if let cameraMissile = self.viewModel.cameraMissile {
                            if cameraMissile.missileNode == self.missileNode {
                                self.viewModel.inMissileView = false
                                self.viewModel.cameraMissile = nil
                            }
                        }
                    }
                }
            }
        }
    }
    // In the Missile class, add the following function:
    func getMissileNode() -> SCNNode {
        return self.missileNode
    }

}
