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

@MainActor struct CntentView: View {
    @StateObject var spacecraftViewModel = SpacegroundViewModel(view: SCNView(), cameraNode: SCNNode())
    @State var userSelectedContinue: Bool = false // THE USER WOULD LIKE TO BEGIN
    @State var userSelectedSettings: Bool = false // THE USER WANTS THE SETTINGS MENU
    @State var skyboxIntensity: Double = 0.75 // THE BRIGHTNESS OF THE STARS n SKYBOX
    @State var cameraDistance: Double = 75 // CAMERA FOLLOWS SHIP AT THIS DISTANCE
    var settings: some View {
        SettingsScreen(spaceViewModel: self.spacecraftViewModel, intensity: $skyboxIntensity, cameraDistance: $cameraDistance, userSelectedSettings: self.$userSelectedSettings)
    }
    var hud: some View {
        HUDView(spaceViewModel: self.spacecraftViewModel, userSelectedSettings: self.$userSelectedSettings)
    }
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
                    self.settings
                }
                else {
                    self.hud
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
