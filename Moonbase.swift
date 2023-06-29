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
    var isAI: Bool = false
    
    required init(node: SCNNode, sceneManager: SceneManager) {
        self.node = node
        self.sceneManager = sceneManager
    }
    
    
    public var node: SCNNode
    private var habNode: SCNNode?
    private var innerHab: SCNNode?
    // Add other moonbase parts here
    private var railgunBaseNodes: [SCNNode] = []
    private var railgunTurretNode: SCNNode?
    init(sceneManager: SceneManager, planet: Planet) {
        
        self.node = SCNNode()
        self.sceneManager = sceneManager
        self.loadHab()
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(0,0,1_500))
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(0,0,-1_500))
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(1500,0,1_500))
        self.loadRailgunBase(named: "TankCannon", offset: SCNVector3(1_500,0,-1_500))
        //self.loadRailgunTurret(named: "moonGun")
        // Load other moonbase parts here
        self.loadPanels()
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
                node.addChildNode(railgunBaseNode)
            }
            node.position = offset
            node.scale = SCNVector3(2,2,2)
            node.castsShadow = true
            self.node.addChildNode(node)
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
                    panel.position = SCNVector3(-2_500,-100 + -i * 10,i*10*25)
                    panel.eulerAngles.y = .pi * 1.5
                    panel.scale=SCNVector3(25,25,25)
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
                self.node.addChildNode(innerHab)
            }
        } catch {
            print("Failed to load inner hab: \(error)")
        }
        
        do {
            self.habNode = try ModelManager.loadOBJModel(named: "outerHDU")
            if let habNode = self.habNode {
                habNode.castsShadow = true
                self.node.addChildNode(habNode)
            }
        } catch {
            print("Failed to load outer hab: \(error)")
        }
    }

    // Add methods to manipulate moonbase
    func update() {
        //self.aim
    }
    func destroy() {
    }
    // Aim the railgun turret at a target
    func aimRailgunAt(target: SCNVector3) {
        railgunTurretNode?.look(at: target)
    }
}
