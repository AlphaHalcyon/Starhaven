//
//  Spaceground.swift
//  Starhaven
//
//  Created by JxR on 4/4/23.
//

import Foundation
import SwiftUI
import SceneKit
import simd

struct ContentView: View {
    var body: some View {
        VStack {
            SpacecraftView()
        }
    }
}
struct SpacecraftView: View {
    @StateObject var spacecraftViewModel = SpacecraftViewModel()

    var body: some View {
        Space()
            .gesture(
                LongPressGesture(minimumDuration: 0.01)
                    .onEnded { _ in
                        spacecraftViewModel.isPressed.toggle()
                        if spacecraftViewModel.isPressed {
                            spacecraftViewModel.startContinuousRotation()
                        } else {
                            spacecraftViewModel.stopContinuousRotation()
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        spacecraftViewModel.dragChanged(value: value)
                    }
                    .onEnded { _ in
                        spacecraftViewModel.dragEnded()
                    }
            )
            .overlay(
                HUDView()
                    .environmentObject(spacecraftViewModel)
            )
            .environmentObject(spacecraftViewModel)
        Slider(value: $spacecraftViewModel.ship.throttle, in: 0...10, step: 0.1)
            .padding()
    }
}
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
