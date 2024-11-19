//
//  DestinationTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/03.
//

import UIKit

class DestinationTableViewCell: UITableViewCell{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    var item: ItemProtocol?
    var delegate: DestinationDelegate?
    var multiDestinationsDelegate:MultiDestinationsDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        titleLabel.addGestureRecognizer(tapGesture)
        titleLabel.isUserInteractionEnabled = true
    }
    
    func config(item:ItemProtocol?,delegate:DestinationDelegate,multiDestinationsDelegate:MultiDestinationsDelegate){
        self.delegate = delegate
        self.multiDestinationsDelegate = multiDestinationsDelegate
        self.item = item
        let today = Date()
        let calendar = Calendar.current
        if let item = self.item,
           let name = item.name,
            let stayTime = item.stayTime{
            titleLabel.text = name
            datePicker.date = calendar.date(bySettingHour: stayTime.hours, minute: stayTime.minutes, second: 0, of: today)!
        }else{
            titleLabel.text = ""
            let data = UserDefaults.standard.data(forKey: "staytime")!
            let stayTime = TimeInterval.decode(data: data)
            datePicker.date = calendar.date(bySettingHour: stayTime!.hours, minute: stayTime!.minutes, second: 0, of: today)!
        }
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        let selectedDate = datePicker.date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)
        item?.stayTime = TimeInterval(hour: components.hour!, minute: components.minute!)
    }
    @objc func labelTapped(sender:UITapGestureRecognizer){
        multiDestinationsDelegate?.shiftSearchVC(item: item!)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
