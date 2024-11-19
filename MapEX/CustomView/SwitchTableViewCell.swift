//
//  SwitchTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var boolSwitch: UISwitch!
    
    var key:String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func config(title:String,key:String){
        titleLabel.text = title
        boolSwitch.isOn = UserDefaults.standard.bool(forKey: key)
        self.key = key
    }

    @IBAction func switchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(boolSwitch.isOn, forKey: key!)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
    }
}
