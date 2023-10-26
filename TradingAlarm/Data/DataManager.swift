//
//  DataManager.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/11/23.
//

import Foundation
import Combine

enum DataMode {
    case production
    case debugMultipleRelativeTimesToNow
    case debugSingle
}

class DataManager: Injectable {
    
    /// A flag that determines which set of default alarms to use
    var mode: DataMode
    
    /// Data store for currently stored alarms
    /// Alarms are only scheduled if it is a trading day (weekday)
    private var alarms = Alarms(alarms: []) {
        didSet {
            @Injected var alarmScheduler: AlarmScheduler
            if Date.now.isTradingDay && mode == .production {
                alarmScheduler.schedule(alarms: activeEnabledAlarms)
            }
        }
    }
    
    /// Return an array of all Alarms regardless of thier status or grouping
    var allAlarms: [Alarm] {
        alarms.alarms
    }
    
    /// Return an array of all Alarms that have not been disabled by the user
    var enabledAlarms: [Alarm] {
        alarms.alarms.filter { $0.alarmEnabled == true }
    }
    
    /// Return an array of Alarms within the current day that are schedule for the future
    /// The last inactive alarm is included in the array so we always show the last event that happened
    var activeEnabledAlarms: [Alarm] {
        var futureAlarms = enabledAlarms.filter { $0.alarmTime >= Date.now }
        if let last = inactiveEnabledAlarms.last {
            futureAlarms.append(last)
        }
        
        return futureAlarms
    }
    
    /// Return an array of Alarms within the current day, but where the alarmTime times have already past
    var inactiveEnabledAlarms: [Alarm] {
        enabledAlarms.filter { $0.alarmTime.timeIntervalSinceReferenceDate < Date.now.timeIntervalSinceReferenceDate }
    }
    
    /// Returns the last Alarm that has been presented to the screen
    var lastDeliveredAlarm: Alarm? {
        inactiveEnabledAlarms.last
    }
    
    func prepareForFirstUseIfNeeded(mode: DataMode) {
        if false {
            
        } else {
            var managedAlarms = [NSManagedObject]()
            alarms = JsonProcessing.initialAlarmsFor(mode: self.mode)
            alarms.alarms.forEach { alarm in
                
            }
        }
    }
    
    init(mode: DataMode = AppServices.datamode) {
        self.mode = mode
        prepareForFirstUseIfNeeded(mode: mode)
    }
}

// MARK: - DAO functions

extension DataManager {
    func fetchAlarmWith(id: String) -> Alarm? {
        allAlarms.first { $0.alarmId == id }
    }
    
    func updateAlarmWith(updatedAlarm: Alarm) {
        guard let index = allAlarms.firstIndex(where: { $0.alarmId == updatedAlarm.alarmId }) else { return }
        alarms.alarms[index] = updatedAlarm
    }
}
