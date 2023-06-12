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
    unowned var spaceViewModel: SpacegroundViewModel
    @Binding var userSelectedSettings: Bool
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
            .stroke(self.spaceViewModel.closestEnemy == nil ? Color.white : Color.red, lineWidth: 1)
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
            .font(.custom("Avenir Next Regular", size: 24)).padding().foregroundColor(.red)
            HStack {
                self.settingsButton; Spacer()
            }.padding(.horizontal)
            Spacer()
        }
    }
    var settingsButton: some View {
        Image(systemName: "gear.circle.fill").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/10)
            .onTapGesture {
                self.userSelectedSettings = true
            }
    }
    var pointStack: some View {
        VStack { Text("POINTS"); Text("\(spaceViewModel.points)") }
    }
    var speedStack: some View {
        VStack { Text("SPEED"); Text("\(Int(spaceViewModel.ship.throttle * 10)) km/s") }
    }
    var gearStack: some View {
        VStack {
            Text("GEAR")
            HStack {
                Text("1").foregroundColor(self.gear==1 ? .white : .red)
                Text("2").foregroundColor(self.gear==2 ? .white : .red)
                Text("3").foregroundColor(self.gear==3 ? .white : .red)
                Text("4").foregroundColor(self.gear==4 ? .white : .red)
            }
        }.onTapGesture {
            if self.gear == 4 {
                self.gear = 1
            } else { self.gear += 1 }
        }
    }
    @State var throttle: Float = 0
    var mainHUD: some View {
        HStack {
            VStack {
                Spacer()
                CustomSlider(value: self.$throttle, range: -200 * Float(self.gear)...200 * Float(self.gear), onChange: { val in
                    self.spaceViewModel.throttle(value: self.throttle)
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
            Task {
                self.spaceViewModel.fireMissile(target: self.spaceViewModel.closestEnemy)
                self.spaceViewModel.fireCooldown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.spaceViewModel.fireCooldown = false
                }
            }
        }) {
            Image(systemName: "flame")
                .resizable()
                .scaledToFit()
                .foregroundColor(self.spaceViewModel.fireCooldown ? .gray : .red)
                .frame(width: UIScreen.main.bounds.width/6, height: UIScreen.main.bounds.width/6, alignment: .center)
        }.disabled(self.spaceViewModel.fireCooldown)
        .foregroundColor(.white)
        .padding()
    }
    var scoreUpdates: some View {
        VStack {
            Spacer()
            if spaceViewModel.showKillIncrement {
                Text("+10,000")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spaceViewModel.showKillIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                            spaceViewModel.showKillIncrement = false
                        }
                    }
                Text("ENEMY DESTROYED")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spaceViewModel.showKillIncrement)
            }
            if spaceViewModel.showScoreIncrement {
                Text("+\(Int(self.spaceViewModel.ship.throttle) * 100 * 60)")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spaceViewModel.showScoreIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            spaceViewModel.showScoreIncrement = false
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
