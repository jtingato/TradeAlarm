//
//  StringExtensions.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/18/23.
//

import Foundation

extension String {
    func toTimeInterval() -> TimeInterval? {
        let dateFormatter = DateFormatter()
        let date = dateFormatter.date(from: self)
        
        return date?.timeIntervalSince1970
    }
}
