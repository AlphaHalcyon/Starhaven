//
//  Space.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI
import AVFoundation

struct Space: UIViewRepresentable {
    @EnvironmentObject var spaceViewModel: SpacegroundViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        let scnView = self.spaceViewModel.makeSpaceView()
        self.spaceViewModel.setupPhysics()
        self.spaceViewModel.view.pointOfView = self.spaceViewModel.cameraNode
        return scnView
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        
    }
    @MainActor class Coordinator: NSObject, SCNPhysicsContactDelegate {
        var view: Space

        init(_ view: Space) {
            self.view = view
        }
    }
}

