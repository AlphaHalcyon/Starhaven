//
//  BH.swift
//  Starhaven
//
//  Created by Jared on 7/9/23.
//

import Foundation
import SwiftUI
import SceneKit

class BH {
    init(){}
    static let numRings: Int = 12
    static let radius: CGFloat = 80
    static let pipeRadius: CGFloat = 10
    static func blackHole(pov: SCNNode) -> SCNNode {
        let node = BH.blackHoleNode
        let lensedRootNode = SCNNode()
        node.addChildNode(lensedRootNode)
        for i in 1..<BH.numRings {
            let mods = BH.gravitationalLensingShaderModifiers(currentRing: i, totalRings: BH.numRings, vibe: ShaderVibe.discOh)
            let torus = BH.accretionRing(radius: BH.radius + BH.pipeRadius + CGFloat(i) * BH.pipeRadius)
            let customTorus = BH.lensedRing(radius: BH.radius + BH.pipeRadius + CGFloat(i) * BH.pipeRadius)
            torus.geometry?.shaderModifiers = mods
            customTorus.geometry?.shaderModifiers = mods
            node.addChildNode(torus)
            lensedRootNode.addChildNode(customTorus)
        }
        // Rotations
        node.runAction(BH.mainRotation)
        node.simdOrientation = simd_quatf(angle: .pi/2, axis: simd_float3(x: 0, y: 1, z: 0))
        let lensingConstraint = SCNLookAtConstraint(target: pov)
        lensedRootNode.constraints = [lensingConstraint]
        return node
    }
    static func accretionRing(radius: CGFloat) -> SCNNode {
        let accretionRingGeometry = BH.ringGeometry(radius: radius)
        let accretionRingNode = SCNNode(geometry: accretionRingGeometry)
        return accretionRingNode
    }
    static func lensedRing(radius: CGFloat) -> SCNNode {
        let lensedRingGeometry = BH.lensedRingGeometry(radius: radius)
        let lensedRingNode = SCNNode(geometry: lensedRingGeometry)
        return lensedRingNode
    }
    static func ringGeometry(radius: CGFloat) -> SCNTorus {
        return SCNTorus(ringRadius: radius, pipeRadius: BH.pipeRadius)
    }
    static func lensedRingGeometry(radius: CGFloat) -> SCNGeometry {
        return CustomTorus(radius: radius, ringRadius: BH.pipeRadius, radialSegments: 30, ringSegments: 30).torusGeometry
    }
    static let blackHoleNode: SCNNode = {
        let sphere = BH.mainSphere
        let node = SCNNode(geometry: sphere)
        return node
    }()
    static let mainSphere: SCNSphere = {
        let sphere = SCNSphere(radius: BH.radius)
        let blackHoleMaterial = BH.sphereMaterial
        sphere.materials = [blackHoleMaterial]
        return sphere
    }()
    static let sphereMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        material.lightingModel = .constant
        return material
    }()
    static let mainRotation: SCNAction = {
        let action = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10))
        return action
    }()
}

extension BH {
    static func gravitationalLensingShaderModifiers(currentRing: Int, totalRings: Int = 15, vibe: String) -> [SCNShaderModifierEntryPoint: String] {
        let randFloat: Float = Float.random(in: 0.0...1)
        let fragmentShaderCode = """
            float3 color = _surface.diffuse.rgb;
            float t = float(\(currentRing)) / float(\(totalRings));
            t = t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
            
            float3 red = float3(250.0 / 255.0, 9.0 / 255.0, 5.0 / 255.0);
            float3 orange = float3(220.0 / 255.0, 80.0 / 255.0, 30.0 / 255.0);
            float3 orange2 = float3(250.0 / 255.0, 120.0 / 255.0, 50.0 / 255.0);
            float3 gold = float3(213.0 / 255.0, 65.0 / 255.0, 26.0 / 255.0);
            float3 gold2 = float3(232.0 / 255.0, 89.0 / 255.0, 32.0 / 255.0);
            float3 gold3 = float3(240.0 / 255.0, 95.0 / 255.0, 35.0 / 255.0);
            float3 green = float3(5.0 / 255.0, 9.0 / 255.0, 5.0 / 255.0);
            float3 blue = float3(5.0 / 255.0, 5.0 / 255.0, 250.0 / 255.0);
            float3 purple = float3(120.0 / 255.0, 0.0 / 255.0, 250.0 / 255.0);
            
            \(vibe)
            if (float(\(randFloat)) > 0.95) {
                color = red;
            }
            
            _output.color.rgb = color;
            
            """
        
        return [.geometry: String(), .fragment: fragmentShaderCode]
    }
}
