//
//  DataManager.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/11/23.
//

import Foundation

enum DataMode {
    case production
    case debugMultipleRelativeTimesToNow
    case debugSingle
}

class DataManager {
    var mode: DataMode
    private var alarms = Alarms(alarms: [])
    
    var inactiveDailyAlarms: [Alarm] {
        enabledAlarms.filter { $0.alarmTime < Date.now }
    }
    
    var activeDailyAlarms: [Alarm] {
        var futureAlarms = enabledAlarms.filter { $0.alarmTime >= Date.now }
        futureAlarms.append(inactiveDailyAlarms.last!)
        
        return futureAlarms
    }
    
    var enabledAlarms: [Alarm] {
        alarms.alarms.filter { $0.alarmEnabled == true }
    }
    
    var allAlarms: [Alarm] {
        alarms.alarms
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
    
    init(mode: DataMode) {
        // Load default content based on the run mode presented from caller
        self.mode = mode
        
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
}

extension DataManager {
    /// Uses a group of times relative to the run time and returns a Data object representing a returned json string
    /// This string is parsed from its know type into codable alarms
    var debugJson: Data? {
        let now = Date()
        
        let t1 = (now + TimeInterval.minutes(1)).timeString
        let t2 = (now + TimeInterval.minutes(2)).timeString
        let t3 = (now + TimeInterval.minutes(3)).timeString
        let t4 = (now + TimeInterval.minutes(4)).timeString
        let t5 = (now + TimeInterval.minutes(5)).timeString
        let t6 = (now + TimeInterval.minutes(6)).timeString
        
        let jsonString = """
        {"alarms":[{"id":"caa0c427-aa6a-4364-88cf-50916eb2037d","title":"NYSE will be opening soon","desc":"Have a great day trading. NYSE will open in 30 minutes","time":"\(t1)"},{"id":"af1c5264-f8f9-4ea7-9e9f-fd0e607692d1","title":"NYSE is OPEN","desc":"The stock exchange is open.  If you are playing the ORB prepare to set your range as the candles close.","time":"\(t2)"},{"id":"edd7d355-c8a0-488d-ba30-4347ca782811","title":"Mid-Morning Reversal","desc":"The Mid-Morning reversal is the time when trend can change direction.  Keep a watch on your indicators or for slowing candle growth to help determine when the change is coming. If the trend does not change, it is likely that the trend will continue for a goor portion of the day.","time":"\(t3)"},{"id":"cd4fc7ae-9cc3-4582-a7e5-da62a268d4c2","title":"London Stock Exchange is Closed","desc":"Have a great day trading. NYSE will open in 30 minutes","time":"\(t4)"},{"id":"d06d4c42-d08d-4e35-9f88-ba4571aa2995","title":"Power Hour","desc":"Its the last hour of the day","time":"\(t5)"},{"id":"d06d4c42-d08d-4e35-9f88-ba4571aa2997","title":"US Stock Market is closed","desc":"The NYSE is now officially closed.  You have 15 minutes remaining to buy or sell stocks.  Option trading is not available after the official closing.","time":"\(t6)"}]}
        """
        return jsonString.data(using: .utf8)
    }
}

extension TimeInterval {
    
    static func minutes(_ minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }
}
