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

class GameManager: ObservableObject {
    let sceneManager: SceneManager
    let cameraManager: CameraManager
    let shipManager: ShipManager
    @Published var points: Int = 0
    @Published var kills: Int = 0
    @Published var fireCooldown: Bool = false
    @Published var showKillIncrement: Bool = false
    @Published var showScoreIncrement: Bool = false
    @Published var gear: Int = 1
    
    init() {
        // Initialize the SCNScene, SCNView, Level, and other objects
        let level = Level(objects: [], collisionHandler: Level.DefaultCollisionHandler())
        let scene = SCNScene()
        let view = SCNView()
        // Initialize the managers
        self.shipManager = ShipManager()
        self.cameraManager = CameraManager(trackingState: CameraTrackState.player(ship: self.shipManager.ship), scene: scene, throttle: self.shipManager.throttle)
        self.sceneManager = SceneManager(cameraManager: cameraManager, shipManager: shipManager, scene: scene)
        self.sceneManager.viewLoaded = true
        self.sceneManager.gameManager = self
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
        self.fireMissile(target: self.shipManager.hitTest(), particleSystemColor: .systemPink)
    }
    // WEAPONS
    func fireMissile(target: SCNNode? = nil, particleSystemColor: UIColor) {
        let missile: OSNRMissile
        if self.sceneManager.missiles.isEmpty {
            missile = OSNRMissile(target: target, particleSystemColor: particleSystemColor, sceneManager: self.sceneManager)
            self.fire(missile: missile.missileNode)
        } else if let missile = self.sceneManager.missiles.popLast() {
            missile.target = target
            missile.faction = .Phantom
            missile.particleSystem.particleColor = particleSystemColor
            self.fire(missile: missile.missileNode)
            missile.fire()
        }
    }
    func fire(missile: SCNNode) {
        missile.position = self.shipManager.ship.position - SCNVector3(0, -1, 1)
        missile.physicsBody?.velocity = SCNVector3(0,0,0)
        missile.simdOrientation = self.shipManager.ship.simdOrientation
        let direction = self.shipManager.ship.presentation.worldFront
        let missileMass = missile.physicsBody?.mass ?? 1
        missile.eulerAngles.x += Float.pi / 2
        let missileForce = 500 * missileMass
        self.sceneManager.addNode(missile)
        DispatchQueue.main.async {
            missile.physicsBody?.applyForce(direction * Float(missileForce), asImpulse: true)
        }
    }
}

@MainActor struct OSNRMoonView: View {
    @StateObject var manager = GameManager()
    @State var userSelectedSettings: Bool = false
    @State var userSelectedContinue: Bool = false
    @State private var reticlePosition: CGPoint = CGPoint()
    var body: some View {
        ZStack {
            self.starHaven
            if !self.userSelectedContinue {
                self.loadingScreen
            }
        }.onChange(of: self.manager.sceneManager.viewLoaded, perform: { val in print("here"); self.manager.sceneManager.viewLoaded = val })
    }
    var starHaven: some View {
        ZStack {
            SpaceView(manager: manager).gesture(DragGesture(minimumDistance: 0.001)
                .onChanged { value in
                    self.manager.handleDragChange(value: value)
                }
                .onEnded { _ in
                    self.manager.handleDragEnd()
                })
            HUD(manager: self.manager, OSNRMoonView: self)
        }
    }
    var loadingScreen: some View {
        IntroScreen(spaceViewModel: self.manager, userSelectedContinue: self.$userSelectedContinue)
    }
}

struct SpaceView: UIViewRepresentable {
    @State var manager: GameManager
    init(manager: GameManager) {
        self.manager = manager
    }

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
