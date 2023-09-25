//
//  AlertSettingsViewModel.swift
//  TradingAlarm
//
//  Created by John Ingato on 9/22/23.
//

import Foundation

class AlarmSettingsViewModel {
    private let dataManager = DataManager(mode: .debugMultipleRelativeTimesToNow)
    
    lazy var alarmsList: [Alarm] = dataManager.allAlarms
}
