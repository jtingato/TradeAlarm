//
//  AlertSettingCollectionViewCell.swift
//  TradingAlarm
//
//  Created by John Ingato on 9/22/23.
//

import UIKit

class AlarmSettingTableViewCell: UITableViewCell {
    @IBOutlet weak var alarmNameLabel: UILabel!
    @IBOutlet weak var alarmEnabledSwitch: UISwitch!
    @IBOutlet weak var alarmTimeLabel: UILabel!
    
    var thisAlarm: Alarm?
    var alarmIdentifier: String = ""
    
    @Injected var dataManager: DataManager
    
    func populateCell(_ alarm: Alarm) {
        thisAlarm = alarm
        alarmIdentifier = alarm.alarmId
        alarmNameLabel.text = alarm.alarmTitle
        alarmEnabledSwitch.isOn = alarm.alarmEnabled == true
        alarmTimeLabel.text = alarm.alarmTime.displayString
    }
    
    @IBAction func didUpdateEnabledState(_ sender: UISwitch) {
        thisAlarm?.alarmEnabled = alarmEnabledSwitch.isOn
        
        if let thisAlarm = thisAlarm {
            print("Updating \(thisAlarm.alarmId) to \(alarmEnabledSwitch.isOn ? "enabled" : "disabled")")
            print(dataManager.allAlarms.first!.alarmId)
            
            dataManager.updateAlarmWith(updatedAlarm: thisAlarm)
        }
    }
}
