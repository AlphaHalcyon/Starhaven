//
//  ARView.swift
//  Starhaven
//
//  Created by JxR on 6/27/23.
//

import Foundation
import SwiftUI
import ARKit
import SceneKit

struct ARView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arView.session.run(configuration)
        
        // Set the view's delegate to receive AR session updates
        arView.session.delegate = context.coordinator
        
        // Store a reference to the ARSCNView in the coordinator
        context.coordinator.arSCNView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var arSCNView: ARSCNView?
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Loop through the added anchors
            for anchor in anchors {
                // Check if the anchor is a plane anchor
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    print("Processing plane anchor at center: \(planeAnchor.center)")
                    
                    // Create a BlackHole node at the anchor position
                    let blackHoleNode = BlackHole(scene: self.arSCNView!.scene, view: self.arSCNView!, radius: 0.5, camera: SCNNode(), ringCount: 10, vibeOffset: 1, bothRings: false, vibe: ShaderVibe.discOh, period: 10, shipNode: SCNNode()).blackHoleNode
                    
                    // Set the node's position
                    blackHoleNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z + 15)
                    
                    print("Created BlackHole node at position: \(blackHoleNode.position)")
                    
                    // Add the node to the scene
                    if let scene = arSCNView?.scene {
                        scene.rootNode.addChildNode(blackHoleNode)
                        print("Added BlackHole node to scene at position: \(blackHoleNode.position)")
                    } else {
                        print("Failed to add BlackHole node to scene!")
                    }
                }
            }
        }
    }
}

struct ContView: View {
    var body: some View {
        ARView()
            .edgesIgnoringSafeArea(.all)
    }
}
