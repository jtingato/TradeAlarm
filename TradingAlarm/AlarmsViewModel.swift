//
//  AlertsViewModel.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/5/23.
//

import Foundation
import Combine

class AlarmsViewModel {
    private let dataManager = DataManager(mode: .debugSingle)

    var triggeredAlertPublisher = PassthroughSubject<String, Never>()
    
    func setup() throws {
        dataManager.activeAlarms.forEach { alarm in
            RunLoop.main.add(createTimer(for: alarm), forMode: .common)
        }
    }
    
    private func createTimer(for alarm: Alarm) -> Timer {
        Timer(fireAt: alarm.alarmTime, 
              interval: 0,
              target: self,
              selector: #selector(publishAlerting(timer:)),
              userInfo: alarm.alarmId, repeats: false)
    }
    
    @objc func publishAlerting(timer: Timer) {
        if let uuid = timer.userInfo as? String {
            triggeredAlertPublisher.send(uuid)
        }
    }
}

extension AlarmsViewModel {
    func getAlertBy(id: String) -> Alarm? {
        dataManager.activeAlarms.first { $0.alarmId == id }
    }
}
