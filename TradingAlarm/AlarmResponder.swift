//
//  AlarmResponder.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/7/23.
//

import UIKit
import Combine


class AlarmResponder: NSObject, UNUserNotificationCenterDelegate {
    
    // Publishes to subscribers when an alert becomes active
    var triggeredAlertPublisher = PassthroughSubject<AlarmingState, Never>()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let uuid = response.notification.request.content.userInfo["identifier"] as? String {
            print("AlarmScheduler : userNotificationCenter didReceive alerId: \(uuid)")
            
            let alarmingState = AlarmingState(id: uuid, animated: false, sounding: false)
            triggeredAlertPublisher.send(alarmingState)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let uuid = notification.request.content.userInfo["identifier"] as? String {
            print("AlarmScheduler : userNotificationCenter willPresent alerId: \(uuid)")
            
            let alarmingState = AlarmingState(id: uuid, animated: true, sounding: true)
            triggeredAlertPublisher.send(alarmingState)
        }
    }
    
    func showAlarmOnForegroundingWithoutSelectingNotification(alarm: Alarm) {
        let alarmingState = AlarmingState(id: alarm.alarmId, animated: true, sounding: true)
        triggeredAlertPublisher.send(alarmingState)
    }
}
