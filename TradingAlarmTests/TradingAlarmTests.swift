//
//  TradingAlarmTests.swift
//  TradingAlarmTests
//
//  Created by John Ingato on 8/11/23.
//

import XCTest

@testable import TradingAlarm


final class TradingAlarmTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTimeStringHoursAndMinutes() throws {
        XCTAssertTrue(try localHourFrom(utcTimeString: "9:00:00") == 9)
        XCTAssertTrue(try localHourFrom(utcTimeString: "02:17:00") == 2)
        
        XCTAssertFalse(try localHourFrom(utcTimeString: "04:20:00") == 12)
    }
    
    func localHourFrom(utcTimeString: String) throws -> Int {
        let timeString = try XCTUnwrap(TimeString(with: utcTimeString))
        return timeString.hour
    }
    
    func testForCorrectTimesForInfection() {
        
    }
}
