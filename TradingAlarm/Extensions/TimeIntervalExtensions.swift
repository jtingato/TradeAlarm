//
//  TimeIntervalExtensions.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/3/23.
//

import Foundation

extension TimeInterval {
    
    static var oneMinute = TimeInterval(60)
    static var oneHour = TimeInterval(oneMinute * 60)
    
    static func minutes(_ minutes: Int) -> TimeInterval {
        TimeInterval(TimeInterval(minutes) * TimeInterval.oneMinute)
    }
}
