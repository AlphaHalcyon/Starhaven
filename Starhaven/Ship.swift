//
//  Ship.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit

class Ship: ObservableObject {
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
}
