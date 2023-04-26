//
//  Reticle.swift
//  Starhaven
//
//  Created by JxR on 4/10/23.
//

import Foundation
import SwiftUI
import SceneKit

struct Reticle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let innerRadius: CGFloat = 5
        let outerRadius: CGFloat = 15

        let points = [
            CGPoint(x: center.x, y: center.y - innerRadius),
            CGPoint(x: center.x, y: center.y - outerRadius),
            CGPoint(x: center.x, y: center.y + innerRadius),
            CGPoint(x: center.x, y: center.y + outerRadius),
            CGPoint(x: center.x - innerRadius, y: center.y),
            CGPoint(x: center.x - outerRadius, y: center.y),
            CGPoint(x: center.x + innerRadius, y: center.y),
            CGPoint(x: center.x + outerRadius, y: center.y),
        ]

        path.move(to: points[0])
        path.addLine(to: points[1])
        path.move(to: points[2])
        path.addLine(to: points[3])
        path.move(to: points[4])
        path.addLine(to: points[5])
        path.move(to: points[6])
        path.addLine(to: points[7])

        return path
    }
}
