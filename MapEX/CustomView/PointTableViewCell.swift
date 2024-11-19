//
//  PointTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/10.
//

import UIKit

class PointTableViewCell: UITableViewCell {
    
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stayTimeLabel: UILabel!
    private var item: FixedItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        stayTimeLabel.layer.cornerRadius = 10 // 角の丸みを決定します
        stayTimeLabel.layer.masksToBounds = true
        // Initialization code
    }
    
    func config(item:PointItem,isEnd:Bool){
        self.item = item
        titleLabel.text = item.name
        if isEnd{
            stayTimeLabel.isHidden = true
        }else{
            stayTimeLabel.text = item.stayTime?.text
        }
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
}
