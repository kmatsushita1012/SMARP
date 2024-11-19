//
//  ProceedableTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit

class ProceedableTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    var vc:UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func config(title:String,selected:String){
        titleLabel.text = title
        selectedLabel.text = selected
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
}
