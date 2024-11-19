//
//  ResultViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/27.
//

import UIKit
import MapKit
import GoogleMobileAds

class ItineraryViewController:UIViewController,UITableViewDataSource,UITableViewDelegate, ItineraryDelegate{
    
    private var appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var enumButton: UIButton!
    private var delegate:BaseVCDelegate?
    var requestItems:[RequestItem]?
    var annotations = [MKAnnotation]()
    var polylines = [MKPolyline]()
    let loadingAlert = LoadingAlert()
    var type:ItineraryType?
    private var itinerary:Itinerary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "PointTableViewCell", bundle: nil), forCellReuseIdentifier: "PointTableViewCell")
        tableView.register(UINib(nibName: "SectionTableViewCell", bundle: nil), forCellReuseIdentifier: "SectionTableViewCell")
        delegate?.removePolylines(polylines: self.polylines)
        self.polylines.removeAll()
        delegate?.removeAnnotations(annotations: self.annotations)
        self.annotations.removeAll()
        //TODO
        makeItinerary()
    }
    
    func makeItinerary(){
        var destinations:Destinations
        switch type {
        case .Advanced:
            destinations = appDelegate.destinations
        case .Direct(let dests):
            destinations = dests
        case .none:
            return
        }
        
        Task {
            self.startActivityIndicator()
            do{
                let currentCoordinate = try await appDelegate.getCurrentLocation()
                let requestItems = try await destinations.ordered(currentCoordinate: currentCoordinate)
                self.itinerary = Itinerary(items: requestItems,type: type!)
                itinerary!.enumDate = destinations.enumDate
                try await itinerary!.run()
            }catch{
                self.stopActivityIndicator()
                var message:String = "原因不明のエラー"
                if let error = error as? CustomError{
                    message = error.text
                }
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: message)
                }
                return
            }
            datePicker.date = self.itinerary!.enumDate.date
            self.setEnumButton(enumDate: self.itinerary!.enumDate)
            tableView.reloadData()
            drawPolyline()
            stopActivityIndicator()
        }
    }
    
    
    func drawPolyline(){
        var totalRect = MKMapRect.null
        for item in self.itinerary!.items{
            if let item = item as? PointItem{
                let annotation = CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name, glyphText: String(item.index), image: nil, color: .black)
                annotations.append(annotation)
                delegate?.addAnnotation(annotation: annotation,selected: false)
            }else if let item = item as? SectionItem{
                if item.transportType == .transit{
                    let polyline = CustomPolyline(coordinates: [item.sourse.placemark.coordinate,item.destination.placemark.coordinate], count: 2)
                    polyline.color = item.transportType.color
                    totalRect = totalRect.union(polyline.boundingMapRect)
                    delegate!.addPolyline(polyline: polyline)
                    self.polylines.append(polyline)
                }else{
                    
                    for step in item.steps{
                        if let step = step as? MKRoute.Step{
                            let count = step.polyline.pointCount
                            var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: count)
                            step.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
                            let polyline = CustomPolyline(coordinates: coords, count: count)
                            polyline.color = step.transportType.color
                            totalRect = totalRect.union(polyline.boundingMapRect)
                            self.polylines.append(polyline)
                            delegate!.addPolyline(polyline: polyline)
                        }
                    }
                }
            
            }
        }
        let extraSpace = totalRect.size.width * 0.1 // 余白のサイズを設定
        totalRect = totalRect.insetBy(dx: -extraSpace, dy: -extraSpace)
        delegate?.setRegion(rect:totalRect)
    }
    func setEnumButton(enumDate:EnumDate){
        switch enumDate{
        case .departure(_):
            enumButton.setTitle("出発", for: .normal)
        case .arrive(_):
            enumButton.setTitle("到着", for: .normal)
        }
        var actions = [UIMenuElement]()
        let arriveAction = UIAction(title: "到着", handler: { [weak self] _ in
            if self!.self.itinerary?.type == .Advanced{
                self!.appDelegate.destinations.enumDate = .arrive(self!.appDelegate.destinations.enumDate.date)
            }
            self!.itinerary?.enumDate = .arrive(self!.appDelegate.destinations.enumDate.date)
            self!.enumButton.setTitle("到着", for: .normal)
            Task{
                self!.startActivityIndicator()
                do{
                    try await self!.itinerary?.run()
                }catch{
                    self!.stopActivityIndicator()
                    var message:String = "原因不明のエラー"
                    if let error = error as? CustomError{
                        message = error.text
                    }
                    DispatchQueue.main.async {
                        self!.showAlert(title: "エラー", message: message)
                    }
                    return
                }
                self!.tableView.reloadData()
                self!.drawPolyline()
                self!.stopActivityIndicator()
            }
        })
        actions.append(arriveAction)
        let depatureAction = UIAction(title: "出発", handler: { [weak self] _ in
            if self!.self.itinerary?.type == .Advanced{
                self!.appDelegate.destinations.enumDate = .departure(self!.appDelegate.destinations.enumDate.date)
            }
            self!.itinerary?.enumDate = .departure(self!.appDelegate.destinations.enumDate.date)
            self!.enumButton.setTitle("出発", for: .normal)
            Task{
                self!.startActivityIndicator()
                do{
                    try await self!.itinerary?.run()
                }catch{
                    self!.stopActivityIndicator()
                    var message:String = "原因不明のエラー"
                    if let error = error as? CustomError{
                        message = error.text
                    }
                    DispatchQueue.main.async {
                        self!.showAlert(title: "エラー", message: message)
                    }
                    return
                }
                self!.tableView.reloadData()
                self!.drawPolyline()
                self!.stopActivityIndicator()
            }
        })
        actions.append(depatureAction)
        enumButton.menu = UIMenu(title: "", options: .displayInline, children: actions)
        enumButton.showsMenuAsPrimaryAction = true
        
    }
    
    func config(delegate:BaseVCDelegate,type:ItineraryType){
        self.delegate = delegate
        self.type = type
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.removePolylines(polylines: self.polylines)
        self.polylines.removeAll()
        delegate?.removeAnnotations(annotations: self.annotations)
        self.annotations.removeAll()
    }
    @IBAction func dismissButtonTapped(_ sender: UIButton) {
        delegate?.dismissSemiModalView()
    }
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        switch itinerary!.enumDate{
        case .arrive(_):
            self.itinerary?.enumDate = .arrive(datePicker.date)
        case .departure(_):
            self.itinerary?.enumDate = .departure(datePicker.date)
        }
        if type == .Advanced{
            appDelegate.destinations.enumDate = self.itinerary!.enumDate
        }
        delegate?.removePolylines(polylines: self.polylines)
        self.polylines.removeAll()
        delegate?.removeAnnotations(annotations: self.annotations)
        self.annotations.removeAll()
        Task{
            self.startActivityIndicator()
            do{
                try await self.itinerary?.run()
            }catch{
                self.stopActivityIndicator()
                var message:String = "原因不明のエラー"
                if let error = error as? CustomError{
                    message = error.text
                }
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: message)
                }
                return
            }
            tableView.reloadData()
            drawPolyline()
            stopActivityIndicator()
        }
    }
    func showAlert(title:String,message:String){
        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: false, completion: {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(action)
                self.present(alertController, animated: true)
            })
        } else {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(action)
            self.present(alertController, animated: true)
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let itinerary = self.itinerary{
            return itinerary.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = self.itinerary?.items[indexPath.item] as? PointItem{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PointTableViewCell", for: indexPath) as! PointTableViewCell
            cell.config(item: item, isEnd: item.isEnd)
            //TODO
            let annotation = CustomAnnotation(coordinate: item.placemark.coordinate, title: item.name, glyphText: String(item.index), image: nil, color: .black)
            annotations.append(annotation)
            delegate?.addAnnotation(annotation: annotation,selected: false)
            return cell
        }else if let item = self.itinerary?.items[indexPath.item] as? SectionItem{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SectionTableViewCell", for: indexPath) as! SectionTableViewCell
            cell.config(delegate:self,item: item,indexPath: indexPath)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.itinerary?.items[indexPath.item] is FixedItem{
            return 51
        }else if let item = self.itinerary?.items[indexPath.item] as? SectionItem{
            if item.transportType == .transit{
                return CGFloat(44 * 3 + 51)
            }else if item.isToggled{
                return CGFloat(44 * item.steps.count + 51)
            }else{
                return CGFloat(44 * 2 + 51)
            }
        }else{
            return 44
        }
    }
    func reloadRow(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    func addPolyline(polyline: MKPolyline) {
        self.polylines.append(polyline)
        delegate?.addPolyline(polyline: polyline)
    }
    func showAlertController(alertController:UIAlertController){
        self.present(alertController, animated: true)
    }
    func startActivityIndicator() {
        loadingAlert.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingAlert)
        NSLayoutConstraint.activate([
            loadingAlert.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingAlert.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 16.0),
            loadingAlert.widthAnchor.constraint(equalToConstant: 150),
            loadingAlert.heightAnchor.constraint(equalToConstant: 100)
        ])
        loadingAlert.startAnimating()
    }
    func stopActivityIndicator() {
        loadingAlert.stopAnimating()
        loadingAlert.removeFromSuperview()
    }
}



protocol ItineraryDelegate {
    func reloadRow(at: IndexPath)
    func addPolyline(polyline: MKPolyline)
    func showAlertController(alertController:UIAlertController)
}
