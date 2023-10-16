//
//  AddAlarmViewController.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/9/23.
//

import UIKit

protocol PresentationObserver {
    func onAlarmEditingCompleted(alarm: Alarm?)
}

class AddAlarmViewController: UIViewController {
    @IBOutlet weak var alarmTitle: UITextField!
    @IBOutlet weak var alarmDescription: UITextView!
    @IBOutlet weak var alarmTime: UIDatePicker!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var delegate: PresentationObserver?
    
    func prepareForEditing() {
        alarmTitle.becomeFirstResponder()
    }
    
    func prepareToCloseEditing() {
        view.endEditing(true)
    }

    override func viewDidLoad() {
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(keyboardWillShow),
//                                               name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, 
//                                               selector: #selector(keyboardWillHide),
//                                               name: UIResponder.keyboardWillHideNotification, object: nil)
//        
//        cancelButton.addTarget(self, action: #selector(test), for: .touchUpInside)
    }
    
    @IBAction func selectedAnAction(_ sender: UIButton) {
        view.endEditing(true)
        
        if sender == cancelButton {
            delegate?.onAlarmEditingCompleted(alarm: nil)
        } else  {
            let newAlarm: Alarm = Alarm(alarmTitle: alarmTitle.text ?? "",
                                        alarmDescription: alarmDescription.text ?? "",
                                        alarmTime: Date())
            delegate?.onAlarmEditingCompleted(alarm: newAlarm)
        }
        
        // Reset all fields

    }
    
//    @objc func keyboardWillShow() {
//        view.frame.origin.y = newAlarmAnimationValues.away
//        print("keyboardWillShow")
//    }
//    
//    @objc func keyboardWillHide() {
//        view.frame.origin.y = newAlarmAnimationValues.home
//        print("keyboardWillHide")
//    }
}

extension AddAlarmViewController {
    struct AnimationConstraintValues {
        var home: CGFloat
        var away: CGFloat
    }
}
