//
//  Alarm.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/9/23.
//

import Foundation
import RealmSwift

struct Alarms: Codable {
    var alarms: [Alarm]
}


final class Alarm: Object, Codable {
    @Persisted(primaryKey: true) var alarmId: String
    @Persisted var alarmTitle: String?
    @Persisted var alarmDescription: String?
    @Persisted var alarmTime: Date
    @Persisted var alarmRepeats: Bool
    @Persisted var alarmEnabled: Bool
    @Persisted var alarmSoundName: String?
    @Persisted var alarmSoundEnabled: Bool
    
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
    
    convenience init(from decoder: Decoder) throws {
        self.init()
        
        let container           = try decoder.container(keyedBy: CodingKeys.self)
        
        self.alarmId            = try container.decodeIfPresent(String.self, forKey: .alarmId) ?? UUID().uuidString
        self.alarmTitle         = try container.decodeIfPresent(String.self, forKey: .alarmTitle) ?? nil
        self.alarmDescription   = try container.decodeIfPresent(String.self, forKey: .alarmDescription) ?? nil
        self.alarmRepeats       = try container.decodeIfPresent(Bool.self, forKey: .alarmRepeats) ?? true
        self.alarmEnabled       = try container.decodeIfPresent(Bool.self, forKey: .alarmEnabled) ?? true
        self.alarmSoundName     = try container.decodeIfPresent(String.self, forKey: .alarmSoundName) ?? "happybells"
        self.alarmSoundEnabled  = try container.decodeIfPresent(Bool.self, forKey: .alarmSoundEnabled) ?? true
        
        let timeStringFromJson  = try container.decode(String.self, forKey: .alarmTime)
        self.alarmTime          = TimeProvider(timeString: timeStringFromJson).alarmDate
    }
    
    convenience init(alarmTitle: String, alarmDescription: String, alarmTime: Date ) {
        self.init()
        
        self.alarmId = UUID().uuidString
        self.alarmTitle = alarmTitle
        self.alarmDescription = alarmDescription
        self.alarmTime = alarmTime
        self.alarmRepeats = false
        self.alarmEnabled = true
        self.alarmSoundName = "happybells"
        self.alarmSoundEnabled = true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(alarmId, forKey: .alarmId)
        try container.encode(alarmTitle, forKey: .alarmTitle)
        try container.encode(alarmDescription, forKey: .alarmDescription)
        try container.encode(alarmRepeats, forKey: .alarmRepeats)
        try container.encode(alarmEnabled, forKey: .alarmEnabled)
        try container.encode(alarmSoundName, forKey: .alarmSoundName)
        try container.encode(alarmSoundEnabled, forKey: .alarmSoundEnabled)
        try container.encode(alarmTime, forKey: .alarmTime)
    }
}
