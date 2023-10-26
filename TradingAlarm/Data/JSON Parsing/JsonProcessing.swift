//
//  JsonProcessing.swift
//  TradingAlarm
//
//  Created by John Ingato on 10/18/23.
//

import Foundation
import RealmSwift

class JsonProcessing {
    static func initialAlarmsFor(mode: DataMode = AppServices.datamode) -> Alarms {
        // Load default content based on the run mode presented from caller
        
        switch mode {
        case .debugMultipleRelativeTimesToNow:
            if let data = debugJson {
                do {
                    return try parse(data: data)
                } catch {
                    print(error)
                }
            }
        case .debugSingle:
            if let data = readLocalJSONFile(for: "testAlarm.json") {
                do {
                    return try parse(data: data)
                } catch {
                    print(error)
                }
            }
        case .production:
            let filename = "defaultNYAlarms.json"
            guard let data = readLocalJSONFile(for: filename) else {
                fatalError("Cannot find file \(filename)")
            }
            
            do {
                return try parse(data: data)
            } catch {
                print(error)
            }
        }
        
        return Alarms(alarms: [])
    }
    
    
    private static func readLocalJSONFile(for name: String) -> Data? {
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
    
    // Parse the received data object and decode into alarms
    private static func parse(data: Data) throws -> Alarms  {
        let realm = try Realm()
        let decodedAlarms = try JSONDecoder().decode(Alarms.self, from: data)
        
        return decodedAlarms
    }
}
