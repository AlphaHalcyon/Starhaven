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
    func explosion(name: String) {
        let url = Bundle.main.url(forResource: name, withExtension: "wav")
        do {
            let player = try AVAudioPlayer(contentsOf: url!)
            self.explosionPlayer = player
            self.explosionPlayer?.play(atTime: .zero)
        } catch {
            print("Error playing sound")
        }
    }
    public func playMusic(resourceName: String) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: "mp3")
        do {
            if let url = url {
                let player = try AVAudioPlayer(contentsOf: url)
                self.hvnPlayer = player
                self.hvnPlayer?.play()
                print("playing song")
            } else { print ("Couldn't load URL or play song.")}
        } catch {
            print("Error playing sound")
        }
    }
}
