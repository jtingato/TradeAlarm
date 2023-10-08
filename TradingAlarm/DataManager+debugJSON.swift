//
//  DataManager+debugJSON.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/7/23.
//

import Foundation

extension DataManager {
    /// Uses a group of times relative to the run time and returns a Data object representing a returned json string
    /// This string is parsed from its know type into codable alarms
    var debugJson: Data? {
        let now = Date() + TimeInterval.oneHour
        
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
