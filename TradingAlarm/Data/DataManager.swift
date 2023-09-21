//
//  DataManager.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/11/23.
//

import Foundation

enum DataMode {
    case production
    case debugMultiple
    case debugSingle
}

class DataManager {
    var mode: DataMode
    private var alarms = Alarms(alarms: [])
    
    var activeAlarms: [Alarm] {
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
    
    private func parse(data: Data) throws  {
            let decoded = try JSONDecoder().decode(Alarms.self, from: data)
            print(decoded)
            self.alarms = decoded
        }

    
    init(mode: DataMode) {
        self.mode = mode
        switch mode {
        case .debugMultiple:
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
            if let data = readLocalJSONFile(for: "defaultAlarms.json") {
                do {
                    try parse(data: data)
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension DataManager {
    
    var debugJson: Data? {
        let now = Date()
        
        guard let t1 = (now + 10).timeString,
              let t2 = (now + 20).timeString,
              let t3 = (now + 30).timeString,
              let t4 = (now + 40).timeString,
              let t5 = (now + 50).timeString else {
            return nil
        }
        
        let jsonString = """
        {"alarms":[{"id":"caa0c427-aa6a-4364-88cf-50916eb2037d","title":"NYSE will be opening soon","desc":"Have a great day trading. NYSE will open in 30 minutes","time":\(t1)},{"id":"af1c5264-f8f9-4ea7-9e9f-fd0e607692d1","title":"NYSE is OPEN","desc":"The stock exchange is open.  If you are playing the ORB prepare to set your range as the candles close.","time":\(t2)},{"id":"edd7d355-c8a0-488d-ba30-4347ca782811","title":"Mid-Morning Reversal","desc":"The Mid-Morning reversal is the time when trend can change direction.  Keep a watch on your indicators or for slowing candle growth to help determine when the change is coming. If the trend does not change, it is likely that the trend will continue for a goor portion of the day.","time":\(t3)},{"id":"cd4fc7ae-9cc3-4582-a7e5-da62a268d4c2","title":"London Stock Exchange is Closed","desc":"Have a great day trading. NYSE will open in 30 minutes","time":\(t4)},{"id":"d06d4c42-d08d-4e35-9f88-ba4571aa2995","title":"Power Hour","desc":"Its the last hour of the day","time":\(t5)}]}
        """
        return jsonString.data(using: .utf8)
        
    }
}
