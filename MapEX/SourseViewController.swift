//
//  SourseViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit
import MapKit

class SourseViewController:UIViewController, UITableViewDataSource,UITableViewDelegate{
    
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var boolSwitch: UISwitch!
    
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    private var items:[FixedItem]?
    private var currentItem:ItemProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setTitleView(withTitle: "出発地", subTitile: "")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "CheckTableViewCell", bundle: nil), forCellReuseIdentifier: "CheckTableViewCell")
        if let data = UserDefaults.standard.data(forKey: "sourse"),
           let sourse = NilItem.decode(data: data){
            self.currentItem = sourse
            boolSwitch.isOn = !(sourse is NilItem)
            tableView.isHidden = sourse is NilItem
        }
        let swipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGestureRecognizer.edges = .left // 画面左端でのスワイプを検知
        view.addGestureRecognizer(swipeGestureRecognizer)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint.constant = CGFloat(tableView.contentSize.height)
    }
    
    @IBAction func boolSwitchChanged(_ sender: UISwitch) {
        tableView.isHidden = !boolSwitch.isOn
        if boolSwitch.isOn{
            if let data = UserDefaults.standard.data(forKey: "staytime"),
               let stayTime = TimeInterval.decode(data: data){
                self.currentItem = SelectableItem(name: "現在地", stayTime: stayTime)
                let data = self.currentItem?.encode()
                UserDefaults.standard.set(data, forKey: "sourse")
            }
        }else{
            self.currentItem = NilItem()
            let data = self.currentItem?.encode()
            UserDefaults.standard.set(data, forKey: "sourse")
        }
        tableView.reloadData()
        appDelegate.initDestinations()
        
    }
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    @objc func handleSwipeGesture(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            // 画面をdismissする処理
            dismiss(animated: false, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + appDelegate.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckTableViewCell", for: indexPath) as! CheckTableViewCell
        switch indexPath.item{
        case 0:
            let data = UserDefaults.standard.data(forKey: "staytime")!
            let stayTime = TimeInterval.decode(data: data)!
            let item = SelectableItem(name: "現在地", stayTime: stayTime,pointOfInterestCategory: nil)
            cell.config(item: item, selected: item.name == currentItem?.name)
        default:
            let item = appDelegate.favorites.get(at: indexPath.item-1)
            cell.config(item: item, selected: item.name == currentItem?.name)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.item{
        case 0:
            let staytimeData = UserDefaults.standard.data(forKey: "staytime")!
            let stayTime = TimeInterval.decode(data: staytimeData)!
            self.currentItem = SelectableItem(name: "現在地", stayTime: stayTime, pointOfInterestCategory: nil)
            let data = self.currentItem?.encode()
            UserDefaults.standard.set(data, forKey: "sourse")
        default:
            self.currentItem = appDelegate.favorites.get(at: indexPath.item-1)
            let data = self.currentItem?.encode()
            UserDefaults.standard.set(data, forKey: "sourse")
        }
        tableView.reloadData()
        appDelegate.initDestinations()
        
    }
}
