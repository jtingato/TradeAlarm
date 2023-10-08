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
    private var alarms = Alarms(alarms: []) {
        didSet {
            @Injected var alarmScheduler: AlarmScheduler
            alarmScheduler.schedule(alarms: activeDailyAlarms)
        }
    }
    
    /// Return an array of all Alarms regardless of thier status or grouping
    var allAlarms: [Alarm] {
        alarms.alarms
    }
    
    /// Return an array of Alarms within the current day, but where the alarmTime times have already past
    var inactiveDailyAlarms: [Alarm] {
        enabledAlarms.filter { $0.alarmTime.timeIntervalSinceReferenceDate < Date.now.timeIntervalSinceReferenceDate }
    }
    
    var lastDeliveredAlarm: Alarm? {
        inactiveDailyAlarms.last
    }
    
    /// Return an array of Alarms within the current day that are schedule for the future
    /// The last inactive alarm is included in the array so we always show the last event that happened
    var activeDailyAlarms: [Alarm] {
        var futureAlarms = enabledAlarms.filter { $0.alarmTime >= Date.now }
        if let last = inactiveDailyAlarms.last {
            futureAlarms.append(last)
        }
        
        return futureAlarms
    }
    
    /// Return an array of all Alarms that have not been disabled by the user
    var enabledAlarms: [Alarm] {
        alarms.alarms.filter { $0.alarmEnabled == true }
    }
    
    func getAlertBy(id: String) -> Alarm? {
        enabledAlarms.first { $0.alarmId == id }
    }
    
    private func readLocalJSONFile(for name: String) -> Data? {
        do {
            if let filePath = Bundle.main.path(forResource: name, ofType: nil) {
                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileUrl)
                return data
            }
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    // Parse the received data object and decode into alarms
    private func parse(data: Data) throws  {
        let decoded = try JSONDecoder().decode(Alarms.self, from: data)
        // print(decoded)
        self.alarms = decoded
    }
    
    func setAlarms(mode: DataMode = AppServices.datamode) {
        // Load default content based on the run mode presented from caller
        
        switch mode {
        case .debugMultipleRelativeTimesToNow:
            if let data = debugJson {
                do {
                    try parse(data: data)
                } catch {
                    print(error)
                }
            }
        case .debugSingle:
            if let data = readLocalJSONFile(for: "testAlarm.json") {
                do {
                    try parse(data: data)
                } catch {
                    print(error)
                }
            }
        case .production:
            let filename = "defaultNYAlarms.json"
            guard let data = readLocalJSONFile(for: filename) else {
                fatalError("Cannot find file \(filename)")
            }
            
            do {
                try parse(data: data)
            } catch {
                print(error)
            }
        }
    }
    
    init(mode: DataMode = AppServices.datamode) {
        self.mode = mode
        setAlarms(mode: mode)
    }
}
