//
//  JSONDateAndTimeConversions.swift
//  TradingAlarmTests
//
//  Created by John Ingato on 9/27/23.
//

import XCTest

@testable import TradingAlarm


final class JSONDateAndTimeConversionsTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testJSONTimeExtraction() {
        let dataMan = DataManager(mode: .production)
        XCTAssertNotNil(dataMan)
        
        let allTimes = dataMan.allAlarms.map { $0.alarmTime }
        
        XCTAssertEqual(allTimes.first?.timeString, "09:00:00")
        
    }
}
