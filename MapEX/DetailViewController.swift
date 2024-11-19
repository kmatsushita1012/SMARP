//
//  DetailViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/18.
//

import UIKit
import MapKit

class DetailViewController:UIViewController,UITableViewDelegate, UITableViewDataSource{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var favoriteButton: UIButton!
    @IBOutlet weak var buttonContainerConstraint: NSLayoutConstraint!
    
    
    var delegate: BaseVCDelegate?
    var method:SearchMethod?
    var item:ItemProtocol?
    var annotation:MKAnnotation?
    var isFavorite=false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let item = self.item else {
            return
        }
        label.text = item.name
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "AdressTableViewCell", bundle: nil), forCellReuseIdentifier: "AdressTableViewCell")
        tableView.register(UINib(nibName: "LinkTableViewCell", bundle: nil), forCellReuseIdentifier: "LinkTableViewCell")
        tableView.register(UINib(nibName: "MapAppTableViewCell", bundle: nil), forCellReuseIdentifier: "MapAppTableViewCell")
        tableView.isScrollEnabled = false
        buttonContainer.layer.cornerRadius = 10
        let width = CGFloat(CGFloat(UIScreen.main.bounds.width - 92)/3.0)
        buttonContainerConstraint.constant = width + 16
        if method == .fromSearch,
            let item = item as? FixedItem{
            let annotation = CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name, glyphText: nil, category: item.pointOfInterestCategory)
            delegate?.addAnnotation(annotation: annotation,selected: true)
            self.annotation = annotation
        }
        switch method{
        case .fromDestinetions(_, _):
            let decideButton = makeDecideButton(leadingAnchor: buttonContainer.leadingAnchor, width: width)
            let directButton = makeDirectButton(leadingAnchor: decideButton.trailingAnchor, width: width)
            _ = makeReplaceButton(leadingAnchor: directButton.trailingAnchor, width: width)
        default:
            let addButton = makeAddButton(leadingAnchor: buttonContainer.leadingAnchor, width: width)
            let directButton = makeDirectButton(leadingAnchor: addButton.trailingAnchor, width: width)
            _ = makeReplaceButton(leadingAnchor: directButton.trailingAnchor, width: width)
        }
        
        if let item = item as? FixedItem{
            favoriteButton.isHidden = false
            tableView.isHidden = false
            delegate?.setRegion(center: item.placemark.coordinate, distance: nil)
            if appDelegate.favorites.firstIndex(item: item) == nil{
                favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
            }else{
                favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            }
        }else{
            favoriteButton.isHidden = true
            tableView.isHidden = true
            Task{
                let center:CLLocationCoordinate2D
                do{
                    center = try await appDelegate.getCurrentLocation()
                }catch{
                    return
                }
                delegate?.setRegion(center: center, distance: nil)
            }
        }
        let today = Date()
        let calendar = Calendar.current
        datePicker.date = calendar.date(bySettingHour: (self.item?.stayTime!.hours)!, minute: (self.item?.stayTime!.minutes)!, second: 0, of: today)!
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint.constant = CGFloat(tableView.contentSize.height)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let annotation = self.annotation{
            delegate?.removeAnnotations(annotations: [annotation])
            self.annotation = nil
        }
    }
    
    func config(delegate:BaseVCDelegate,method:SearchMethod,item:ItemProtocol) {
        self.delegate = delegate
        self.method = method
        self.item = item
        switch method {
        case .fromFeature(let annotation):
            self.annotation = annotation
        default:
            break
        }
        if let item = item as? FixedItem,
            let index = appDelegate.favorites.firstIndex(item: item){
            isFavorite = true
            self.item = appDelegate.favorites.get(at: index)
        }
    }
    func makeDecideButton(leadingAnchor:NSLayoutXAxisAnchor,width:CGFloat)->UIButton{
        let decideButton = UIButton()
        decideButton.backgroundColor = .systemBlue
        decideButton.setTitleColor(.white, for: .normal)
        decideButton.translatesAutoresizingMaskIntoConstraints = false
        decideButton.addTarget(self, action: #selector(decideButtonTapped), for: .touchUpInside)
        decideButton.layer.cornerRadius = 10
        decideButton.tintColor = .white
        decideButton.setImage(UIImage(systemName:"checkmark"), for: .normal)
        decideButton.setTitle("決定", for: .normal)
        buttonContainer.addSubview(decideButton)
        NSLayoutConstraint.activate([
            decideButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            decideButton.heightAnchor.constraint(equalToConstant: width),
            decideButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            decideButton.widthAnchor.constraint(equalToConstant: width)
        ])
        return decideButton
    }
    func makeAddButton(leadingAnchor:NSLayoutXAxisAnchor,width:CGFloat)->UIButton{
        let addButton = UIButton()
        addButton.backgroundColor = .systemBlue
        addButton.setTitleColor(.white, for: .normal)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.layer.cornerRadius = 10
        addButton.tintColor = .white
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.titleLabel?.numberOfLines = 0
        addButton.titleLabel?.textAlignment = .center
        addButton.setTitle("新規\n追加", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        buttonContainer.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            addButton.heightAnchor.constraint(equalToConstant: width),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            addButton.widthAnchor.constraint(equalToConstant: width)
        ])
        return addButton
    }
    func makeDirectButton(leadingAnchor:NSLayoutXAxisAnchor,width:CGFloat)->UIButton{
        let directButton = UIButton()
        directButton.backgroundColor = UIColor(hex: "D5E7FD")
        directButton.setTitleColor(.systemBlue, for: .normal)
        directButton.translatesAutoresizingMaskIntoConstraints = false
        directButton.addTarget(self, action: #selector(directButtonTapped), for: .touchUpInside)
        directButton.layer.cornerRadius = 10
        directButton.setImage(UIImage(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill"), for: .normal)
        directButton.setTitle("ここから", for: .normal)
        directButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        directButton.titleLabel?.lineBreakMode = .byWordWrapping
        buttonContainer.addSubview(directButton)
        NSLayoutConstraint.activate([
            directButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            directButton.heightAnchor.constraint(equalToConstant: width),
            directButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            directButton.widthAnchor.constraint(equalToConstant: width)
        ])
        return directButton
    }
    func makeReplaceButton(leadingAnchor:NSLayoutXAxisAnchor,width:CGFloat)->UIButton{
        let replaceButton = UIButton()
        replaceButton.backgroundColor = UIColor(hex: "D5E7FD")
        replaceButton.setTitleColor(.systemBlue, for: .normal)
        replaceButton.translatesAutoresizingMaskIntoConstraints = false
        replaceButton.layer.cornerRadius = 10
        replaceButton.setImage(UIImage(systemName: "list.number"), for: .normal)
        replaceButton.titleLabel?.numberOfLines = 0
        replaceButton.titleLabel?.textAlignment = .center
        replaceButton.setTitle("追加", for: .normal)
        replaceButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        var actions = [UIAction]()
        for (i,block) in appDelegate.destinations.blocks.enumerated(){
            let title:String
            if block.isFixed,
                let name = block.first?.name{
                title = name
            }else{
                title = "グループ\(i+1)"
            }
            let fixedAction = UIAction(title: title, handler: { [weak self] _ in
                block.append(item: self!.item!)
                if let vc = self?.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController{
                    vc.config(delegate: self!.delegate!)
                    self!.delegate?.showSemiModalView(vc: vc)
                }
            })
            actions.append(fixedAction)
        }
        let fixedAction = UIAction(title: "グループ\(appDelegate.destinations.count)", handler: { [weak self] _ in
            let transportData = UserDefaults.standard.data(forKey: "transport")!
            let transportType = MKDirectionsTransportType.decode(data: transportData)!
            let block = Block(items: [self!.item!],transportType: transportType)
            self!.appDelegate.destinations.append(block: block)
            if let vc = self?.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController{
                vc.config(delegate: self!.delegate!)
                self!.delegate?.showSemiModalView(vc: vc)
            }
        })
        actions.append(fixedAction)
        replaceButton.menu = UIMenu(title: "", options: .displayInline, children: actions)
        replaceButton.showsMenuAsPrimaryAction = true
        buttonContainer.addSubview(replaceButton)
        NSLayoutConstraint.activate([
            replaceButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            replaceButton.heightAnchor.constraint(equalToConstant: width),
            replaceButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            replaceButton.widthAnchor.constraint(equalToConstant: width)
        ])
        return replaceButton
    }
    
    @objc func directButtonTapped(_ sender: UIButton) {
        let stayTimeData = UserDefaults.standard.data(forKey: "staytime")!
        let stayTime = TimeInterval.decode(data: stayTimeData)!
        let transportData = UserDefaults.standard.data(forKey: "transport")!
        let transportType = MKDirectionsTransportType.decode(data: transportData)!
        let sourse = SelectableItem(name: "現在地", stayTime: stayTime)
        let sourseBlock = Block(items: [sourse],transportType:transportType)
        let destinationBlock = Block(items: [self.item!],transportType: transportType)
        let destinations = Destinations(blocks: [sourseBlock,destinationBlock])
        delegate?.showItineraryVC(type: .Direct(destinations))
    }
    
    @objc func addButtonTapped(_ sender: UIButton) {
        let transportData = UserDefaults.standard.data(forKey: "transport")!
        let transportType = MKDirectionsTransportType.decode(data: transportData)!
        let block = Block(items: [self.item!],transportType: transportType)
        appDelegate.destinations.append(block: block)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController
        vc?.config(delegate: self.delegate!)
        self.delegate?.showSemiModalView(vc: vc!)
    }
    
    @objc func decideButtonTapped(_ sender: UIButton){
        switch method! {
        case .fromDestinetions(let i,let j):
            appDelegate.destinations.replaceItem(item: self.item!, blockIndex: i, itemIndex: j)
        default:
            break
        }
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController
        vc?.config(delegate: self.delegate!)
        self.delegate?.showSemiModalView(vc: vc!)
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        delegate?.dismissSemiModalView()
    }
    
    @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            UIMenuController.shared.showMenu(from: gesture.view!,rect: gesture.view!.bounds)
        }
    }
    @IBAction func favotiteButton(_ sender: UIButton) {
        if let item = item as? FixedItem{
            isFavorite = !isFavorite
            if isFavorite{
                appDelegate.favorites.add(item: item)
                favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            }else{
                appDelegate.favorites.delete(item: item)
                favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
            }
        }
    }
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: datePicker.date)
        self.item!.stayTime = TimeInterval(hour: components.hour!, minute: components.minute!)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
        //住所,URL,電話番号,GoogleMap,マップ,
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = item as? FixedItem{
            switch indexPath.item{
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath) as! LinkTableViewCell
                cell.config(item: item, type: .address)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath) as! LinkTableViewCell
                cell.config(item: item, type: .link)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath) as! LinkTableViewCell
                cell.config(item: item, type: .phoneNumber)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "MapAppTableViewCell", for: indexPath) as! MapAppTableViewCell
                cell.config(item: item, app: .Google)
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "MapAppTableViewCell", for: indexPath) as! MapAppTableViewCell
                cell.config(item: item, app: .Apple)
                return cell
            default:
                let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
                return cell
            }
        }
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.item {
        case 0:
            return 120
        case 1:
            return 69
        case 2:
            return 69
        default:
            return 44
        }
    }
}
