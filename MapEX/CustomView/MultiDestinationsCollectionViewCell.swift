//
//  MultiDestinationsCollectionViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/03.
//

import UIKit
import MapKit

class MultiDestinationsCollectionViewCell: UICollectionViewListCell,UITableViewDataSource,UITableViewDelegate,MultiDestinationsDelegate{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet weak var transportLabel: UILabel!
    @IBOutlet var toggleButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var transportButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    var block: Block?
    var delegate: DestinationDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topRight, .bottomRight], cornerRadii: CGSize(width: 10, height: 10))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        widthConstraint.constant = UIScreen.main.bounds.width
    }
    
    func config(block:Block,delegate:DestinationDelegate) {
        self.block = block
        self.delegate = delegate
        self.setCorner()
        let index = appDelegate.destinations.firstIndex(block: block)
        titleLabel.text = " グループ\(index+1)"
        transportButton.setTitle(block.transportType.text, for: .normal)
        
        var transportActions = [UIMenuElement]()
        for item in MKDirectionsTransportType.allCases{
            let action = UIAction(title: item.text, handler: { [weak self] _ in
                block.transportType = item
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
            self!.layoutIfNeeded()
        })
        menuActions.append(deleteAction)
        let addBlockAction = UIAction(title: "ブロックを追加", handler: { [weak self] _ in
            let data = UserDefaults.standard.data(forKey: "transport")!
            let transportType = MKDirectionsTransportType.decode(data: data)!
            let newBlock = Block(items: [NilItem()],transportType: transportType)
            let index = self!.appDelegate.destinations.firstIndex(block: block)
            self!.appDelegate.destinations.insert(at: index+1, block: newBlock)
            self!.delegate!.reloadData()
            self!.layoutIfNeeded()
        })
        menuActions.append(addBlockAction)
        let addItemAction = UIAction(title: "アイテムを追加", handler: { [weak self] _ in
            block.append(item: NilItem())
            let index = self!.appDelegate.destinations.firstIndex(block: block)
            let indexPath = IndexPath(item: index, section: 0)
            delegate.reloadItem(indexPath: indexPath)
            self!.tableView.reloadData()
            self!.layoutIfNeeded()
           
        })
        menuActions.append(addItemAction)
        
        menuButton.menu = UIMenu(title: "", options: .displayInline, children: menuActions)
        menuButton.showsMenuAsPrimaryAction = true
        
        if block.isOpened{
            toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        }else{
            toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "DestinationTableViewCell", bundle: nil), forCellReuseIdentifier: "DestinationTableViewCell")
        tableView.isScrollEnabled = false
        tableView.reloadData()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // セルの幅をコレクションビューの幅に合わせる
        if superview is UICollectionView {
            frame.origin.x = 0
        }
        heightConstraint.constant = CGFloat(94 * block!.count)
    }
    // 開閉を切り替えるメソッド
    @IBAction func toggleButtonTapped(_ sender: UIButton) {
        block!.isOpened.toggle()
        let index = appDelegate.destinations.firstIndex(block: block!)
        let indexPath = IndexPath(item: index, section: 0)
        delegate?.reloadItem(indexPath: indexPath)
        if block!.isOpened{
            toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            tableView.reloadData()
        }else{
            toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
        self.setCorner()
    }
    
    func setCorner(){
        // Initialization code
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.bottomRight, .topRight], cornerRadii: CGSize(width: 15, height: 15))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return block!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationTableViewCell", for: indexPath) as! DestinationTableViewCell
        cell.config(item: block?.get(at: indexPath.item), delegate: delegate!,multiDestinationsDelegate: self)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 94.0 // セルの高さを指定します
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        return
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let action = UIContextualAction(style: .destructive, title: "削除") { [self] (action, view, completion) in
            _ = block?.remove(at: indexPath.item)
            delegate?.reloadData()
            completion(true)
        }
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    func getSuperBlock()->Block{
        return block!
    }
    func shiftSearchVC(item:ItemProtocol) {
        delegate?.shiftSearchVC(block: block!, item: item)
    }
}

protocol MultiDestinationsDelegate {
    func getSuperBlock()->Block
    func shiftSearchVC(item:ItemProtocol)
}
