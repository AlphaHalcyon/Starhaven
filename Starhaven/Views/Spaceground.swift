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
    @StateObject var spacecraftViewModel = SpacegroundViewModel(view: SCNView(), cameraNode: SCNNode())
    var body: some View {
        if self.spacecraftViewModel.gameOver {
            Text("GAME OVER! SCORE: \(self.spacecraftViewModel.points)")
                .multilineTextAlignment(.center).font(.custom("Avenir Next Regular", size: 50))
        }
        else {
            ZStack {
                self.space
                if self.spacecraftViewModel.loadingSceneView {
                    self.loadScreen
                }
                else {
                    HUDView().environmentObject(spacecraftViewModel)
                }
            }
        }
    }
    var loadScreen: some View {
        ZStack {
            Image("sky").resizable().frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
            VStack {
                Spacer()
                Image("Launch").resizable().scaledToFit()
                Spacer()
            }
            Text("HVN").font(.custom("Avenir Next Regular", size: 136)).foregroundColor(.white)
        }
    }
    var space: some View {
        Space()
            .gesture(
                LongPressGesture(minimumDuration: 0.0001)
                    .onChanged { value in
                        if value {
                            if !self.spacecraftViewModel.view.allowsCameraControl {
                                self.spacecraftViewModel.isPressed = true
                                self.spacecraftViewModel.isDragging = true
                            }
                        } else {
                            if !self.spacecraftViewModel.view.allowsCameraControl {
                                self.spacecraftViewModel.isPressed = false
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0.0001)
                    .onChanged { value in
                        if !self.spacecraftViewModel.view.allowsCameraControl {
                            self.spacecraftViewModel.dragChanged(value: value)
                        }
                    }
                    .onEnded { _ in
                        if !self.spacecraftViewModel.view.allowsCameraControl {
                            spacecraftViewModel.dragEnded()
                        }
                    }
            )
            .environmentObject(spacecraftViewModel)
    }
}
