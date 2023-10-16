//
//  AlertSettingsViewController.swift
//  TradingAlarm
//
//  Created by John Ingato on 9/22/23.
//

import UIKit

class AlarmSettingsViewController: UIViewController {
    
    let viewModel = AlarmSettingsViewModel()
    
    @IBOutlet weak var addAlarmButton: UIButton!
    
    // Alarm Editor
    @IBOutlet weak var alarmEditor: UIView!
    @IBOutlet weak var alarmEditorTopConstraint: NSLayoutConstraint!
    
    var alarmEditorViewController: AddAlarmViewController!
    
    @IBAction func addAlarm(_ sender: UIButton) {
        self.showAlarmEditor()
    }
    
    func showAlarmEditor(_ show: Bool = true) {
        self.alarmEditorTopConstraint.constant = show ? 0 : view.frame.maxY
        if show {
            self.alarmEditorViewController?.prepareForEditing()
        } else {
            self.alarmEditorViewController.prepareToCloseEditing()
        }
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? AddAlarmViewController {
            alarmEditorViewController = dest
            dest.delegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.alarmEditorTopConstraint.constant = view.frame.maxY
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

extension AlarmSettingsViewController: PresentationObserver {
    func onAlarmEditingCompleted(alarm: Alarm?) {
        showAlarmEditor(false)
    }
}
