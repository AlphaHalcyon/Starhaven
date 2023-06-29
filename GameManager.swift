//
//  GameManager.swift
//  Starhaven
//
//  Created by JxR on 6/9/23.
//

import Foundation
import SceneKit
import SwiftUI
import SwiftUI
import ARKit

struct ContentView: View {
    @StateObject var viewModel = GameViewModel()
    @State var userSelectedSettings: Bool = false
    @State var userSelectedContinue: Bool = false
    @State private var reticlePosition: CGPoint = CGPoint()
    @State var gear: Int = 1
    var body: some View {
        ZStack {
            self.starHaven
            if !self.userSelectedContinue {
                self.loadingScreen
            }
        }.onChange(of: self.viewModel.sceneManager.viewLoaded, perform: { val in print("here"); self.viewModel.sceneManager.viewLoaded = val })
    }
    var starHaven: some View {
        ZStack {
            SpaceView(viewModel: viewModel).gesture(DragGesture(minimumDistance: 0.001)
                .onChanged { value in
                    self.viewModel.handleDragChange(value: value)
                }
                .onEnded { _ in
                    self.viewModel.handleDragEnd()
                })
            self.HUD
        }
    }
    var loadingScreen: some View {
        IntroScreen(spaceViewModel: self.viewModel, userSelectedContinue: self.$userSelectedContinue)
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
            .stroke(self.viewModel.shipManager.closestEnemy == nil ? Color.white : Color.red, lineWidth: 1)
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
        VStack { Text("POINTS"); Text("\(self.viewModel.points)") }
    }
    var speedStack: some View {
        VStack { Text("SPEED"); Text("\(Int(self.throttle * 10)) km/s") }
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
                CustomSlider(value: self.$throttle, range: -1000 * Float(self.gear)...1000 * Float(self.gear), onChange: { val in
                    self.viewModel.handleThrottle(value: val)
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
                self.viewModel.handleFireMissile()
                self.viewModel.fireCooldown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.viewModel.fireCooldown = false
                }
            }
        }) {
            Image(systemName: "flame")
                .resizable()
                .scaledToFit()
                .foregroundColor(self.viewModel.fireCooldown ? .gray : .red)
                .frame(width: UIScreen.main.bounds.width/6, height: UIScreen.main.bounds.width/6, alignment: .center)
        }.disabled(self.viewModel.fireCooldown)
        .foregroundColor(.white)
        .padding()
    }
    var scoreUpdates: some View {
        VStack {
            Spacer()
            if viewModel.showKillIncrement {
                Text("+10,000")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.showKillIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                            viewModel.showKillIncrement = false
                        }
                    }
                Text("ENEMY DESTROYED")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.showKillIncrement)
            }
            if viewModel.showScoreIncrement {
                Text("+\(Int(self.viewModel.shipManager.throttle) * 100 * 60)")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.showScoreIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            viewModel.showScoreIncrement = false
                        }
                    }
            }
            Spacer()
            Spacer()
        }
    }

}
class GameViewModel: ObservableObject {
    @Published var sceneManager: SceneManager
    var cameraManager: CameraManager
    var physicsManager: PhysicsManager
    var shipManager: ShipManager
    var points: Int = 0
    var fireCooldown: Bool = false
    var showKillIncrement: Bool = false
    var showScoreIncrement: Bool = false
    init() {
        // Initialize the SCNScene, SCNView, Level, and other objects
        let level = Level(objects: [], collisionHandler: Level.DefaultCollisionHandler())
        let scene = SCNScene()
        let view = SCNView()
        // Initialize the managers
        self.physicsManager = PhysicsManager(scene: scene, view: view, level: level)
        self.shipManager = ShipManager(blackHoles: [])
        self.cameraManager = CameraManager(trackingState: CameraTrackState.player(ship: self.shipManager.ship), scene: scene, throttle: self.shipManager.throttle)
        self.sceneManager = SceneManager(cameraManager: cameraManager, shipManager: shipManager, scene: scene)
        self.sceneManager.viewLoaded = true
    }
    
    func handleDragChange(value: DragGesture.Value) {
        self.shipManager.dragChanged(value: value)
    }
    
    func handleDragEnd() {
        self.shipManager.dragEnded()
    }
    
    func handleThrottle(value: Float) {
        self.shipManager.throttle(value: value)
        self.cameraManager.throttle(value: value)
    }
    func handleFireMissile() {
        // Fire a missile at the current target
        self.shipManager.fireMissile(target: self.shipManager.hitTest())
    }
    
}

struct SpaceView: UIViewRepresentable {
    @State var viewModel: GameViewModel
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        let scnView = self.viewModel.sceneManager.view
        scnView.pointOfView = self.viewModel.cameraManager.cameraNode
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

