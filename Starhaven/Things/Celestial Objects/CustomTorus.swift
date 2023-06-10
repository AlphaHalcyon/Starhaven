//
//  CustomTorus.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//

import Foundation
import SwiftUI
import SceneKit
import simd

class BaseTorus: SCNNode {
    private(set) var torusGeometry: SCNGeometry
    
    override var geometry: SCNGeometry? {
        get { torusGeometry }
        set { fatalError("You cannot set the geometry of BaseTorus.") }
    }
    
    init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int, offsetAngle: CGFloat) {
        self.torusGeometry = BaseTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments, offsetAngle: offsetAngle)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func buildTorusGeometry(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int, offsetAngle: CGFloat) -> SCNGeometry {
        let vertexCount = radialSegments * ringSegments
        let indexCount = radialSegments * ringSegments * 6

        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [UInt16] = []

        for radIndex in 0..<radialSegments {
            for pipeIndex in 0..<ringSegments {
                let u = CGFloat(radIndex) / CGFloat(radialSegments)
                let v = CGFloat(pipeIndex) / CGFloat(ringSegments)

                let theta = 2.0 * CGFloat.pi * u
                let phi = 2.0 * CGFloat.pi * v

                let x = (radius + ringRadius * cos(phi)) * cos(theta)
                let y = (radius + ringRadius * cos(phi)) * sin(theta)
                let z = ringRadius * sin(phi)

                let rotatedX = x
                let rotatedY = y * cos(offsetAngle) - z * sin(offsetAngle)
                let rotatedZ = y * sin(offsetAngle) + z * cos(offsetAngle)

                let normal = SCNVector3(rotatedX - radius * cos(theta), rotatedY - radius * sin(theta), rotatedZ)

                vertices.append(SCNVector3(rotatedX, rotatedY, rotatedZ))
                normals.append(normal.normalized())
            }
        }

        for radIndex in 0..<radialSegments {
            for pipeIndex in 0..<ringSegments {
                let index1 = UInt16((radIndex * ringSegments + pipeIndex) % vertexCount)
                let index2 = UInt16(((radIndex + 1) * ringSegments + pipeIndex) % vertexCount)
                let index3 = UInt16(((radIndex + 1) * ringSegments + (pipeIndex + 1)) % vertexCount)
                let index4 = UInt16((radIndex * ringSegments + (pipeIndex + 1)) % vertexCount)

                indices.append(contentsOf: [index1, index2, index3, index1, index3, index4])
            }
        }

        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let indexData = Data(bytes: indices, count: indexCount * MemoryLayout<UInt16>.size)
        let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: indexCount / 3, bytesPerIndex: MemoryLayout<UInt16>.size)

        return SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
    }
}

class CustomTorus: BaseTorus {
    init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) {
        super.init(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments, offsetAngle: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LensingTorus: BaseTorus {
    init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) {
        super.init(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments, offsetAngle: CGFloat(90).degreesToRadians)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LensedTorus: BaseTorus {
    init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) {
        super.init(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments, offsetAngle: CGFloat(180).degreesToRadians)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat {
        return self * .pi / 180.0
    }
}
