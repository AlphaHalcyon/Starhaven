//
//  HUD.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SceneKit
import SwiftUI

struct HUDView: View {
    @EnvironmentObject var spacecraftViewModel: SpacecraftViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Yaw: \(spacecraftViewModel.ship.yaw, specifier: "%.2f")")
                Spacer()
                Text("Pitch: \(spacecraftViewModel.ship.pitch, specifier: "%.2f")")
                Spacer()
                Text("Roll: \(spacecraftViewModel.ship.roll, specifier: "%.2f")")
            }
            .foregroundColor(.blue)
            HStack {
                Text("FREE CAM").onTapGesture {
                    self.spacecraftViewModel.view.allowsCameraControl = true
                    self.spacecraftViewModel.cameraNode.constraints = []
                }
                if self.spacecraftViewModel.isInverted {
                    Text("INVERTED")
                        .foregroundColor(.red)
                        .bold()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                spacecraftViewModel.isInverted = false
                            }
                        }
                }
                Spacer()
                Text("POINTS: \(spacecraftViewModel.points)")
            }.foregroundColor(.red)
            Spacer()
            if spacecraftViewModel.showScoreIncrement {
                Text("+100")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: spacecraftViewModel.showScoreIncrement)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            spacecraftViewModel.showScoreIncrement = false
                        }
                    }
            }
            Reticle()
                .frame(width: 30, height: 30)
                .foregroundColor(.red)
            Spacer()
            HStack {
                Text("REVERSE").gesture(LongPressGesture().onChanged { value in
                    self.spacecraftViewModel.throttle(value: self.spacecraftViewModel.ship.throttle + 1.0)
                }).foregroundColor(.white)
                Text("THROTTLE").gesture(LongPressGesture().onChanged { value in
                    self.spacecraftViewModel.throttle(value: self.spacecraftViewModel.ship.throttle - 1.0)
                }).foregroundColor(.white)
            }
        }.padding()
    }
}
