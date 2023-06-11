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
@MainActor struct Spaceground: View {
    @StateObject var spacecraftViewModel = SpacegroundViewModel(view: SCNView(), cameraNode: SCNNode())
    @State var userSelectedContinue: Bool = false
    var body: some View {
        if self.spacecraftViewModel.gameOver {
            Text("GAME OVER! SCORE: \(self.spacecraftViewModel.points)")
                .multilineTextAlignment(.center).font(.custom("Avenir Next Regular", size: 50))
        }
        else {
            ZStack {
                self.space
                if !self.userSelectedContinue {
                    self.loadScreen
                }
                else {
                    HUDView().environmentObject(spacecraftViewModel)
                }
            }
        }
    }
    var loadScreen: some View {
        VStack(spacing: 15) {
            Text("HVN")
                .font(.custom("Avenir Next Regular", size: 136)).foregroundColor(self.spacecraftViewModel.loadingSceneView ? .gray : .red)
            Spacer()
            Text("The Office of Stellar-Naval Research has instructed you to harvest a rogue system of black holes in Messier 87's 'Starhaven' region.").multilineTextAlignment(.center).font(.body).foregroundColor(.white)
            Text("Other factions are dueling for control of the region and its contents. They will be distracted with each other; engage them at your own risk, and earn points for destroying them.").multilineTextAlignment(.center).font(.body).foregroundColor(.white)
            Text("Collect all the black holes in the area by flying directly into them to earn points. Your Higgs Decoupling Drive should render your ship massless and safe.").multilineTextAlignment(.center).font(.body).foregroundColor(.white)
            Spacer()
            Text("CONTINUE")
                .font(.custom("Avenir Next Regular", size: 50))
                .foregroundColor(self.spacecraftViewModel.loadingSceneView ? .gray : .red)
                .onTapGesture {
                    if !self.spacecraftViewModel.loadingSceneView { self.userSelectedContinue = true }
                }.padding()
            Spacer()
            // PRACTICE YOUR BARREL ROLLS
            Text("Tip: \(self.generateTip())")
                .font(.custom("Avenir Next Italic", size: 21))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack { Spacer() }
        }.background(.black)
    }
    func generateTip() -> String {
        return "Remember to practice your barrel rolls!"
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
