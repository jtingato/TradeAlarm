//
//  Date+TimeString.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/13/23.
//

import Foundation

extension Date {
    
    /// A convenience function that returns the 24 hour time portion of a Date object in a colon separated format. e.g. 08:27:21 or
    /// This matches the time format that is expected in imported json.
    /// This is for debug purposes only
    var timeString: String? {
        let currentHourString = String(Calendar.current.component(.hour, from: self))
        let currentMinuteString = String(Calendar.current.component(.minute, from: self))
        if currentHourString.isEmpty || currentMinuteString.isEmpty {
            return nil
        }
        
        return "\(currentHourString):\(currentMinuteString):00"
    }
}


