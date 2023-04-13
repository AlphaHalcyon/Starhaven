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
        ZStack {
            self.space
            HUDView()
                .environmentObject(spacecraftViewModel)
        }
    }
    var space: some View {
        Space()
            .gesture(
                LongPressGesture(minimumDuration: 0.00001)
                    .onEnded { _ in
                        if !self.spacecraftViewModel.view.allowsCameraControl {
                            spacecraftViewModel.isPressed.toggle()
                            if spacecraftViewModel.isPressed {
                                spacecraftViewModel.startContinuousRotation()
                            } else {
                                spacecraftViewModel.stopContinuousRotation()
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !self.spacecraftViewModel.view.allowsCameraControl { spacecraftViewModel.dragChanged(value: value) }
                    }
                    .onEnded { _ in
                        if !self.spacecraftViewModel.view.allowsCameraControl { spacecraftViewModel.dragEnded() }
                    }
            )
            .environmentObject(spacecraftViewModel)
        //Slider(value: $spacecraftViewModel.ship.throttle, in: 0...10, step: 0.1)
    }
}
