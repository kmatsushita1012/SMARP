//
//  AdressTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/19.
//

import UIKit
import MapKit

class LinkTableViewCell: UITableViewCell,UITextViewDelegate{
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textView.delegate = self
        // Initialization code
    }
    
    func config(item: MKMapItem, type:UIDataDetectorTypes){
        typeLabel.text = type.text
        self.textView.dataDetectorTypes = type
        switch type {
        case .address:
            Task{
                do{
                    self.textView.text = try await MapTools.getAddress(from: item)
                }catch{
                    if let error = error as? CustomError{
                        let alertController = UIAlertController(title: "エラー", message: error.text, preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .default)
                        alertController.addAction(action)
                    }
                }
            }
        case .link:
            self.textView.text = item.url?.absoluteString
        case .phoneNumber:
            self.textView.text = item.phoneNumber
        default:
            break
        }
        textView.isScrollEnabled = false // スクロールを無効にする
        textView.isEditable = false
        textView.isSelectable = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "tel" {
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        } else if URL.scheme == "http" || URL.scheme == "https" {
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        }
        return false
    }
    
}
