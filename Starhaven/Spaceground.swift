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
            .overlay(
                HUDView()
                    .environmentObject(spacecraftViewModel)
            )
            .environmentObject(spacecraftViewModel)
        //Slider(value: $spacecraftViewModel.ship.throttle, in: 0...10, step: 0.1)
    }
}
