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

@MainActor struct HUDView: View {
    @EnvironmentObject var spacecraftViewModel: SpacecraftViewModel
    @State private var reticlePosition: CGPoint = CGPoint()
    @State var fireCooldown: Bool = false
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
                .position(self.reticlePosition)
                .foregroundColor(.red)
            Spacer()
            
            HStack {
                Button(action: {
                    print("fire!!!")
                    self.spacecraftViewModel.weaponType == "Missile" ? self.spacecraftViewModel.missiles.append(self.spacecraftViewModel.ship.fireMissile()) : self.spacecraftViewModel.ship.fireLaser()
                    if self.spacecraftViewModel.weaponType == "Missile" {
                        self.fireCooldown = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.fireCooldown = false
                        }
                    }
                }) {
                    Label("",systemImage: "flame")
                }.disabled(self.fireCooldown)
                .foregroundColor(.white)
                .padding()
            }
            Slider(value: $spacecraftViewModel.ship.throttle, in: -100...100)
            Button(action: {
                self.spacecraftViewModel.toggleWeapon()
            }) {
                Text("Switch Weapon: \(spacecraftViewModel.weaponType)")
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .padding().onAppear {
            Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true, block: { _ in
                self.updateReticle()
            })
        }
    }
    func updateReticle() {
        // Find the enemy ship that is closest to the player's ship
        var closestEnemy: SCNNode?
        var closestDistance: Float = .greatestFiniteMagnitude
        for enemy in spacecraftViewModel.belligerents {
            let distance = simd_distance(enemy.simdPosition, self.spacecraftViewModel.ship.shipNode.simdPosition)
            if distance < closestDistance && enemy != self.spacecraftViewModel.ship.shipNode {
                closestDistance = distance
                closestEnemy = enemy
            }
        }

        // Check if there is a closest enemy within a certain distance
        if let closestEnemy = closestEnemy, closestDistance < 4000 {
            // Convert the 3D position of the closest enemy to a 2D position in the view
            let projectedPoint = self.spacecraftViewModel.view.projectPoint(closestEnemy.worldPosition)
            let reticlePosition = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
            //print(projectedPoint, reticlePosition)
            // Pass the reticlePosition to your ReticleView and use it to update its position on the screen
            self.reticlePosition = reticlePosition
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
        path.move(to: CGPoint(x: rect.midX, y: rect.minY+50))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY+50))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY+50))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY+50))
        return path
    }
}
