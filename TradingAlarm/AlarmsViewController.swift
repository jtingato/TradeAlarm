//
//  ViewController.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/5/23.
//

import UIKit
import Combine

class AlarmsViewController: UIViewController {
    
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertDescription: UILabel?

    let viewModel = AlarmsViewModel()
    var subscribers = [AnyCancellable]()
    let soundPlayer = SoundPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try viewModel.setup()
        } catch {
            print("Error: \(error)")
        }
        
        // Listens to the 
        viewModel.triggeredAlertPublisher
            .sink { identifier in
                print("Received AlertId: \(identifier)")
                guard let activeAlert = self.viewModel.getAlertBy(id: identifier) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.alertTitle.text        = activeAlert.alarmTitle
                    self.alertDescription?.text = activeAlert.alarmDescription
                    self.view.flash(numberOfFlashes: 10)
                    if activeAlert.alarmSoundEnabled {
                        if let soundName = activeAlert.alarmSoundName {
                            self.soundPlayer.playSound(name: soundName)
                        } else {
                            self.soundPlayer.playSound(name: "happybells")
                        }
                    }
                }
            }
            .store(in: &subscribers)
    }
}

extension UIView {
        func flash(numberOfFlashes: Float) {
           let flash = CABasicAnimation(keyPath: "opacity")
           flash.duration = 0.2
           flash.fromValue = 1
           flash.toValue = 0.1
           flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
           flash.autoreverses = true
           flash.repeatCount = numberOfFlashes
           layer.add(flash, forKey: nil)
       }
 }
