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
                Spacer()
                Text("POINTS: \(spacecraftViewModel.points)")
            }.foregroundColor(.red)
            Spacer()
            if spacecraftViewModel.isInverted {
                Text("INVERTED")
                    .foregroundColor(.red)
                    .bold()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            spacecraftViewModel.isInverted = false
                        }
                    }
            }
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
            Spacer()
            Reticle()
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
        }.padding()
    }
}
