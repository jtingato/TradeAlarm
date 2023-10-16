//
//  AlertSettingsViewModel.swift
//  TradingAlarm
//
//  Created by John Ingato on 9/22/23.
//

import Foundation

class AlarmSettingsViewModel {
    @Injected var dataManager: DataManager
    
    lazy var alarmsList: [Alarm] = dataManager.allAlarms
    
}
