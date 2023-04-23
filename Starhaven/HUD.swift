//
//  HUD.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

struct HUDView: View {
    @EnvironmentObject var spacecraftViewModel: SpacecraftViewModel

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
                .foregroundColor(.red)
            Spacer()
            
            HStack {
                Button(action: {
                    print("fire!!!")
                    self.spacecraftViewModel.weaponType == "Missile" ? self.spacecraftViewModel.ship.fireMissile() : self.spacecraftViewModel.ship.fireLaser()
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
        }.padding()
    }
    @State var fireCooldown: Bool = false
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
