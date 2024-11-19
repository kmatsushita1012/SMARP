//
//  TransitTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/14.
//

import UIKit

class TransitTableViewCell: UITableViewCell {
    @IBOutlet weak var detailButton: UIButton!
    var delegate:ItineraryDelegate?
    var directionParam:DirectionParam?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func config(delegate:ItineraryDelegate,directionParam:DirectionParam){
        self.delegate = delegate
        self.directionParam = directionParam
    }
    @IBAction func detailButtonTapped(_ sender: UIButton) {
        var components = URLComponents(string: "https://www.google.com/maps/dir/")!
            components.queryItems = [
                URLQueryItem(name: "api", value: "1"),
                URLQueryItem(name: "origin", value: directionParam?.origin.text),
                URLQueryItem(name: "destination", value: directionParam?.destination.text),
                URLQueryItem(name: "travelmode", value: "transit"),
            ]
        if let dateText = directionParam?.depatureTime.text{
            let alertController = UIAlertController(title: "出発時刻:\(dateText)", message: "GoogleMapが開きます。GoogleMapで時間を指定してリンクを作成するのは規約違反となる恐れがあるため、GoogleMapが開いたあとご自身で時間を指定してください。", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default,handler: { _ in
                if let url = components.url{
                    UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey : Any](), completionHandler: nil)
                }
                
            })
            alertController.addAction(action)
            delegate?.showAlertController(alertController: alertController)
        }
        
    }
    
    @IBAction func questionButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "お知らせ", message: "電車/バスの経路検索は、Appleが提供するサービスの都合上予想出発/到着時刻のみの提供となっております.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        delegate?.showAlertController(alertController: alertController)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        
    }
    
}
