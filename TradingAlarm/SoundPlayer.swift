//
//  SoundPlayer.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/8/23.
//

import Foundation
import AVFoundation

class SoundPlayer {
    var player: AVAudioPlayer?
    
    func playSound(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            player?.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func stopPlaying() {
        player?.stop()
    }
}
