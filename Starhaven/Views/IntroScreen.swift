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
    @EnvironmentObject var gameManager: GameManager
    @Binding var userSelectedContinue: Bool
    @State var redraw: Bool = false
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
            if !self.gameManager.viewLoaded { self.loading } else {
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
            .font(.custom("Avenir Next Regular", size: 40))
            .foregroundColor(self.gameManager.viewLoaded ? .red : .gray)
            .onTapGesture {
                print(self.gameManager.viewLoaded)
                if self.gameManager.viewLoaded {
                    
                    self.gameManager.userSelectedContinue = true
                    self.gameManager.sceneManager.celestialManager?.distributeBlackHoles()
                    self.gameManager.sceneManager.shipManager.ship.look(at: self.gameManager.sceneManager.scene.rootNode.position)
                    self.gameManager.sceneManager.shipManager.currentRotation = self.gameManager.sceneManager.shipManager.ship.simdOrientation
                    print(self.gameManager.userSelectedContinue)
                }
            }.padding()
    }
    func generateTip() -> String {
        return "Remember to practice your barrel rolls!"
    }
}
