//
//  GameManager.swift
//  Starhaven
//
//  Created by JxR on 6/9/23.
//

import Foundation
import SceneKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = GameViewModel()
    var body: some View {
        SpaceView(viewModel: viewModel).gesture(DragGesture()
            .onChanged { value in
                self.viewModel.handleDragChange(value: value)
            }
            .onEnded { _ in
                self.viewModel.handleDragEnd()
            })
    }
}
class GameViewModel: ObservableObject {
    @Published var sceneManager: SceneManager
    var cameraManager: CameraManager
    var physicsManager: PhysicsManager
    var shipManager: ShipManager
    
    init() {
        // Initialize the SCNScene, SCNView, Level, and other objects
        let level = Level(objects: [], collisionHandler: Level.DefaultCollisionHandler())
        let scene = SCNScene()
        let view = SCNView()
        // Initialize the managers
        self.physicsManager = PhysicsManager(scene: scene, view: view, level: level)
        self.shipManager = ShipManager(blackHoles: [])
        self.cameraManager = CameraManager(trackingState: CameraTrackState.player(ship: self.shipManager.ship), scene: scene)
        self.sceneManager = SceneManager(cameraManager: cameraManager, shipManager: shipManager)
        
    }
    
    func handleDragChange(value: DragGesture.Value) {
        self.shipManager.dragChanged(value: value)
    }
    
    func handleDragEnd() {
        self.shipManager.dragEnded()
    }
    
    func handleThrottle(value: Float) {
        self.shipManager.throttle(value: value)
    }
    
    func handleFireMissile() {
        // Fire a missile at the current target
        self.shipManager.fireMissile(target: self.shipManager.hitTest())
    }
}

struct SpaceView: UIViewRepresentable {
    var viewModel: GameViewModel
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
