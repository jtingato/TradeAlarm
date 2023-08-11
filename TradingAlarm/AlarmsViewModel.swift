//
//  AlertsViewModel.swift
//  TradingAlarm
//
//  Created by John Ingato on 8/5/23.
//

import Foundation
import Combine

class AlarmsViewModel {
    private var alarms = Alarms(alarms: [])
    
    var publisher = PassthroughSubject<String, Never>()
    
    func setup() throws {
        guard let data = readLocalJSONFile(for: "defaultAlarms.json") else { return }

        let stringValue = String(data: data, encoding: .utf8)
        try parse(data: data)
        
        alarms.alarms.forEach { alarm in
            RunLoop.main.add(createTimer(for: alarm), forMode: .common)
        }
    }
    
    private func createTimer(for alarm: Alarm) -> Timer {
        Timer(fireAt: alarm.alarmTime, interval: 0, target: self, selector: #selector(publishAlerting(timer:)), userInfo: alarm.alarmId, repeats: false)
    }
    
    @objc func publishAlerting(timer: Timer) {
        if let uuid = timer.userInfo as? String {
            publisher.send(uuid)
        }
    }
}

extension AlarmsViewModel {
    func getAlertBy(id: String) -> Alarm? {
        alarms.alarms.first { $0.alarmId == id }
    }
    
    private func readLocalJSONFile(for name: String) -> Data? {
        do {
            if let filePath = Bundle.main.path(forResource: name, ofType: nil) {
                let fileUrl = URL(fileURLWithPath: filePath)
                let data = try Data(contentsOf: fileUrl)
                return data
            }
        } catch {
            print("error: \(error)")
        }
        return nil
    }
    
    private func parse(data: Data) throws  {
        let decoded = try JSONDecoder().decode(Alarms.self, from: data)
        print(decoded)
        self.alarms = decoded
    }
}
