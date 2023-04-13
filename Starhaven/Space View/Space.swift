//
//  Space.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

struct Space: UIViewRepresentable {
    @EnvironmentObject var spaceViewModel: SpacecraftViewModel
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        return self.spaceViewModel.makeSpaceView()
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // ...
    }

    class Coordinator: NSObject {
        var view: Space

        init(_ view: Space) {
            self.view = view
        }
    }
}
