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
                .font(.custom("Avenir Next Regular", size: 136)).foregroundColor(.red)
            self.mission
            if !self.spaceViewModel.sceneManager.viewLoaded { self.loading } else {
                self.continueButton
            }
            Spacer()
            // PRACTICE YOUR BARREL ROLLS
            Text("Tip: \(self.generateTip())")
                .font(.custom("Avenir Next Italic", size: 20))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).padding().foregroundColor(.primary)
            HStack { Spacer() }
        }.background(.black)
    }
    var loading: some View {
        Text("LOADING").font(.custom("Avenir Next Bold", size: 50)).foregroundColor(.cyan).padding()
    }
    var continueButton: some View {
        Text("CONTINUE")
            .font(.custom("Avenir Next Regular", size: 50))
            .foregroundColor(!self.spaceViewModel.sceneManager.viewLoaded ? .gray : .red)
            .onTapGesture {
                if self.spaceViewModel.sceneManager.viewLoaded { self.userSelectedContinue = true; self.spaceViewModel.sceneManager.view.play(nil) }
            }.padding()
    }
    var mission: some View {
        VStack {
            Text("The Office of Stellar-Naval Research has instructed you to harvest a rogue system of black holes in Messier 87's 'Starhaven' region.").multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("Avenir Next Bold", size: 20))
                .foregroundColor(.gray)
            Text("Other factions are dueling for control of the region and its contents. They will be distracted with each other; engage them at your own risk, and earn points for destroying them.")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).font(.custom("Avenir Next Bold", size: 20)).foregroundColor(.gray)
            Text("Collect all the black holes in the area by flying directly into them to earn points (the faster you fly, the more points you earn). Your Higgs Decoupling Drive should render your ship massless and safe.").multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).font(.custom("Avenir Next Bold", size: 20)).foregroundColor(.gray)
        }.padding(.horizontal)
    }
    func generateTip() -> String {
        return "Remember to practice your barrel rolls!"
    }
}
