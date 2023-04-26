//
//  HUD.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI
import simd

struct HUDView: View {
    @EnvironmentObject var spacecraftViewModel: SpacegroundViewModel
    @State private var reticlePosition: CGPoint = CGPoint()
    @State var fireCooldown: Bool = false
    @State var boundingBoxNode: SCNNode? = nil
    var body: some View {
        VStack {
            HStack {
                Text("Pitch: \(spacecraftViewModel.ship.pitch, specifier: "%.2f")")
                Spacer()
                Text("Speed: \(spacecraftViewModel.ship.throttle * 10, specifier: "%.2f") km/s")
            }
            .foregroundColor(.blue)
            HStack {
                if self.spacecraftViewModel.isInverted {
                    Text("INVERTED")
                        .foregroundColor(.red)
                        .bold()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                spacecraftViewModel.isInverted = false
                            }
                        }
                }
                Spacer()
                Text("POINTS: \(spacecraftViewModel.points)")
            }.foregroundColor(.red)
            Button(action: {
                self.spacecraftViewModel.toggleWeapon()
            }) {
                Text("Switch Weapon: \(spacecraftViewModel.weaponType)")
                    .foregroundColor(.white)
                    .padding()
            }
            if spacecraftViewModel.showKillIncrement {
                Text("+10,000")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spacecraftViewModel.showKillIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            spacecraftViewModel.showKillIncrement = false
                        }
                    }
                Text("GHOST DESTROYED")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spacecraftViewModel.showKillIncrement)
            }
            if spacecraftViewModel.showScoreIncrement {
                Text("+\(Int(self.spacecraftViewModel.ship.throttle) * 100)")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spacecraftViewModel.showScoreIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            spacecraftViewModel.showScoreIncrement = false
                        }
                    }
            }
            Spacer()
            ReticleView()
                .opacity(0.80)
                .foregroundColor(.red)
            Spacer()
            
            HStack {
                Button(action: {
                    print("fire!!!")
                    self.spacecraftViewModel.weaponType == "Missile" ? DispatchQueue.main.async { self.spacecraftViewModel.missiles.append(self.spacecraftViewModel.ship.fireMissile(target: self.spacecraftViewModel.closestEnemy)) } : self.spacecraftViewModel.ship.fireLaser()
                    if self.spacecraftViewModel.weaponType == "Missile" {
                        self.fireCooldown = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.fireCooldown = false
                        }
                    }
                }) {
                    Label("FIRE",systemImage: "flame")
                }.disabled(self.fireCooldown)
                .foregroundColor(.white)
                .padding()
            }
            Slider(value: $spacecraftViewModel.ship.throttle, in: -100...100)
        }
        .padding().onAppear {
            Timer.scheduledTimer(withTimeInterval: 1/30.0, repeats: true, block: { _ in
                DispatchQueue.main.async {
                    if self.fireCooldown {
                        boundingBoxNode?.removeFromParentNode()
                        boundingBoxNode = nil
                    }
                    else {
                        DispatchQueue.main.async { self.updateMissileLockBoundingBox() }
                    }
                }
            })
        }
    }
    func updateMissileLockBoundingBox() {
        // Find the enemy ship that is closest to the player's ship
        var closestDistance: Float = .greatestFiniteMagnitude
        for enemy in spacecraftViewModel.ghosts {
            let node = enemy.shipNode
            let distance = simd_distance(node.simdPosition, self.spacecraftViewModel.ship.shipNode.simdPosition)
            if distance < closestDistance && node != self.spacecraftViewModel.ship.shipNode {
                closestDistance = distance
                self.spacecraftViewModel.closestEnemy = node
            }
        }

        // Remove the existing bounding box if it's attached to a different enemy
        if let existingBoundingBox = boundingBoxNode, let parentNode = existingBoundingBox.parent, parentNode != self.spacecraftViewModel.closestEnemy {
            existingBoundingBox.removeFromParentNode()
            boundingBoxNode = nil
        }

        // Check if there is a closest enemy within a certain distance
        if let closestEnemy = self.spacecraftViewModel.closestEnemy, closestDistance < 100000 {
            // If a bounding box node does not exist, create it and add it as a child node to the closest enemy
            if boundingBoxNode == nil {
                let boundingBox = closestEnemy.boundingBox
                let width = CGFloat(boundingBox.max.x - boundingBox.min.x)
                let height = CGFloat(boundingBox.max.x - boundingBox.min.x)
                let box = SCNBox(width: width * 2, height: height * 2, length: height * 2, chamferRadius: 1)
                box.firstMaterial?.diffuse.contents = UIColor.red
                let planeNode = SCNNode(geometry: box)
                planeNode.opacity = 0.1
                planeNode.position = SCNVector3((boundingBox.min.x + boundingBox.max.x) / 2, (boundingBox.min.y + boundingBox.max.y) / 2, 0)
                closestEnemy.addChildNode(planeNode)
                boundingBoxNode = planeNode
            }
        } else {
            // If there is no closest enemy or it's out of range, remove the bounding box
            boundingBoxNode?.removeFromParentNode()
            boundingBoxNode = nil
        }
    }

}
struct ReticleView: View {
    var body: some View {
        ZStack {
            Crosshair()
                .stroke(Color.red, lineWidth: 1)
                .frame(width: 40, height: 30).opacity(0.80)
        }
    }
}

struct Crosshair: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
