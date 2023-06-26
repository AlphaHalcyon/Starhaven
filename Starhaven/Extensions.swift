//
//  Extensions.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//
import Foundation
import SwiftUI
import SceneKit
import Swift
import Metal
import simd

extension SCNNode {
    func rotate(toTargetVector target: SCNVector3, duration: TimeInterval) {
        // Calculate the rotation axis
        let nodePosition = self.presentation.position
        let toTarget = target - nodePosition
        let planeNormal = self.presentation.worldFront
        let rotationAxis = planeNormal.cross(toTarget)

        // Calculate the angle between the two vectors
        let dotProduct = simd_dot(
            simd_float3(planeNormal.x, planeNormal.y, planeNormal.z),
            simd_float3(toTarget.x, toTarget.y, toTarget.z)
        )
        let angle = atan2(rotationAxis.length(), dotProduct)

        // Create the rotation action and run it on the node
        let rotation = SCNAction.rotate(by: CGFloat(angle), around: rotationAxis.normalized(), duration: duration)
        self.runAction(rotation)
    }
    func rotateAroundAxis(by angle: CGFloat, axis: SCNVector3) {
        let rotation = SCNMatrix4MakeRotation(Float(angle), axis.x, axis.y, axis.z)
        let newTransform = SCNMatrix4Mult(self.transform, rotation)
        self.transform = newTransform
    }
}

extension SCNMatrix4 {
    func rotateAroundX(angle: Float) -> SCNMatrix4 {
        var matrix = self
        let rotationMatrix = SCNMatrix4MakeRotation(angle, 1, 0, 0)
        matrix = SCNMatrix4Mult(matrix, rotationMatrix)
        return matrix
    }

    func rotateAroundY(angle: Float) -> SCNMatrix4 {
        var matrix = self
        let rotationMatrix = SCNMatrix4MakeRotation(angle, 0, 1, 0)
        matrix = SCNMatrix4Mult(matrix, rotationMatrix)
        return matrix
    }

    func rotateAroundZ(angle: Float) -> SCNMatrix4 {
        var matrix = self
        let rotationMatrix = SCNMatrix4MakeRotation(angle, 0, 0, 1)
        matrix = SCNMatrix4Mult(matrix, rotationMatrix)
        return matrix
    }
}

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> CGFloat {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return CGFloat(sqrt(dx * dx + dy * dy + dz * dz))
    }
    static func != (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return !SCNVector3EqualToVector3(lhs, rhs)
    }
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    func crossProduct(_ vec: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            x: self.y * vec.z - self.z * vec.y,
            y: self.z * vec.x - self.x * vec.z,
            z: self.x * vec.y - self.y * vec.x
        )
    }
    func normalized() -> SCNVector3 {
        let len = length()
        return SCNVector3(x / len, y / len, z / len)
    }
    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    static func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    func cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            y * vector.z - z * vector.y,
            z * vector.x - x * vector.z,
            x * vector.y - y * vector.x
        )
    }
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }
}
extension UIColor {
    func lerp(to color: UIColor, alpha: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let r = r1 + (r2 - r1) * alpha
        let g = g1 + (g2 - g1) * alpha
        let b = b1 + (b2 - b1) * alpha
        let a = a1 + (a2 - a1) * alpha
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}
