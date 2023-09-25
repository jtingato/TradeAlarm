//
//  Alarm.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/9/23.
//

import Foundation

struct Alarms: Codable {
    var alarms: [Alarm]
}


struct Alarm: Codable {
    let alarmId: String
    var alarmTitle: String?
    var alarmDescription: String?
    var alarmTime: Date
    var alarmRepeats: Bool
    var alarmEnabled: Bool
    var alarmSoundName: String?
    var alarmSoundEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
        case alarmId = "id"
        case alarmTitle = "title"
        case alarmDescription = "desc"
        case alarmTime = "time"
        case alarmRepeats
        case alarmEnabled
        case alarmSoundName
        case alarmSoundEnabled
    }
    
    mutating func update(alarm: Alarm) {
        self.alarmEnabled = alarm.alarmEnabled
        self.alarmSoundEnabled = alarm.alarmSoundEnabled
        self.alarmRepeats = alarm.alarmRepeats
        self.alarmSoundName = alarm.alarmSoundName
    }
    
    init(from decoder: Decoder) throws {
        let container           = try decoder.container(keyedBy: CodingKeys.self)
        
        self.alarmId            = try container.decodeIfPresent(String.self, forKey: .alarmId) ?? UUID().uuidString
        self.alarmTitle         = try container.decodeIfPresent(String.self, forKey: .alarmTitle) ?? nil
        self.alarmDescription   = try container.decodeIfPresent(String.self, forKey: .alarmDescription) ?? nil
        self.alarmRepeats       = try container.decodeIfPresent(Bool.self, forKey: .alarmRepeats) ?? true
        self.alarmEnabled       = try container.decodeIfPresent(Bool.self, forKey: .alarmEnabled) ?? true
        self.alarmSoundName     = try container.decodeIfPresent(String.self, forKey: .alarmSoundName) ?? "happybells"
        self.alarmSoundEnabled  = try container.decodeIfPresent(Bool.self, forKey: .alarmSoundEnabled) ?? true
        
        let timeStringFromJson  = try container.decode(String.self, forKey: .alarmTime)
        self.alarmTime          = Alarm.timeFrom(jsonTimeString: timeStringFromJson) ?? Date(timeIntervalSince1970: 0)
    }
    
    static func timeFrom(jsonTimeString: String) -> Date? {
        guard let timeString = TimeString(with: jsonTimeString) else { return nil }
        
        return Calendar.current.date(bySettingHour: timeString.hour, minute: timeString.minutes, second: 0, of: Date())!
    }
}
