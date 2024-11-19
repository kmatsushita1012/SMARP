//
//  SearchViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/18.
//

import UIKit
import FloatingPanel
import MapKit

class SearchViewController:UIViewController,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    var results = [ItemProtocol]()
    var method :SearchMethod?
    var delegate: BaseVCDelegate?
    var errorCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorCounter = 0
        tableView.dataSource = self
        tableView.delegate = self
        textField.placeholder = "検索"
        textField.delegate = self
        textField.attributedPlaceholder = NSAttributedString(string: "検索", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        textField.becomeFirstResponder()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        if let stayTimeData = UserDefaults.standard.data(forKey: "staytime"),
           let stayTime = TimeInterval.decode(data: stayTimeData){
            let item = SelectableItem(name: "現在地", stayTime: stayTime)
            results.append(item)
        }
        results.append(contentsOf: appDelegate.favorites.items)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func config(method:SearchMethod,delegate:BaseVCDelegate) {
        self.method = method
        self.delegate = delegate
    }
    @objc func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        // キーボードの高さを取得
        let keyboardHeight = keyboardFrame.height
        
        // FloatingPanelの高さを調整
        if let parentVC = self.parent as? FloatingPanelController {
            parentVC.move(to: .half, animated: true)
            parentVC.surfaceView.frame.origin.y -= keyboardHeight / 2
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // キーボードが隠れたとき、FloatingPanelの位置を元に戻す
        if let parentVC = self.parent as? FloatingPanelController {
            parentVC.move(to: .half, animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        if !UserDefaults.standard.bool(forKey: "suggest"){
            Task { @MainActor in
                await search(text: textField.text!)
                
            }
        }
        return true
    }
    @IBAction func editingChanged(_ sender: Any) {
        if UserDefaults.standard.bool(forKey: "suggest"){
            Task { @MainActor in
                await search(text: textField.text!)
            }
        }
    }
    func search(text: String) async{
        results = [ItemProtocol]()
        //TODO Select検索追加
        let region = delegate?.getShowingRegion()
        let mkItems:[MKMapItem]
        do{
            mkItems = try await MapTools.search(query: text, region: region!)
        }catch{
            errorCounter += 1
            if  errorCounter == 10,
                let error = error as? CustomError{
                let alertController = UIAlertController(title: "エラー", message: error.text, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(action)
                self.present(alertController, animated: true)
                textField.text  = ""
            }
            return
        }
        errorCounter = 0
        for mkItem in mkItems{
            if let stayTimeData = UserDefaults.standard.data(forKey: "staytime"),
               let stayTime = TimeInterval.decode(data: stayTimeData){
                let item = FixedItem(item:mkItem, stayTime: stayTime)
                results.append(item)
            }
        }
        DispatchQueue.main.async { [self] in
            tableView.reloadData()
        }
        
    }
    @IBAction func dismissButton(_ sender: UIButton) {
        delegate?.dismissSemiModalView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item < results.count{
            let item =  results[indexPath.item]
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = item.name
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item >= results.count{
            tableView.reloadData()
            return
        }
        var item = results[indexPath.item]
        switch self.method{
        case .fromDestinetions(let i,let j):
            if appDelegate.destinations.getItem(blockIndex: i, itemIndex: j) is NilItem{
            }else if let replacedItem = appDelegate.destinations.getItem(blockIndex: i, itemIndex: j){
                item.stayTime = replacedItem.stayTime
            }
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController
            vc?.config(delegate: self.delegate!)
            appDelegate.destinations.replaceItem(item: item, blockIndex: i, itemIndex: j)
            delegate?.showSemiModalView(vc: vc!)
        default:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController{
                vc.config(delegate:self.delegate!,method: self.method!, item: item)
                delegate?.showSemiModalView(vc: vc)
            }
        }
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "詳細") { [self] (action, view, completion) in
            let item = results[indexPath.item]
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController{
                vc.config(delegate:self.delegate!,method: self.method!, item: item)
                delegate?.showSemiModalView(vc: vc)
            }
            completion(true)
        }
        action.backgroundColor = .systemBlue
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    
}
