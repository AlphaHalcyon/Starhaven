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

@MainActor struct ContentView: View {
    @StateObject var spacecraftViewModel = SpacegroundViewModel(view: SCNView(), cameraNode: SCNNode())
    @State var userSelectedContinue: Bool = false
    @State var userSelectedSettings: Bool = false
    var body: some View {
        if self.spacecraftViewModel.gameOver {
            Text("GAME OVER! SCORE: \(self.spacecraftViewModel.points)")
                .multilineTextAlignment(.center).font(.custom("Avenir Next Regular", size: 50))
        }
        else {
            ZStack {
                self.space
                if !self.userSelectedContinue {
                    LoadingScreen(spaceViewModel: self.spacecraftViewModel, userSelectedContinue: self.$userSelectedContinue)
                }
                else if self.userSelectedSettings {
                    SettingsScreen(spaceViewModel: self.spacecraftViewModel, userSelectedSettings: self.$userSelectedSettings)
                }
                else {
                    HUDView(spaceViewModel: self.spacecraftViewModel, userSelectedSettings: $userSelectedSettings)
                }
            }
        }
    }
    
    var space: some View {
        Space()
            .gesture(
                LongPressGesture(minimumDuration: 0.001)
                    .onChanged { value in
                        if self.spacecraftViewModel.isDragging {
                            self.spacecraftViewModel.isPressed = false
                            self.spacecraftViewModel.dragEnded()
                        } else {
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
