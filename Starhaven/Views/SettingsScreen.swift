//
//  SettingsScreen.swift
//  Starhaven
//
//  Created by JxR on 6/11/23.
//

import Foundation
import SwiftUI

@MainActor struct SettingsScreen: View {
    unowned var spaceViewModel: SpacegroundViewModel
    @State var intensity: Double = 0.99
    
    @Binding var userSelectedSettings: Bool
    
    var settingsScreen: some View {
        VStack {
            Text("HVN")
                .font(.custom("Avenir Next Regular", size: 136)).foregroundColor(.red)
            Text("SETTINGS")
                .font(.custom("Avenir Next Bold", size: 50)).foregroundColor(.white)
            VStack {
                self.skyboxSettings
                self.distanceSettings
            }.padding()
        }.background(.black)
    }
    var skyboxSettings: some View {
        VStack {
            Text("Skybox Intensity").font(.custom("Avenir Next Regular", size: 35)).foregroundColor(.white)
            Slider(value: self.$intensity, in: 0...1) { value in
                self.spaceViewModel.setSkyboxIntensity(intensity: self.intensity)
            }.padding()
        }
    }
    @State var cameraDistance: Double = 75
    var distanceSettings: some View {
        VStack {
            Text("Camera Distance").font(.custom("Avenir Next Regular", size: 35)).foregroundColor(.white)
            Slider(value: self.$cameraDistance, in: 25...100) { value in
                self.spaceViewModel.setDistanceFromShip(distance: Float(self.cameraDistance))
            }.padding()
        }
    }
    @State var toggle3POV: Bool = false
    var POVSettings: some View {
        HStack {
            Text("Enable 3rd Person").font(.custom("Avenir Next Regular", size: 35)).foregroundColor(.white)
            Circle().foregroundColor(self.toggle3POV ? .green : .red).onTapGesture {
                //self.spaceViewModel.toggleThirdPerson()
            }
        }
    }
    var body: some View {
        VStack {
            self.settingsScreen
            Spacer()
            Text("BACK").onTapGesture {
                self.userSelectedSettings = false
            }.font(.custom("Avenir Next Bold", size: 50)).foregroundColor(.red).padding()
        }.background(.black)
    }
}
