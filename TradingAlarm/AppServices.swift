//
//  AppServices.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/5/23.
//

import Foundation
import Combine

class AppServices {
    
    static var datamode: DataMode = .debugMultipleRelativeTimesToNow
    
    var subscriber = Set<AnyCancellable>()
    init() {
        // Alarmscheduler must be first because DataManager depends on it for initialization
        InjectedValues[AlarmScheduler.self] = AlarmScheduler()
        
        InjectedValues[DataManager.self] =  DataManager(
            mode: AppServices.datamode
        )
        
        InjectedValues[AppLifecycleManager.self] = AppLifecycleManager()
        
        @Injected var appLifecycleManager: AppLifecycleManager
        @Injected var dataManager: DataManager
        @Injected var alarmScheduler: AlarmScheduler
        
        appLifecycleManager.appLifecycleEvent
            .sink { event in
                if case .applicationWillEnterForeground = event {
                    if let lastDeliveredAlarm = dataManager.lastDeliveredAlarm {
                        alarmScheduler.alarmResponder.showAlarmOnForegroundingWithoutSelectingNotification(alarm: lastDeliveredAlarm)
                    }
                }
                
                if case .applicationWillTerminate = event {
                    alarmScheduler.resetAllAlerts()
                }
            }
            .store(in: &subscriber)
    }
}
