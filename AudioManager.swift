//
//  AudioManager.swift
//  Starhaven
//
//  Created by Jared on 7/10/23.
//

import Foundation
import AVFoundation
import AVKit

class AudioManager {
    var hvnPlayer: AVAudioPlayer?
    var explosionPlayer: AVAudioPlayer?
    var soundPlayer: AVAudioPlayer?
    func playExplosion(distance: Float, maxDistance: Float) {
        // Calculate sound based on distance-ish
        let volume = (maxDistance - distance) / maxDistance
        let url = Bundle.main.url(forResource: "Explosion", withExtension: "aif")
        do {
            let player = try AVAudioPlayer(contentsOf: url!)
            self.explosionPlayer = player
            self.explosionPlayer?.volume = volume
            self.explosionPlayer?.play()
            print("played \(volume)")
        } catch {
            print("Error playing sound")
        }
    }
    func missileFired() {
        let name = "missileFired"
        let url = Bundle.main.url(forResource: name, withExtension: "wav")
    }
    enum Harvest: CaseIterable {
        case one
        case two
        case three
        case four
        
        func next() -> Harvest {
            guard let index = Harvest.allCases.firstIndex(of: self) else { return .one }
            let nextIndex = (index + 1) % Harvest.allCases.count
            return Harvest.allCases[nextIndex]
        }
    }
    var harvest: Harvest = .one
    func playHarvest() {
        let name: String
        switch self.harvest.next() {
        case .one:
            name = "harvest1"
        case .two:
            name = "harvest2"
        case .three:
            name = "harvest3"
        case .four:
            name = "harvest4"
        }
        self.playSound(resourceName: name, withExtension: "aif")
        
    }
    public func playMusic(resourceName: String) {
        self.playSound(resourceName: resourceName, withExtension: "mp3")
    }
    private func playSound(resourceName: String, withExtension: String) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: withExtension)
        do {
            if let url = url {
                let player = try AVAudioPlayer(contentsOf: url)
                self.soundPlayer = player
                self.soundPlayer?.play()
                print("Playing sound.")
            } else { print ("Couldn't load URL or play sound.")}
        } catch {
            print("Error playing sound.")
        }
    }
}
