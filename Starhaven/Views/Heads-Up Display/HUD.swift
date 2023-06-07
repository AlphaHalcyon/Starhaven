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
    @State var gear: Int = 1
    var body: some View {
        ZStack {
            self.mainHUD
            self.infoHUD
            self.scoreUpdates
            VStack {
                Spacer()
                self.reticle
                Spacer()
            }
        }
    }
    var reticle: some View {
        Crosshair()
            .stroke(self.spacecraftViewModel.closestEnemy == nil ? Color.white : Color.red, lineWidth: 1)
            .frame(width: 20, height: 20).opacity(0.98)
    }
    var dynamicCamera: some View {
        VStack {
            Image(systemName: "camera").resizable().scaledToFit().frame(width: 100)
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
                Text("4").foregroundColor(self.gear==3 ? .white : .red)
            }
        }.onTapGesture {
            if self.gear == 4 {
                self.gear = 1
            } else { self.gear += 1 }
        }
    }
    var mainHUD: some View {
        HStack {
            VStack {
                Spacer()
                CustomSlider(value: self.$spacecraftViewModel.ship.throttle, range: -125 * Float(self.gear)...125 * Float(self.gear), onChange: { val in
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
            DispatchQueue.main.async {
                self.spacecraftViewModel.fireMissile(target: self.spacecraftViewModel.closestEnemy)
                self.spacecraftViewModel.fireCooldown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    self.spacecraftViewModel.fireCooldown = false
                }
            }
        }) {
            Image(systemName: "flame")
                .resizable()
                .scaledToFit()
                .foregroundColor(self.spacecraftViewModel.fireCooldown ? .gray : .red)
                .frame(width: UIScreen.main.bounds.width/6, height: UIScreen.main.bounds.width/6, alignment: .center)
        }.disabled(self.spacecraftViewModel.fireCooldown)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            spacecraftViewModel.showScoreIncrement = false
                        }
                    }
            }
            Spacer()
            Spacer()
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
