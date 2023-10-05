//
//  Date+TimeString.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/13/23.
//

import Foundation

extension Date {
    
    // Display the date time as 9:47:00
    var timeStringFormater: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        return formatter
    }
    
    /// A convenience function that returns the 24 hour time portion of a Date object in a colon separated format. e.g. 08:27:21 or
    /// This matches the time format that is expected in imported json.
    /// This is for debug purposes only
    var timeString: String {
        timeStringFormater.string(from: self)
    }
    
    var displayString: String {
        return self.timeStringFormater.string(from: self)
    }
    
    var timeComponents: DateComponents {
        let hour = Calendar.current.component(.hour, from: self)
        let minutes = Calendar.current.component(.minute, from: self)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minutes
        
        return dateComponents
    }
}


