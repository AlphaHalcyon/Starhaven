//
//  Star.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

class Star {
    var starNode: SCNNode
    
    init(radius: CGFloat, color: UIColor) {
        let starGeometry = SCNSphere(radius: radius)
        
        // Create a material for the star
        let starMaterial = SCNMaterial()
        
        // Set the base color of the star
        starMaterial.diffuse.contents = color
        
        // Add an emission property to make the star glow
        starMaterial.emission.contents = color
        
        // Apply the material to the star geometry
        starGeometry.materials = [starMaterial]
        
        // Create the star node and set its geometry
        starNode = SCNNode(geometry: starGeometry)

        let pulseAnimation = CABasicAnimation(keyPath: "emission.intensity")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 0.0
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude

        starMaterial.addAnimation(pulseAnimation, forKey: "pulse")
    }
}

