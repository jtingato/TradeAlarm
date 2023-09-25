//
//  AlertSettingsViewController.swift
//  TradingAlarm
//
//  Created by John Ingato on 9/22/23.
//

import UIKit

class AlarmSettingsViewController: UIViewController {

    let viewModel = AlarmSettingsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension AlarmSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.alarmsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmSettingSwitched", for: indexPath) as? AlarmSettingTableViewCell {
            
            let thisAlarm = viewModel.alarmsList[indexPath.row]
            cell.populateCell(thisAlarm)
            
            return cell
        }
        
        return UITableViewCell()
    }
}
