//
//  CustomTorus.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//
import Foundation
import SwiftUI
import SceneKit
import Swift
import UIKit
import simd

class CustomTorus: SCNNode {
    private let torusGeometry: SCNGeometry
    
    override var geometry: SCNGeometry? {
        get { torusGeometry }
        set { fatalError("You cannot set the geometry of CustomTorus.") }
    }

    init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) {
        let lowDetailGeometry = CustomTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: 10, ringSegments: 10)
        let mediumDetailGeometry = CustomTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: 20, ringSegments: 20)
        let highDetailGeometry = CustomTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: 40, ringSegments: 40)

        let lowDetailLOD = SCNLevelOfDetail(geometry: lowDetailGeometry, screenSpaceRadius: 100)
        let mediumDetailLOD = SCNLevelOfDetail(geometry: mediumDetailGeometry, screenSpaceRadius: 50)
        let highDetailLOD = SCNLevelOfDetail(geometry: highDetailGeometry, screenSpaceRadius: 0)
        self.torusGeometry = CustomTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments)
        self.torusGeometry.levelsOfDetail = [lowDetailLOD, mediumDetailLOD, highDetailLOD]
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func buildTorusGeometry(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) -> SCNGeometry {
            let vertexCount = radialSegments * ringSegments
            let indexCount = radialSegments * ringSegments * 6

            var vertices: [SCNVector3] = []
            var normals: [SCNVector3] = []
            var indices: [UInt16] = []

            let rotationAngle = CGFloat(0).degreesToRadians

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
                    let rotatedY = y * cos(rotationAngle) - z * sin(rotationAngle)
                    let rotatedZ = y * sin(rotationAngle) + z * cos(rotationAngle)

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

class LensingTorus: SCNNode {
    public let torusGeometry: SCNGeometry
    
    override var geometry: SCNGeometry? {
        get { torusGeometry }
        set { fatalError("You cannot set the geometry of CustomTorus.") }
    }
    
    public init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) {
        self.torusGeometry = LensingTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments)
        let lowDetailGeometry = LensingTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: 10, ringSegments: 10)
        let mediumDetailGeometry = LensingTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: 20, ringSegments: 20)
        let highDetailGeometry = LensingTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: 40, ringSegments: 40)

        let lowDetailLOD = SCNLevelOfDetail(geometry: lowDetailGeometry, screenSpaceRadius: 100)
        let mediumDetailLOD = SCNLevelOfDetail(geometry: mediumDetailGeometry, screenSpaceRadius: 50)
        let highDetailLOD = SCNLevelOfDetail(geometry: highDetailGeometry, screenSpaceRadius: 0)
        self.torusGeometry.levelsOfDetail = [lowDetailLOD, mediumDetailLOD, highDetailLOD]
        super.init()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func buildTorusGeometry(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) -> SCNGeometry {
        let vertexCount = radialSegments * ringSegments
        let indexCount = radialSegments * ringSegments * 6

        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [UInt16] = []

        let offsetAngle = CGFloat(90).degreesToRadians

        for radIndex in 0..<radialSegments {
            for pipeIndex in 0..<ringSegments {
                let u = CGFloat(radIndex) / CGFloat(radialSegments)
                let v = CGFloat(pipeIndex) / CGFloat(ringSegments)

                let theta = 2.0 * CGFloat.pi * u
                let phi = 2.0 * CGFloat.pi * v

                let centerX = radius * cos(theta + offsetAngle)
                let centerY = radius * sin(theta + offsetAngle)

                let x = (radius + ringRadius * cos(phi)) * cos(theta) - centerX
                let y = (radius + ringRadius * cos(phi)) * sin(theta) - centerY
                let z = ringRadius * sin(phi)

                let normal = SCNVector3(x + centerX, y + centerY, z)

                vertices.append(SCNVector3(x, y, z))
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

class LensedTorus: SCNNode {
    public let torusGeometry: SCNGeometry
    
    override var geometry: SCNGeometry? {
        get { torusGeometry }
        set { fatalError("You cannot set the geometry of CustomTorus.") }
    }
    
    public init(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) {
        self.torusGeometry = LensedTorus.buildTorusGeometry(radius: radius, ringRadius: ringRadius, radialSegments: radialSegments, ringSegments: ringSegments)
        super.init()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private static func buildTorusGeometry(radius: CGFloat, ringRadius: CGFloat, radialSegments: Int, ringSegments: Int) -> SCNGeometry {
        let vertexCount = radialSegments * ringSegments
        let indexCount = radialSegments * ringSegments * 6

        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [UInt16] = []

        let offsetAngle = CGFloat(180).degreesToRadians

        for radIndex in 0..<radialSegments {
            for pipeIndex in 0..<ringSegments {
                let u = CGFloat(radIndex) / CGFloat(radialSegments)
                let v = CGFloat(pipeIndex) / CGFloat(ringSegments)

                let theta = 2.0 * CGFloat.pi * u
                let phi = 2.0 * CGFloat.pi * v

                let centerX = radius * cos(theta + offsetAngle)
                let centerY = radius * sin(theta + offsetAngle)

                let x = (radius + ringRadius * cos(phi)) * cos(theta) - centerX
                let y = (radius + ringRadius * cos(phi)) * sin(theta) - centerY
                let z = ringRadius * sin(phi)

                let normal = SCNVector3(x + centerX, y + centerY, z)

                vertices.append(SCNVector3(x, y, z))
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

extension CGFloat {
    var degreesToRadians: CGFloat {
        return self * .pi / 180.0
    }
}
