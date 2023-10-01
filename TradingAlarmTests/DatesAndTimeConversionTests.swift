//
//  DatesAndTimeConversionTests.swift
//  TradingAlarmTests
//
//  Created by John Ingato on 9/29/23.
//

import XCTest

@testable import TradingAlarm

final class DateAndTimeConversionsTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK - Playground
    func testTimeZoneDelta() {
        XCTAssertEqual(TimeProvider.hoursFromNYTime, 1)
    }
    
    func testDeltasBetweenCurrentAndNYTime() {
        XCTAssertEqual(TimeProvider.hoursFromNYTime, 1.0)
        XCTAssertEqual(TimeProvider.timeZoneDelta, 3600.0)
    }
    
 
    func testCreateTimeProvider() {
        var timeProvider = TimeProvider(timeString: "9:30:00")
        
        // Expectation is 9:30
        XCTAssertEqual(timeProvider.date.displayString, "09:30:00")
        
        // Expectation is 9:30
        XCTAssertEqual(timeProvider.alarmDate.displayString, "08:30:00")
        
        timeProvider = TimeProvider(timeString: "01:30:00")
        // Expectation is
        XCTAssertEqual(timeProvider.alarmDate.displayString, "00:30:00")
    }
}
