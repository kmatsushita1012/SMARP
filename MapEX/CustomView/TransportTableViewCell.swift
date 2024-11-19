//
//  TransportTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit
import MapKit

class TransportTableViewCell: UITableViewCell {
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        var transportActions = [UIMenuElement]()
        for transportType in MKDirectionsTransportType.allCases{
            let action = UIAction(title: transportType.text, handler: { [weak self] _ in
                let data = transportType.encode()
                UserDefaults.standard.set(data, forKey: "transport")
                self!.button.setTitle(transportType.text, for: .normal)
                self!.button.setImage(transportType.image, for: .normal)
            })
            transportActions.append(action)
        }
        button.menu = UIMenu(title: "", options: .displayInline, children: transportActions)
        button.showsMenuAsPrimaryAction = true
        // ボタンの表示を変更
        let data = UserDefaults.standard.data(forKey: "transport")!
        let defaultTransportType = MKDirectionsTransportType.decode(data: data)
        button.setTitle(defaultTransportType?.text, for: .normal)
        button.setImage(defaultTransportType?.image, for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
}
