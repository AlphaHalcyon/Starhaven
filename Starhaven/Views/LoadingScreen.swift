//
//  LoadingScreen.swift
//  Starhaven
//
//  Created by JxR on 6/11/23.
//

import Foundation
import SwiftUI

@MainActor struct LoadingScreen: View {
    unowned var spaceViewModel: SpacegroundViewModel
    @Binding var userSelectedContinue: Bool
    var body: some View {
        self.loadScreen
    }
    var loadScreen: some View {
        VStack {
            Text("HVN")
                .font(.custom("Avenir Next Regular", size: 136)).foregroundColor(self.spaceViewModel.loadingSceneView ? .gray : .red)
            Spacer()
            self.mission
            Spacer()
            Text("CONTINUE")
                .font(.custom("Avenir Next Regular", size: 50))
                .foregroundColor(self.spaceViewModel.loadingSceneView ? .gray : .red)
                .onTapGesture {
                    if !self.spaceViewModel.loadingSceneView { self.userSelectedContinue = true }
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
    var mission: some View {
        VStack(spacing: 15) {
            Text("The Office of Stellar-Naval Research has instructed you to harvest a rogue system of black holes in Messier 87's 'Starhaven' region.").multilineTextAlignment(.center).font(.body).foregroundColor(.white)
            Text("Other factions are dueling for control of the region and its contents. They will be distracted with each other; engage them at your own risk, and earn points for destroying them.").multilineTextAlignment(.center).font(.body).foregroundColor(.white)
            Text("Collect all the black holes in the area by flying directly into them to earn points. Your Higgs Decoupling Drive should render your ship massless and safe.").multilineTextAlignment(.center).font(.body).foregroundColor(.white)
        }
    }
    func generateTip() -> String {
        return "Remember to practice your barrel rolls!"
    }
}
