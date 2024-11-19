//
//  DestinetionsViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/18.
//

import UIKit
import MapKit

class DestinationsViewController: UIViewController, DestinationDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UICollectionViewDragDelegate,UICollectionViewDropDelegate{
    
    var  appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var enumButton: UIButton!
    @IBOutlet weak var transportButton: UIButton!
    var isOpenedStatus: [Bool]?
    var selectedTime: TimeInterval?
    var draggedView: UIView?
    var initialIndex: Int?
    var delegate: BaseVCDelegate?
    var destinationCellDelegate: TimeSelectableCellDelegate?
    let dataList = [[Int](0...23), [Int](0...59)]
    var annotations = [MKAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for item in appDelegate.destinations.items{
            if let item = item as? FixedItem{
                let annotation = CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name, glyphText: nil, category: item.pointOfInterestCategory)
                delegate?.addAnnotation(annotation: annotation,selected: false)
                self.annotations.append(annotation)
            }
        }
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0) // 余白を設定する
        }
        collectionView.register(UINib(nibName: "DestinationCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DestinationCollectionViewCell")
        collectionView.register(UINib(nibName: "MultiDestinationsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MultiDestinationsCollectionViewCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.isScrollEnabled = true
        
        isOpenedStatus = Array(repeating: false, count: appDelegate.destinations.count)
        switch appDelegate.destinations.enumDate{
        case .departure(_):
            enumButton.setTitle("出発", for: .normal)
        case .arrive(_):
            enumButton.setTitle("到着", for: .normal)
        }
        datePicker.date = appDelegate.destinations.enumDate.date
        var actions = [UIMenuElement]()
        let arriveAction = UIAction(title: "到着", handler: { [weak self] _ in
            self!.appDelegate.destinations.enumDate = .arrive(self!.appDelegate.destinations.enumDate.date)
            self!.enumButton.setTitle("到着", for: .normal)
            
        })
        actions.append(arriveAction)
        let depatureAction = UIAction(title: "出発", handler: { [weak self] _ in
            self!.appDelegate.destinations.enumDate = .departure(self!.appDelegate.destinations.enumDate.date)
            self!.enumButton.setTitle("出発", for: .normal)
        })
        actions.append(depatureAction)
        enumButton.menu = UIMenu(title: "", options: .displayInline, children: actions)
        enumButton.showsMenuAsPrimaryAction = true
        
        var transportActions = [UIMenuElement]()
        for transportation in MKDirectionsTransportType.allCases{
            let action = UIAction(title: transportation.text, handler: { [weak self] _ in
                for block in self!.appDelegate.destinations.blocks{
                    block.transportType = transportation
                    self!.transportButton.setTitle(block.transportType.text, for: .normal)
                    self!.transportButton.setImage(block.transportType.image, for: .normal)
                    self!.collectionView.reloadData()
                }
            })
            transportActions.append(action)
        }
        transportButton.menu = UIMenu(title: "一括変更", options: .displayInline, children: transportActions)
        transportButton.showsMenuAsPrimaryAction = true
        // ボタンの表示を変更
        let data = UserDefaults.standard.data(forKey: "transport")!
        let transportType = MKDirectionsTransportType.decode(data: data)!
        transportButton.setTitle(transportType.text, for: .normal)
        transportButton.setImage(transportType.image, for: .normal)
    }
    
    func config(delegate:BaseVCDelegate){
        self.delegate = delegate
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.removeAnnotations(annotations: self.annotations)
        self.annotations.removeAll()
    }
    
    @IBAction func plusButtonTapped(_ sender: Any) {
        let data = UserDefaults.standard.data(forKey: "transport")!
        let transportType = MKDirectionsTransportType.decode(data: data)!
        let newBlock = Block(items: [NilItem()],transportType: transportType)
        self.appDelegate.destinations.append(block: newBlock)
        collectionView.reloadData()
    }
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        
        if !UserDefaults.standard.bool(forKey: "clear"){
            let alertController = UIAlertController(title: "確認", message: "本当にリストをクリアしますか？", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
            let confirmAction = UIAlertAction(title: "はい", style: .default) { _ in
                self.appDelegate.initDestinations()
                self.collectionView.reloadData()
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }else{
            self.appDelegate.initDestinations()
            collectionView.reloadData()
        }
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        delegate?.dismissSemiModalView()
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        switch appDelegate.destinations.enumDate {
        case .departure(_):
            appDelegate.destinations.enumDate = .departure(datePicker.date)
        case .arrive(_):
            appDelegate.destinations.enumDate = .arrive(datePicker.date)
        }
        print(appDelegate.destinations.enumDate)
    }
    @IBAction func itineraryButtonTapped(_ sender: UIButton) {
        delegate?.showItineraryVC(type: .Advanced)
    }
    
    func updateItem(coordinator: UICollectionViewDropCoordinator, destinationIndex: IndexPath, collectionView: UICollectionView) {
        guard let item = coordinator.items.first else { return }
        guard let sourceIndex = item.sourceIndexPath else { return }
        // セルと配列の更新
        collectionView.performBatchUpdates({
            let block = appDelegate.destinations.remove(at: sourceIndex.item)
            appDelegate.destinations.insert(at: destinationIndex.item, block: block)
            // セルの更新
            if sourceIndex.item < destinationIndex.item {
                // 移動先が元の位置より後の場合
                collectionView.deleteItems(at: [sourceIndex])
                collectionView.insertItems(at: [destinationIndex])
            } else {
                // 移動先が元の位置より前の場合
                collectionView.insertItems(at: [destinationIndex])
                collectionView.deleteItems(at: [sourceIndex])
            }
        })
        // ドロップの実行
        coordinator.drop(item.dragItem, toItemAt: destinationIndex)

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appDelegate.destinations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if appDelegate.destinations.get(at: indexPath.item).isFixed{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DestinationCollectionViewCell", for: indexPath) as! DestinationCollectionViewCell
            cell.block = nil
            cell.titleLabel.text = nil
            cell.transportButton.setTitle(MKDirectionsTransportType.any.text, for: .normal)
            cell.transportButton.setImage(MKDirectionsTransportType.any.image, for: .normal)
            cell.config(block: appDelegate.destinations.get(at: indexPath.item), delegate: self)
            
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MultiDestinationsCollectionViewCell", for: indexPath) as! MultiDestinationsCollectionViewCell
            cell.block = nil
            cell.titleLabel.text = nil
            cell.transportButton.setTitle(MKDirectionsTransportType.any.text, for: .normal)
            cell.config(block: appDelegate.destinations.get(at: indexPath.item), delegate: self)
            cell.accessories = [.delete()]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let block = appDelegate.destinations.get(at: indexPath.item)
        var height: CGFloat
        if block.isFixed{
            height  = block.isOpened ? 137 : 51
        }else{
            height  = CGFloat(block.isOpened ? 94*block.count + 94 : 51)
        }
        return CGSize(width: UIScreen.main.bounds.width, height: height)
            
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if indexPath.row >= appDelegate.destinations.count { return [] }
        // ドラッグするアイテムの情報を取得
        let item = "\(appDelegate.destinations.get(at: indexPath.item))"
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }

    // ドロップ時のパスを取得&設定
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndexPath = IndexPath(item: row - 1, section: 0)
        }
        // 配列とセルの更新処理を呼び出し
        if coordinator.proposal.operation == .move {
            self.updateItem(coordinator: coordinator, destinationIndex: destinationIndexPath, collectionView: collectionView)
        }
    }

    // ドロップ範囲の設定
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        let lastItemInFirstSection = collectionView.numberOfItems(inSection: 0)
        let destinationIndexPath: IndexPath = destinationIndexPath ?? .init(item: lastItemInFirstSection - 1, section: 0)

        // 画像が入っているところのみDropを有効にする
        if collectionView.hasActiveDrag && destinationIndexPath.row < appDelegate.destinations.count {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        // 画像が入ってないところはforbiddenで無効化
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        return
    }
    func reloadData() {
        collectionView.reloadData()
    }
    func reloadItem(indexPath:IndexPath) {
        collectionView.reloadItems(at: [indexPath])
    }
    func shiftSearchVC(block:Block,item:ItemProtocol){
        let blockIndex = appDelegate.destinations.firstIndex(block: block)
        let itemIndex = block.firstIndex(item: item)
        self.dismiss(animated: false)
        //FreeDestinationsに追加
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController
        vc?.config(method: .fromDestinetions(blockIndex,itemIndex), delegate: delegate!)
        delegate?.showSemiModalView(vc: vc!)
        
    }
}

protocol DestinationDelegate {
    func reloadData()
    func reloadItem(indexPath:IndexPath)
    func shiftSearchVC(block:Block,item:ItemProtocol)
}

