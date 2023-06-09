//
//  SwiftUI Views.swift
//  Starhaven
//
//  Created by Jared on 7/9/23.
//

import Foundation
import SwiftUI
import SceneKit

struct OSNRMoonView: View {
    @StateObject var manager = GameManager()
    @State var userSelectedSettings: Bool = false
    @State var userSelectedContinue: Bool = false
    @State private var reticlePosition: CGPoint = CGPoint()
    var body: some View {
        ZStack {
            self.starHaven
            if !self.manager.userSelectedContinue {
                IntroScreen(userSelectedContinue: self.$userSelectedContinue).environmentObject(self.manager)
            }
        }
    }
    var starHaven: some View {
        ZStack {
            SpaceView()
                .gesture(DragGesture(minimumDistance: 0.001)
                .onChanged { value in
                    self.manager.handleDragChange(value: value)
                }
                .onEnded { _ in
                    self.manager.handleDragEnd()
                })
            HUD(manager: self.manager, OSNRMoonView: self)
        }.environmentObject(self.manager)
    }
}

struct SpaceView: UIViewRepresentable {
    @EnvironmentObject var manager: GameManager
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        let scnView = self.manager.sceneManager.view
        scnView.pointOfView = self.manager.cameraManager.cameraNode
        return scnView
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        
    }
    class Coordinator: NSObject, SCNPhysicsContactDelegate {
        var view: SpaceView

        init(_ view: SpaceView) {
            self.view = view
        }
    }
}
@MainActor struct HUD: View {
    @State var manager: GameManager
    @State var OSNRMoonView: OSNRMoonView
    var body: some View {
        self.HUD
    }
    var HUD: some View {
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
            .stroke(self.manager.shipManager.closestEnemy == nil ? Color.white : Color.red, lineWidth: 1)
            .frame(width: 20, height: 20).opacity(0.33)
    }
    var dynamicCamera: some View {
        VStack {
            Image(systemName: "camera").resizable().scaledToFit().frame(width: 100)
        }
    }
    var infoHUD: some View {
        VStack {
            HStack {
                self.settingsButton.padding(.horizontal)
                self.speedStack
                Spacer()
                self.gearStack
                Spacer()
                self.pointStack
            }
            .font(.custom("Avenir Next Regular", size: 24)).padding().foregroundColor(.red)
            Spacer()
        }
    }
    var settingsButton: some View {
        Image(systemName: "gear.circle.fill").resizable().scaledToFit().frame(width: UIScreen.main.bounds.height/10)
            .onTapGesture {
                self.OSNRMoonView.userSelectedSettings = true
            }
    }
    @State var points: Int = 0
    var pointStack: some View {
        VStack { Text("POINTS"); Text("\(self.points)") }.onChange(of: self.manager.points) { val in
            self.points = self.manager.points
        }
    }
    var speedStack: some View {
        VStack { Text("SPEED"); Text("\(Int(self.throttle * 10)) km/s") }
    }
    @State var gear: Int = 1
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
            if self.manager.gear == 4 {
                self.manager.gear = 1
                self.gear = 1
                self.throttle = min(self.throttle, Float(10*self.manager.gear))
            } else { self.manager.gear += 1; self.gear += 1 }
            
            self.manager.shipManager.throttle = self.throttle
            print("Tapped gear!")
        }
    }
    @State var throttle: Float = 0
    var mainHUD: some View {
        HStack {
            VStack {
                Spacer()
                CustomSlider(value: self.$throttle, range: -10 * Float(self.manager.gear)...10 * Float(self.manager.gear), onChange: { val in
                    self.manager.handleThrottle(value: val)
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
                self.manager.handleFireMissile()
                self.manager.fireCooldown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.manager.fireCooldown = false
                }
            }
        }) {
            Image(systemName: "flame")
                .resizable()
                .scaledToFit()
                .foregroundColor(self.manager.fireCooldown ? .gray : .red)
                .frame(width: UIScreen.main.bounds.height/6, height: UIScreen.main.bounds.height/6, alignment: .center)
        }.disabled(self.manager.fireCooldown)
        .foregroundColor(.white)
        .padding()
    }
    var scoreUpdates: some View {
        VStack {
            Spacer()
            if manager.showKillIncrement {
                Text("+10,000")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: self.manager.showKillIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                            self.manager.showKillIncrement = false
                        }
                    }
                Text("ENEMY DESTROYED")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: self.manager.showKillIncrement)
            }
            if manager.showScoreIncrement {
                Text("+\(Int(self.manager.shipManager.throttle) * 100 * 60)")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: self.manager.showScoreIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            self.manager.showScoreIncrement = false
                        }
                    }
            }
            Spacer()
            Spacer()
        }
    }
}

