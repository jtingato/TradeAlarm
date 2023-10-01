//
//  TimeProvider.swift
//  TradingAlarm
//
//  Created by John Ingato on 9/30/23.
//

import Foundation

struct TimeProvider {
    var date: Date
    var epoch: TimeInterval
    var offset: TimeInterval
    
    var alarmDate: Date {
        return date - offset
    }
    
    init(date: Date) {
        self.date = date
        self.epoch = date.timeIntervalSince1970
        self.offset = TimeProvider.timeZoneDelta
    }
    
    init(timeString: String) {
        guard let time = TimeString(with: timeString) else {
            fatalError("TimeProvider could not create a TimeString from json string")
        }
        
        guard let date = Calendar.current.date(bySettingHour:   time.hour,
                                               minute:          time.minutes,
                                               second:          00,
                                               of:              Date.now) else {
            fatalError("TimeProvider could not create a Date from the json string")
        }
        
        self.init(date: date)
    }
    
    static var hoursFromNYTime: Double {
        return timeZoneDelta / 3600
    }
    
    static var timeZoneDelta: TimeInterval {
        TimeInterval(TimeZone(identifier: "America/New_York")!.secondsFromGMT() - TimeZone.current.secondsFromGMT())
    }
}
