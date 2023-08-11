//
//  TimeString.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/10/23.
//

import Foundation

struct TimeString {
    var hour, minutes, seconds: Int
    
    init?(with jsonString: String?) {
        guard let jsonString else { return nil }
        
        let components = (jsonString.components(separatedBy: ":")).dropLast()
        guard components.count == 2 else { return nil }
        
        let intArr = components.compactMap { Int($0) ?? nil }
        guard components.count == 2 else { return nil }
        
        self.hour = intArr[0]
        self.minutes = intArr[1]
        self.seconds = 0
    }
}
