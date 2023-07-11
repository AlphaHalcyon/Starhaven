//
//  Moonbase.swift
//  Starhaven
//
//  Created by JxR on 6/27/23.
//

import Foundation
import SwiftUI
import SceneKit

class Moonbase: SceneObject {
    var sceneManager: SceneManager
    var faction: Faction = .Wraith
    var isAI: Bool = false
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.node = node
        self.sceneManager = sceneManager
    }
    
    public var node: SCNNode
    private var scale: Float = 1.0
    var habNode: SCNNode?
    var innerHab: SCNNode?
    // Add other moonbase parts here
    private var hasLight: Bool = false
    private var railgunBaseNodes: [SCNNode] = []
    private var railgunTurretNode: SCNNode?
    init(sceneManager: SceneManager, planet: Planet, hasLight: Bool) {
        self.node = SCNNode()
        self.hasLight = hasLight
        if self.hasLight {
            let lightNode = SCNNode()
            let light = SCNLight()
            light.intensity = 500
            light.type = .spot
            light.color = UIColor.cyan
            lightNode.position = SCNVector3(0, 5, 0)
            lightNode.light = light
            lightNode.look(at: planet.node.position)
            lightNode.name = "Moonbase Light"
            self.node.addChildNode(lightNode)
        }
        self.sceneManager = sceneManager
        self.loadHab()
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(0,0,1.5 * self.scale))
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(0,0,-1.5 * self.scale))
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(1.5,0,1.5 * self.scale))
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(1.5,0,-1.5 * self.scale))
        let shape = SCNPhysicsShape(node: self.node, options: [.keepAsCompound: true])
        let physicsBody: SCNPhysicsBody = SCNPhysicsBody(type: .static, shape: shape)
        physicsBody.categoryBitMask = CollisionCategory.enemyShip
        physicsBody.collisionBitMask = CollisionCategory.laser
        physicsBody.contactTestBitMask = CollisionCategory.laser
        self.node.physicsBody = physicsBody
        //self.loadRailgunTurret(named: "moonGun")
        // Load other moonbase parts here
        //self.loadPanels()
    }
    private func loadRailgunBase(named name: String, offset: SCNVector3) {
        do {
            let node = SCNNode()
            let cylinder = SCNCylinder(radius: 75, height: 125)
            node.geometry = cylinder
            let model = try ModelManager.loadOBJModel(named: name)
            if let railgunBaseNode = model {
                railgunBaseNode.position=SCNVector3(0,50,0)
                self.railgunBaseNodes.append(railgunBaseNode)
                node.addChildNode(railgunBaseNode.flattenedClone())
            }
            node.position = offset
            node.scale = SCNVector3(0.001 * self.scale,0.001 * self.scale,0.001 * self.scale)
            node.castsShadow = true
            
            self.node.addChildNode(node.flattenedClone())
        } catch {
            print("Failed to load railgun base node: \(error)")
        }
    }
    private func loadTurret(named name: String) {
        do {
            let turret = try ModelManager.loadOBJModel(named: name)
            if let turret = turret {
                self.node.addChildNode(turret)
            }
        } catch {
            print("Failed to load railgun turret node: \(error)")
        }
    }
    private func loadPanels(){
        do {
            for i in 0...10 {
                let panel = try ModelManager.loadOBJModel(named: "objSolar")
                if let panel = panel {
                    panel.position = SCNVector3(-2_5,-10 + -i * 1,i*1*2)
                    panel.eulerAngles.y = .pi * 0.15
                    panel.scale=SCNVector3(2.5,2.5,2.5)
                    self.node.addChildNode(panel)
                }
            }
        } catch {
            print("Failed to load panel node: \(error)")
        }
    }
    private func loadHab() {
        do {
            self.innerHab = try ModelManager.loadOBJModel(named: "innerHDU")
            if let innerHab = self.innerHab {
                innerHab.castsShadow = true
                innerHab.scale = SCNVector3(0.001 * self.scale,0.001 * self.scale,0.001 * self.scale)
                self.node.addChildNode(innerHab.flattenedClone())
            }
        } catch {
            print("Failed to load inner hab: \(error)")
        }
        
        do {
            self.habNode = try ModelManager.loadOBJModel(named: "outerHDU")
            if let habNode = self.habNode {
                habNode.castsShadow = true
                habNode.scale = SCNVector3(0.001 * self.scale,0.001 * self.scale,0.001 * self.scale)
                self.node.addChildNode(habNode.flattenedClone())
            }
        } catch {
            print("Failed to load outer hab: \(error)")
        }
    }
    
    // Add methods to manipulate moonbase
    func update(updateAtTime time: TimeInterval) {
        /*
         if let target = self.target {
             if Float.random(in: 0...1) < 1/50 {
                 print("firing!")
                 self.fireMissile(target: self.target, particleSystemColor: .red)
             }
         } else {
             self.selectNewTarget()
         }
         */
    }
    func destroy() {
    }
    // Aim the railgun turret at a target
    func aimRailgunAt(target: SCNVector3) {
        railgunTurretNode?.look(at: target)
    }
    // WEAPONS MECHANICS
    var firing: Bool = false
    var target: SCNNode?
    func fireMissile(target: SCNNode? = nil, particleSystemColor: UIColor) {
        let missile: OSNRMissile
        if self.sceneManager.missiles.isEmpty {
            missile = OSNRMissile(target: target, particleSystemColor: particleSystemColor, sceneManager: self.sceneManager)
            self.fire(missile: missile.missileNode)
        } else if let missile = self.sceneManager.missiles.popLast() {
            missile.target = target
            missile.faction = faction
            missile.particleSystem.particleColor = particleSystemColor
            self.fire(missile: missile.missileNode)
            missile.fire()
        } else {
            missile = OSNRMissile(target: target, particleSystemColor: particleSystemColor, sceneManager: self.sceneManager)
            self.fire(missile: missile.missileNode)
        }
    }
    func fire(missile: SCNNode) {
        missile.position = self.railgunBaseNodes[0].position
        missile.physicsBody?.velocity = SCNVector3(0,0,0)
        let direction = self.node.presentation.worldFront
        let missileMass = missile.physicsBody?.mass ?? 1
        missile.orientation = self.node.presentation.orientation
        missile.eulerAngles.x += Float.pi / 2
        let missileForce = 500 * missileMass
        self.sceneManager.addNode(missile)
        DispatchQueue.main.async {
            missile.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        }
    }
    func selectNewTarget() {
        let targets = self.sceneManager.sceneObjects.filter { $0.isAI && $0.faction != self.faction }
        if let target = targets.randomElement() {
            self.target = target.node
        }
        self.target = targets.randomElement()?.node
        let constraint = SCNLookAtConstraint(target: target)
        constraint.isGimbalLockEnabled = true
        for node in railgunBaseNodes {
            node.constraints = [constraint]
        }
    }
}
