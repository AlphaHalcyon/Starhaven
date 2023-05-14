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
    @State var gear: Int = 1
    var body: some View {
        ZStack {
            self.mainHUD
            self.infoHUD
            self.scoreUpdates
        }
        .onAppear {
            _ = self.missileLockTimer
        }
    }
    var infoHUD: some View {
        VStack {
            HStack {
                self.speedStack
                Spacer()
                self.gearStack
                Spacer()
                self.pointStack
            }
            .font(.custom("Avenir Next Regular", size: 25)).padding().foregroundColor(.red)
            Spacer()
        }
    }
    var pointStack: some View {
        VStack { Text("POINTS"); Text("\(spacecraftViewModel.points)") }
    }
    var speedStack: some View {
        VStack { Text("SPEED"); Text("\(Int(spacecraftViewModel.ship.throttle * 10)) km/s") }
    }
    var gearStack: some View {
        VStack {
            Text("GEAR")
            HStack {
                Text("1").foregroundColor(self.gear==1 ? .white : .red)
                Text("2").foregroundColor(self.gear==2 ? .white : .red)
                Text("3").foregroundColor(self.gear==3 ? .white : .red)
            }
        }.onTapGesture {
            if self.gear == 3 {
                self.gear = 1
            } else { self.gear += 1 }
        }
    }
    var mainHUD: some View {
        HStack {
            VStack {
                Spacer()
                CustomSlider(value: self.$spacecraftViewModel.ship.throttle, range: -50 * Float(self.gear)...50 * Float(self.gear), onChange: { val in
                    // changes here
                })
            }
            Spacer()
            VStack {
                Spacer()
                self.fireButton
            }
        }
    }
    var fireButton: some View {
        Button(action: {
            DispatchQueue.main.async { self.spacecraftViewModel.missiles.append(self.spacecraftViewModel.fireMissile(target: self.spacecraftViewModel.closestEnemy))
                self.fireCooldown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.fireCooldown = false
                }
            }
        }) {
            Image(systemName: "flame")
                .resizable()
                .scaledToFit()
                .foregroundColor(self.fireCooldown ? .gray : .red)
                .frame(width: UIScreen.main.bounds.width/6, height: UIScreen.main.bounds.width/6, alignment: .center)
        }.disabled(self.fireCooldown)
        .foregroundColor(.white)
        .padding()
    }
    var scoreUpdates: some View {
        VStack {
            Spacer()
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
                Text("ENEMY DESTROYED")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spacecraftViewModel.showKillIncrement)
            }
            if spacecraftViewModel.showScoreIncrement {
                Text("+\(Int(self.spacecraftViewModel.ship.throttle) * 100 * 60)")
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
        }
    }
    var missileLockTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true, block: { _ in
            DispatchQueue.main.async {
                if self.fireCooldown {
                    if let boundingBoxNode = self.boundingBoxNode {
                        boundingBoxNode.removeFromParentNode()
                        self.boundingBoxNode = nil
                    }
                }
                else {
                    self.updateMissileLockBoundingBox()
                }
            }
        })
    }
    @MainActor public func updateMissileLockBoundingBox() {
        Task {
            // Find the enemy ship that is closest to the player's ship
            let centerPoint = CGPoint(x: self.spacecraftViewModel.view.bounds.midX, y: self.spacecraftViewModel.view.bounds.midY)

            var closestNode: SCNNode?
            var minDistance = CGFloat.greatestFiniteMagnitude

            for node in self.spacecraftViewModel.ghosts {
                if !self.spacecraftViewModel.loadingSceneView && self.spacecraftViewModel.currentRotation != simd_quatf(angle: .pi, axis: simd_float3(x: 0, y: 1, z: 0)) {
                    let projectedPoint = self.spacecraftViewModel.view.projectPoint(node.shipNode.position)
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
                    let distance = hypot(projectedCGPoint.x - centerPoint.x, projectedCGPoint.y - centerPoint.y)

                    if distance < minDistance {
                        minDistance = distance
                        closestNode = node.shipNode
                    }
                }
            }

            if let closestNode = closestNode {
                // closestNode is the SCNNode closest to the center of the screen
                self.spacecraftViewModel.closestEnemy = closestNode
            }

            // Remove the existing bounding box if it's attached to a different enemy
            if let existingBoundingBox = boundingBoxNode, let parentNode = existingBoundingBox.parent, parentNode != self.spacecraftViewModel.closestEnemy {
                DispatchQueue.main.async {
                    existingBoundingBox.removeFromParentNode()
                    self.boundingBoxNode = nil
                }
            }

            // Check if there is a closest enemy within a certain distance
            if let closestEnemy = closestNode {
                // If a bounding box node does not exist, create it and add it as a child node to the closest enemy
                if boundingBoxNode == nil {
                    let boundingBox = closestEnemy.boundingBox
                    let width = CGFloat(boundingBox.max.x - boundingBox.min.x)
                    let height = CGFloat(boundingBox.max.x - boundingBox.min.x)
                    let box = SCNBox(width: width * 1, height: height * 1, length: height * 2, chamferRadius: 1)
                    box.firstMaterial?.diffuse.contents = UIColor.red
                    let planeNode = SCNNode(geometry: box)
                    planeNode.opacity = 0.5
                    planeNode.position = SCNVector3((boundingBox.min.x + boundingBox.max.x) / 2, (boundingBox.min.y + boundingBox.max.y) / 2, 0)
                    boundingBoxNode = planeNode
                    self.spacecraftViewModel.view.prepare([planeNode]) { success in
                        closestEnemy.addChildNode(planeNode)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    // If there is no closest enemy or it's out of range, remove the bounding box
                    if let box = self.boundingBoxNode {
                        box.removeFromParentNode()
                        self.boundingBoxNode = nil
                    }
                }
            }
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
