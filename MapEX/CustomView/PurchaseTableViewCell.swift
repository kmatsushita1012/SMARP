//
//  TableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/05/14.
//

import UIKit

class PurchaseTableViewCell: UITableViewCell {
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet var purchaseButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let isPurchased =  UserDefaults.standard.bool(forKey: "IAP.removeAds")
        if !isPurchased{
            self.purchaseButton.isEnabled = true
            self.purchaseButton.setTitle("購入", for: .normal)
        }else{
            self.purchaseButton.isEnabled = false
            self.purchaseButton.setTitle("購入済み", for: .normal)
            
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func purchaseButtonTapped(_ sender: UIButton) {
        //TODO
        if !UserDefaults.standard.bool(forKey: "removeAds"){
            IAPManager.shared.buy(productIdentifier: appDelegate.removeAdsId)
        }
        
    }
    @IBAction func restoreButtonTapped(_ sender: UIButton) {
        IAPManager.shared.restore()
        
    }
}
