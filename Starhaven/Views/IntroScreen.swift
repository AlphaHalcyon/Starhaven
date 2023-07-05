//
//  IntroScreen.swift
//  Starhaven
//
//  Created by JxR on 6/21/23.
//

import Foundation
//
//  LoadingScreen.swift
//  Starhaven
//
//  Created by JxR on 6/11/23.
//

import Foundation
import SwiftUI

struct IntroScreen: View {
    unowned var spaceViewModel: GameManager
    @Binding var userSelectedContinue: Bool
    var body: some View {
        self.loadScreen
    }
    var loadScreen: some View {
        VStack {
            Text("HVN")
                .font(.custom("Avenir Next Regular", size: 136)).foregroundColor(.red).padding()
            Text("The OFFICE of STELLAR-NAVAL RESEARCH has DEFENSIVE INSTALLATIONS on the SURFACE of PERSEPHONE, a small MOON of the WATER PLANET CIRCE. These installations ARE UNDER THE CONTROL of the ENEMY'S DRONE SYSTEMS. DESTROY ALL OF THEM.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).font(.custom("Avenir Next Bold", size: 16)).foregroundColor(.gray)
            if !self.spaceViewModel.sceneManager.viewLoaded { self.loading } else {
                self.continueButton
            }
            Spacer()
            HStack { Spacer() }
        }.background(.black)
    }
    var loading: some View {
        Text("LOADING").font(.custom("Avenir Next Bold", size: 45)).foregroundColor(.cyan).padding()
    }
    var continueButton: some View {
        Text("CONTINUE")
            .font(.custom("Avenir Next Regular", size: 35))
            .foregroundColor(!self.spaceViewModel.sceneManager.viewLoaded ? .gray : .red)
            .onTapGesture {
                if self.spaceViewModel.sceneManager.viewLoaded { self.userSelectedContinue = true; self.spaceViewModel.sceneManager.view.play(nil) }
            }.padding()
    }
    func generateTip() -> String {
        return "Remember to practice your barrel rolls!"
    }
}
