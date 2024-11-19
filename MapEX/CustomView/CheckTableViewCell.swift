//
//  CheckTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit
import MapKit

class CheckTableViewCell: UITableViewCell {

    
    @IBOutlet var checkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func config(item:ItemProtocol,selected:Bool){
        checkImageView.isHidden = !selected
        titleLabel.text = item.name
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
}
