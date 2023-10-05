//
//  AlarmManager.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/2/23.
//

import Foundation
import UserNotifications
import Combine

struct AlarmingState {
    var id: String
    var animated: Bool
    var sounding: Bool
}

class AlarmScheduler: NSObject {
    
    let notificationCenter = UNUserNotificationCenter.current()
    
    // Publishes to subscriber when an alert becomes active
    var triggeredAlertPublisher = PassthroughSubject<AlarmingState, Never>()
    
    func schedule(alarms: [Alarm]) {
        resetAllAlerts()
        for alarm in alarms {
            schedule(alarm)
        }
        
        Task.init {
            print("Printing pending notification requests")
            let requests = await self.getPendingAlarms()
            print(requests)
        }
    }
    
    // Not needed but is good to have for debugging; inspecting what had been scheduled in the NotificationCenter
    private var scheduledAlarms = [String : String]()
    
    private func schedule(_ alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = alarm.alarmTitle ?? "Trade alert title was not available"
        content.body = alarm.alarmDescription ?? "Every day at 10:30"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "happybells.wav"))
        content.userInfo["identifier"] = alarm.alarmId
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: alarm.alarmTime.timeComponents, repeats: true)
        
        // Build the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        // Schedule in the Notification Center
        notificationCenter.add(request) { error in
            if let error {
                print("Error sending notification: \(error)")
            } else {
                print("Adding '\(alarm.alarmTitle!)' to scheduledAlerts array")
                self.scheduledAlarms[alarm.alarmId] = alarm.alarmTitle
            }
        }
    }
    
    func unschedule(_ alarm: Alarm) {
        let indentifiers = [alarm.alarmId]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: indentifiers)
    }
    
    func getPendingAlarms() async -> [UNNotificationRequest] {
         await notificationCenter.pendingNotificationRequests()
    }
    
    func getDeliveredAlarms() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
    }
    
    func removeAllPendingAlarms() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removeAllDeliveredAlerts() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func resetAllAlerts() {
        removeAllPendingAlarms()
        removeAllDeliveredAlerts()
    }
}


extension AlarmScheduler: UNUserNotificationCenterDelegate {
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
}
