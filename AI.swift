//
//  AI.swift
//  Starhaven
//
//  Created by JxR on 6/20/23.
//

import Foundation
import SceneKit

class AI: SceneObject {
    var node: SCNNode
    var action: AIAction?
    
    required init(node: SCNNode) {
        self.node = node
    }
    func destroy() {
    }
    func update() {
        self.action?.execute()
    }
}
protocol AIAction {
    func execute()
}


