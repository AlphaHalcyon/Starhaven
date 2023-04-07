//
//  SpaceView.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//

import Foundation
import SwiftUI
import SceneKit

struct ThrottleView: UIViewRepresentable {
    @Binding var throttleValue: Float
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .gray
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(gesture:)))
        view.addGestureRecognizer(panGesture)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ThrottleView
        
        init(_ parent: ThrottleView) {
            self.parent = parent
        }
        
        @objc func handlePan(gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            let normalizedTranslation = max(0, min(1, -translation.y / 100))
            parent.throttleValue = Float(normalizedTranslation)
        }
    }
}

struct SpaceView: UIViewRepresentable {
    @EnvironmentObject var viewModel: SpaceViewModel
    @State private var xRotation: Float = 0
    @State private var yRotation: Float = 0
    @Binding var throttleValue: Float
    @State private var joystickAngle: Float = 0
    
    @State var timer: Timer = Timer()
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        viewModel.initializeSpace()
        view.scene = viewModel.scene
        view.prepare(view.scene)
        view.backgroundColor = UIColor.black
        
        // Start updating the node's position
        startUpdatingNodePosition()
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        print("updating!")
        self.viewModel.pilot.update(throttleValue: self.throttleValue, joystickAngle: self.joystickAngle)
    }
    
    func startUpdatingNodePosition() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            // Call the updateCameraVelocity() method here
            self.viewModel.pilot.updateCameraVelocity()
        }
    }

    func stopUpdatingNodePosition() {
        timer.invalidate()
    }
}
