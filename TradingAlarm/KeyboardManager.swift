//
//  KeyboardManager.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/11/23.
//

import UIKit

/**
*  To adjust the scroll view associated with the displayed view to accommodate
*  the display of keyboard so that the view gets adjusted accordingly without getting hidden
*/
class KeyboardManager {

    private var scrollView: UIScrollView

    /**
    *  -parameter scrollView: ScrollView that need to be adjusted so that it does not get clipped by the presence of the keyboard
     */
    init(scrollView: UIScrollView) {
        
        self.scrollView = scrollView
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(adjustForKeyboard),
                                       name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }
    
    /**
    * Indicates that the on-screen keyboard is about to be presented.
    *  -parameter notification: Contains animation and frame details on the keyboard
    *
    */
    @objc func adjustForKeyboard(notification: Notification) {

        guard let containedView = scrollView.superview else { return }

        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = containedView.convert(keyboardScreenEndFrame, to: containedView.window)

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
        let rawAnimationCurveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).uintValue

        UIView.animate(withDuration: TimeInterval(truncating: duration),
                                     delay: 0,
                                     options: [UIView.AnimationOptions(rawValue: rawAnimationCurveValue)],
                                     animations: {

                                        if notification.name == UIResponder.keyboardWillHideNotification {
                                            self.scrollView.contentInset = UIEdgeInsets.zero
                                        } else {
                                            self.scrollView.contentInset = UIEdgeInsets(top: 0,
                                                                                                                                    left: 0,
                                                                                                                                    bottom: keyboardViewEndFrame.height,
                                                                                                                                    right: 0)
                                        }

                                        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset

        },
                                     completion: nil)
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }

}
