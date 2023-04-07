//
//  VelocityBuffer.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit

class VelocityBuffer {
    let bufferCapacity: Int
    var velocities: [CGFloat]
    var weights: [CGFloat]
    
    init(bufferCapacity: Int) {
        self.bufferCapacity = bufferCapacity
        self.velocities = []
        self.weights = []
        
        for i in 0..<bufferCapacity {
            self.weights.append(CGFloat(bufferCapacity - i))
        }
    }
    
    func addVelocity(_ velocity: CGFloat) {
        if velocities.count >= bufferCapacity {
            velocities.removeFirst()
        }
        
        velocities.append(velocity)
    }
    
    func weightedAverageVelocity() -> CGFloat {
        var weightedSum: CGFloat = 0
        var totalWeight: CGFloat = 0
        
        for i in 0..<velocities.count {
            let weight = weights[i]
            let velocity = velocities[i]
            
            weightedSum += weight * velocity
            totalWeight += weight
        }
        
        return weightedSum / totalWeight
    }
}
