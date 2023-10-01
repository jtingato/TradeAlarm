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
        
        // Listens for triggered alarms to display alarm screen
        viewModel.triggeredAlertPublisher
            .receive(on: DispatchQueue.main)
            .sink { identifier in
                print("Received AlertId: \(identifier)for displaying")
                guard let activeAlert = self.viewModel.getAlertBy(id: identifier) else {
                    return
                }
                
                self.alertTitle.text = activeAlert.alarmTitle
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
            .store(in: &subscribers)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let navController = self.navigationController else { return }
        
        navController.setNavigationBarHidden(false, animated: false)
        navController.setToolbarHidden(false, animated: false)
        
        toolbarItems = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(openSettings))
        ]
    }
        
    @objc
    func openSettings() {
        performSegue(withIdentifier: "Show Settings", sender: self)
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
