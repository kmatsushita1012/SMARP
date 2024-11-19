//
//  MapTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/19.
//

import UIKit
import MapKit

class MapAppTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    var app:ExternalApp?
    var item:MKMapItem?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func config(item:MKMapItem,app:ExternalApp){
        self.item = item
        self.app = app
        label.text = "\"\(app.text)\"で開く"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    @IBAction func handleOpenButton(_ sender: UIButton) {
        switch app {
        case .Google:
            let zoom = 15
            let latitude = Float(item!.placemark.coordinate.latitude)
            let longitude = Float(item!.placemark.coordinate.longitude)
            if let name = item?.name,
                let url = URL(string: "comgooglemaps://?q=\(name)ー&center=\(latitude),\(longitude)&zoom=\(zoom)"){
                UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey : Any](), completionHandler: nil)
            }

        case .Apple:
            let region = MKCoordinateRegion(center: item!.placemark.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            let options: [String : Any] = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)
            ]
            if let name = item?.name{
                item?.name = name
                item!.openInMaps(launchOptions: options)
            }
        case .none:
            break
        }
    }
    
}
