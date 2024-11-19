//
//  SettingsViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit
import SafariServices

class SettingsViewController:UIViewController,UITableViewDataSource,UITableViewDelegate{
    
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    var delegate:BaseVCDelegate?
    
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setTitleView(withTitle: "設定", subTitile: "")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "DateTableViewCell", bundle: nil), forCellReuseIdentifier: "DateTableViewCell")
        tableView.register(UINib(nibName: "TransportTableViewCell", bundle: nil), forCellReuseIdentifier: "TransportTableViewCell")
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "ProceedableTableViewCell", bundle: nil), forCellReuseIdentifier: "ProceedableTableViewCell")
        tableView.register(UINib(nibName: "PurchaseTableViewCell", bundle: nil), forCellReuseIdentifier: "PurchaseTableViewCell")
        tableView.layer.cornerRadius = 10
        let swipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGestureRecognizer.edges = .left // 画面左端でのスワイプを検知
        view.addGestureRecognizer(swipeGestureRecognizer)
        IAPManager.shared.delegate = self
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //TODO374に
        heightConstraint.constant = 374.0
    }
    func config(delegate:BaseVCDelegate){
        self.delegate = delegate
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
    func showAlertController(title:String,message:String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        self.present(alertController, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //滞在時間 交通機関 クリア 出発地 お気に入り 購入
        return 8
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.item{
        
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DateTableViewCell", for: indexPath) as! DateTableViewCell
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransportTableViewCell", for: indexPath) as! TransportTableViewCell
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProceedableTableViewCell", for: indexPath) as! ProceedableTableViewCell
            if let data = UserDefaults.standard.data(forKey: "sourse"),
               let sourse = NilItem.decode(data: data){
                if sourse is NilItem{
                    cell.config(title: "出発地点", selected: "なし")
                }else{
                    cell.config(title: "出発地点", selected: sourse.name!)
                }
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProceedableTableViewCell", for: indexPath) as! ProceedableTableViewCell
            cell.config(title: "お気に入り", selected: "")
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            
            cell.config(title: "クリアボタンの確認", key: "clear")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            cell.config(title: "検索のサジェスト", key: "suggest")
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "お問い合わせ"
            return cell
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseTableViewCell", for: indexPath) as! PurchaseTableViewCell
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            return cell
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.item{
        case 2:
            return 44.0
        case 3:
            return 44.0
        case 4:
            return 48.0
        case 5:
            return 48.0
        case 6:
            return 44.0
        case 7:
            return 44.0
        default:
            return 51.0
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.item{
        case 2:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SourseViewController") as? SourseViewController{
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav,animated: true)
            }
        case 3:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "FavoriteViewController") as? FavoriteViewController{
                vc.config(delegate: self.delegate!)
                navigationController?.pushViewController(vc, animated: true)
            }
        case 6:
            if let url = URL(string: "https://forms.gle/VWaaBkT6v47mPtXk9") {
                let safariVC = SFSafariViewController(url: url)
                present(safariVC, animated: true)
            }
            
        default:
            tableView.deselectRow(at: indexPath, animated: true)
            break
        }
    }
}

extension SettingsViewController: IAPManagerDelegate {
    //購入が完了した時
    func iapManagerDidFinishPurchased() {
        //購入完了をユーザに知らせるアラートを表示
        UserDefaults.standard.setValue(true, forKey: "IAP.removeAds")
        
        self.showAlertController(title: "購入完了", message: "ご利用ありがとうございます。以前購入し復元を行った方にもこのメッセージが表示される場合がございます。")
        
        let indexPath = IndexPath(item: 7, section: 0)
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    //購入に失敗した時
    func iapManagerDidFailedPurchased() {
        //購入失敗をユーザに知らせるアラートなど
        self.showAlertController(title: "エラー", message: "購入に失敗しました。")
    }
    //リストアが完了した時
    func iapManagerDidFinishRestore(_ productIdentifiers: [String]) {
        for identifier in productIdentifiers {
            if identifier == appDelegate.removeAdsId {
                //リストア完了をユーザに知らせるアラートを表示
                //UserDefaultにBool値を保存する(例:isPurchased = true)
                //広告を消す処理など
                UserDefaults.standard.setValue(true, forKey: "IAP.removeAds")
                self.showAlertController(title: "復元完了", message: "\"広告の削除\"が復元されました。")
                
                let indexPath = IndexPath(item: 7, section: 0)
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        //Indicatorを隠す処理
    }
    //1度もアイテム購入したことがなく、リストアを実行した時
    func iapManagerDidFailedRestoreNeverPurchase() {
        //先に購入をお願いするアラートを表示
        self.showAlertController(title: "エラー", message: "購入したアイテムが存在しません。")
        //Indicatorを隠す処理
    }
    //リストアに失敗した時
    func iapManagerDidFailedRestore() {
        //リストア失敗をユーザに知らせるアラートを表示
        self.showAlertController(title: "エラー", message: "復元に失敗しました。")
        //Indicatorを隠す処理
    }
    //特殊な購入時の延期の時
    func iapManagerDidDeferredPurchased() {
        //購入失敗をユーザに知らせるアラートを表示
        //Indicatorを隠す処理
        self.showAlertController(title: "エラー", message: "購入に失敗しました。")
    }
}
