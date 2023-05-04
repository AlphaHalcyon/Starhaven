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
        Spaceground()
    }
}
struct Spaceground: View {
    @StateObject var spacecraftViewModel = SpacegroundViewModel()
    var body: some View {
        ZStack {
            self.space
            if self.spacecraftViewModel.loadingSceneView {
                self.loadScreen
            }
            else {
                HUDView().environmentObject(spacecraftViewModel)
            }
        }.onChange(of: self.spacecraftViewModel.loadingSceneView, perform: { val in
            self.spacecraftViewModel.startWorldTimer()
        })
    }
    var loadScreen: some View {
        ZStack {
            Image("sky").resizable().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
            VStack {
                Spacer()
                Image("Launch").resizable().scaledToFit()
                Spacer()
            }
            Text("HVN").font(.custom("Avenir Next Regular", size: 136))
        }
    }
    var space: some View {
        Space()
            .gesture(
                LongPressGesture(minimumDuration: 0.0001)
                    .onEnded { _ in
                        if !self.spacecraftViewModel.view.allowsCameraControl {
                            spacecraftViewModel.isPressed.toggle()
                            if spacecraftViewModel.isPressed {
                                spacecraftViewModel.startContinuousRotation()
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0.0001)
                    .onChanged { value in
                        if !self.spacecraftViewModel.view.allowsCameraControl {
                            spacecraftViewModel.dragChanged(value: value) }
                    }
                    .onEnded { _ in
                        if !self.spacecraftViewModel.view.allowsCameraControl { spacecraftViewModel.dragEnded() }
                    }
            ).environmentObject(spacecraftViewModel)
    }
}
