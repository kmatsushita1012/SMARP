//
//  FavoriteViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/16.
//

import UIKit
import MapKit

class FavoriteViewController:UIViewController,UITableViewDataSource,UITableViewDelegate,FavoriteDelegate{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    var delegate: BaseVCDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setTitleView(withTitle: "お気に入り", subTitile: "")
        tableView.dataSource = self
        tableView.delegate = self
        let swipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGestureRecognizer.edges = .left // 画面左端でのスワイプを検知
        view.addGestureRecognizer(swipeGestureRecognizer)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint.constant = CGFloat(appDelegate.favorites.count*44)
    }
    func config(delegate:BaseVCDelegate){
        self.delegate = delegate
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    @objc func handleSwipeGesture(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            // 画面をdismissする処理
            navigationController?.popViewController(animated: true)
        }
    }
    func showEditingAlert(index:Int) {
        let alertController = UIAlertController(title: "登録名を変更", message: nil, preferredStyle: .alert)
                
        alertController.addTextField { [self] (textField) in
            let item = appDelegate.favorites.get(at: index)
            textField.placeholder = item.name
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        let resetAction = UIAlertAction(title: "リセット", style: .default) { [self] (_) in
            let item = self.appDelegate.favorites.get(at: index)
            item.name = nil
            tableView.reloadData()
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { [self] (_) in
            if let textField = alertController.textFields?.first {
                if let newText = textField.text {
                    let item = self.appDelegate.favorites.get(at: index)
                    item.name = newText
                    tableView.reloadData()
                    self.appDelegate.favorites.save()
                }
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(resetAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = appDelegate.favorites.get(at: indexPath.row).name
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = appDelegate.favorites.get(at: indexPath.item)
        navigationController?.dismiss(animated: true) { [self] in
            if let detailVc = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController{
                detailVc.config(delegate: delegate!, method: .fromSearch, item: item)
                delegate!.showSemiModalView(vc: detailVc)
            }
        }
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "削除") { [self] (action, view, completion) in
            appDelegate.favorites.remove(at: indexPath.item)
            tableView.reloadData()
            heightConstraint.constant = CGFloat(appDelegate.favorites.count*44)
            self.view.layoutIfNeeded()
            completion(true)
        }
        let editAction = UIContextualAction(style: .normal, title: "名称") { [self] (action, view, completion) in
            showEditingAlert(index: indexPath.item)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction,editAction])
        return configuration
    }
    func reloadData() {
        tableView.reloadData()
        heightConstraint.constant = CGFloat(tableView.contentSize.height)
    }
}
protocol FavoriteDelegate {
    func reloadData()
}
