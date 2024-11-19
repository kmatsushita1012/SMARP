//
//  DestinationCollectionViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/27.
//

import UIKit
import MapKit

class DestinationCollectionViewCell: UICollectionViewListCell {
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var titleLabel: UILabel! // 例えば、xib 内のラベル
    @IBOutlet weak var staytimeLabel: UILabel!
    @IBOutlet weak var transportLabel: UILabel!
    @IBOutlet var toggleButton: UIButton! // xib 内のボタン
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var transportButton: UIButton!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var block: Block?
    var delegate: DestinationDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        
        widthConstraint.constant = UIScreen.main.bounds.width
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        titleLabel.addGestureRecognizer(tapGesture)
        titleLabel.isUserInteractionEnabled = true
        
    }
    // 初期化メソッド
    func config(block:Block,delegate:DestinationDelegate){
        self.block = block
        self.delegate = delegate
        self.setCorner()
        
        transportButton.setTitle(block.transportType.text, for: .normal)
        let today = Date()
        let calendar = Calendar.current
        if block.first is NilItem{
            titleLabel.text = ""
            let data = UserDefaults.standard.data(forKey: "staytime")!
            let stayTime = TimeInterval.decode(data: data)
            datePicker.date = calendar.date(bySettingHour: stayTime!.hours, minute: stayTime!.minutes, second: 0, of: today)!
        }else{
            if let name = block.first?.name{
                titleLabel.text = " \(name)"
            }
            if let staytime = block.first?.stayTime{
                datePicker.date = calendar.date(bySettingHour: staytime.hours, minute: staytime.minutes, second: 0, of: today)!
            }
        }
        var transportActions = [UIMenuElement]()
        for transportation in MKDirectionsTransportType.allCases{
            let action = UIAction(title: transportation.text, handler: { [weak self] _ in
                block.transportType = transportation
                self!.transportButton.setTitle(block.transportType.text, for: .normal)
                self!.transportButton.setImage(block.transportType.image, for: .normal)
            })
            transportActions.append(action)
        }
        transportButton.menu = UIMenu(title: "", options: .displayInline, children: transportActions)
        transportButton.showsMenuAsPrimaryAction = true
        // ボタンの表示を変更
        transportButton.setTitle(block.transportType.text, for: .normal)
        transportButton.setImage(block.transportType.image, for: .normal)
        
        var menuActions = [UIMenuElement]()
        let deleteAction = UIAction(title: "削除",attributes: .destructive, handler: { [weak self] _ in
            let index = self!.appDelegate.destinations.firstIndex(block: block)
            _ = self!.appDelegate.destinations.remove(at: index)
            self!.delegate!.reloadData()
        })
        
        menuActions.append(deleteAction)
        let addBlockAction = UIAction(title: "ブロックを追加", handler: { [weak self] _ in
            let data = UserDefaults.standard.data(forKey: "transport")!
            let transportType = MKDirectionsTransportType.decode(data: data)!
            let newBlock = Block(items: [NilItem()],transportType: transportType)
            let index = self!.appDelegate.destinations.firstIndex(block: block)
            self!.appDelegate.destinations.insert(at:index+1 , block: newBlock)
            self!.delegate!.reloadData()
        })
        menuActions.append(addBlockAction)
        let addItemAction = UIAction(title: "アイテムを追加", handler: { [weak self] _ in
            block.append(item: NilItem())
            block.isOpened = true
            let index = self!.appDelegate.destinations.firstIndex(block: block)
            let indexPath = IndexPath(item: index, section: 0)
            self!.delegate!.reloadItem(indexPath: indexPath)
        })
        menuActions.append(addItemAction)
        
        menuButton.menu = UIMenu(title: "", options: .displayInline, children: menuActions)
        menuButton.showsMenuAsPrimaryAction = true
        
        if block.isOpened{
            toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        }else{
            toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // セルの幅をコレクションビューの幅に合わせる
        if superview is UICollectionView {
            frame.origin.x = 0
        }
    }

    
    override var intrinsicContentSize: CGSize {
        if block!.isOpened {
            return CGSize(width: UIScreen.main.bounds.width, height: 137)
        } else {
            return CGSize(width: UIScreen.main.bounds.width, height: 51)
        }
    }
        
    
    // 開閉を切り替えるメソッド
    @IBAction func toggleButtonTapped(_ sender: UIButton) {
        block!.isOpened.toggle()
        let index = self.appDelegate.destinations.firstIndex(block: block!)
        let indexPath = IndexPath(item: index, section: 0)
        delegate?.reloadItem(indexPath: indexPath)
        if block!.isOpened{
            toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        }else{
            toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
        self.setCorner()
    }

    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        let selectedDate = datePicker.date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)
        var item = block?.get(at: 0)
        item?.stayTime = TimeInterval(hour: components.hour!, minute: components.minute!)
    }
    
    @objc func labelTapped(sender: UITapGestureRecognizer) {
        delegate?.shiftSearchVC(block: block!, item:  (block?.first)!)
    }
    func setCorner(){
        // Initialization code
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.bottomRight, .topRight], cornerRadii: CGSize(width: 15, height: 15))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}

protocol TimeSelectableCellDelegate{
    func returnTime(time: TimeInterval)
}
