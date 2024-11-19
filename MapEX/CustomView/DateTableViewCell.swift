//
//  DateTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit

class DateTableViewCell: UITableViewCell {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let today = Date()
        let calendar = Calendar.current
        let data = UserDefaults.standard.data(forKey: "staytime")!
        let timeInterval = TimeInterval.decode(data: data)
        datePicker.date = calendar.date(bySettingHour: timeInterval!.hours, minute: timeInterval!.minutes, second: 0, of: today)!
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        let selectedDate = datePicker.date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)
        let timeInterval = TimeInterval(hour: components.hour!, minute: components.minute!)
        let data = timeInterval.encode()
        UserDefaults.standard.set(data, forKey: "staytime")
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
    }
}
