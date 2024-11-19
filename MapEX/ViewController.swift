//
//  ViewController.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/15.
//

import UIKit
import MapKit
import FloatingPanel
import GoogleMobileAds

class ViewController: UIViewController, MKMapViewDelegate{
    
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    private var floatingPanelController = FloatingPanelController()
    var interstitial: GADInterstitialAd?
    private var adDisplayNecessity: Bool = false
    var currentVC:UIViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.selectableMapFeatures = [.pointsOfInterest]
        mapView.delegate = self
        mapView.showsUserLocation = true
        CoordinateType.mapView = mapView
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        mapView.addGestureRecognizer(gesture)
        loadInterstitial()
        Task{
            let distance = UserDefaults.standard.double(forKey: "distance")
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController{
                vc.config(method: .fromSearch, delegate: self)
                showSemiModalView(vc: vc)
            }
            let coordinate:CLLocationCoordinate2D
            do{
                coordinate = try await appDelegate.getCurrentLocation()
            }catch{
                return
            }
            self.setRegion(center: coordinate, distance: distance)
            locationButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        floatingPanelController.removePanelFromParent(animated: true)
    }
    
    @objc func handleLongPress(gesture:UILongPressGestureRecognizer){
        if gesture.state == .began{
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let data = UserDefaults.standard.data(forKey: "staytime")
            let item = FixedItem(coordinate: coordinate, name: "ドロップされたピン", stayTime: TimeInterval.decode(data: data!))
            let annotation = CustomAnnotation(coordinate: coordinate, title: "ドロップされたピン", glyphText: nil, category: nil)
            addAnnotation(annotation: annotation,selected: true)
            mapView.selectAnnotation(annotation, animated: true)
            
            
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController{
                vc.config(delegate:self,method: .fromFeature(annotation) , item: item)
                showSemiModalView(vc: vc)
                setRegion(center: item.placemark.coordinate, distance: nil)
            }
        }
    }
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController{
            vc.config(delegate: self)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav,animated: true)
        }
    }
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController{
            vc.config(method: .fromSearch, delegate: self)
            showSemiModalView(vc: vc)
        }
    }
    @IBAction func destinationsButtonTapped(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController{
            vc.config(delegate: self)
            showSemiModalView(vc: vc)
        }
    }
    @IBAction func itineraryButtonTapped(_ sender: UIButton) {
        showItineraryVC(type: .Advanced)
    }
    
    @IBAction func locationButtonTapped(_ sender: UIButton) {
        Task{
            let coordinate:CLLocationCoordinate2D
            do{
                coordinate = try await appDelegate.getCurrentLocation()
            }catch{
                if let error = error as? CustomError{
                    let alertController = UIAlertController(title: "エラー", message: error.text, preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default)
                    alertController.addAction(action)
                    self.present(alertController, animated: true)
                }
                return
            }
            let distance = UserDefaults.standard.double(forKey: "distance")
            self.setRegion(center: coordinate, distance: distance)
            locationButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        }
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? MKMapFeatureAnnotation{
            let detailRequest = MKMapItemRequest(mapFeatureAnnotation: annotation)
            detailRequest.getMapItem { mapItem, error in
                DispatchQueue.main.async {
                    // UIの変更を行うコードをここに書く
                    if let mkItem = mapItem,
                       let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController,
                       let stayTimeData = UserDefaults.standard.data(forKey: "staytime"),
                       let stayTime = TimeInterval.decode(data: stayTimeData){
                        self.currentVC = vc
                        let item = FixedItem(item: mkItem, stayTime: stayTime)
                        vc.config(delegate: self, method: .fromFeature(annotation), item: item)
                        self.showSemiModalView(vc: vc)
                    }
                }
                
            }
            return nil
        }else if let annotation = annotation as? CustomAnnotation {
            let identifier = "CustomAnnotation"
            //            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            var annotationView : MKMarkerAnnotationView?
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.glyphText = annotation.glyphText
            annotationView?.glyphImage = annotation.image
            annotationView?.markerTintColor = annotation.color
            annotationView?.displayPriority = .required
            annotationView?.alpha = 1.0
            return annotationView
        }else{
            return nil
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? CustomPolyline{
            let polyLineRendere: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            polyLineRendere.lineWidth = 8
            polyLineRendere.strokeColor = polyline.color
            return polyLineRendere
        }else{
            let polyLineRendere: MKPolylineRenderer = MKPolylineRenderer(overlay: overlay)
            polyLineRendere.lineWidth = 8
            polyLineRendere.strokeColor = .black
            return polyLineRendere
        }
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        locationButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
    }
    func move(state: FloatingPanelState) {
        floatingPanelController.move(to: state, animated: true)
    }
}
extension ViewController{
    func showItineraryVC(type:ItineraryType) {
        var destinations :Destinations
        switch type {
        case .Advanced:
            destinations = appDelegate.destinations
        case .Direct(let directDestinations):
            destinations = directDestinations
        }
        if !destinations.arrange(){
            let alertController = UIAlertController(title: "エラー", message: "最低でも2つのブロックを追加してください。 もしくは入力に空欄があります。", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "DestinationsViewController") as? DestinationsViewController{
                    vc.config(delegate: self)
                    self.showSemiModalView(vc: vc)
                }
            }))
            self.present(alertController, animated: true)

            return
        }
        DispatchQueue.main.async {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ItineraryViewController") as? ItineraryViewController{
                vc.config(delegate: self,type: type)
                self.showSemiModalView(vc: vc)
                if type == .Advanced && self.appDelegate.destinations.items.count>2{
                    self.adDisplayNecessity = true
                }
                //Sectionとpoint含めて
            }
        }
        
    }
    
    func showSemiModalView(vc: UIViewController) {
        floatingPanelController.dismiss(animated: false)
        floatingPanelController.set(contentViewController: vc)
        floatingPanelController.addPanel(toParent: self)
        if self.adDisplayNecessity{
            self.adDisplayNecessity = false
            showInterstitial()
        }
        self.currentVC = vc
    }
    
    func dismissSemiModalView() {
        removeAnnotations(annotations:getAnnotations())
        floatingPanelController.dismiss(animated: false)
        if self.adDisplayNecessity{
            self.adDisplayNecessity = false
            showInterstitial()
        }
        self.currentVC = nil
    }
    
    func getShowingRegion() -> MKCoordinateRegion {
        return mapView.region
    }
    
    func setRegion(center specfiedCenter: CLLocationCoordinate2D?,distance specfiedDistance:Double?){
        let distance = specfiedDistance ?? UserDefaults.standard.double(forKey: "distance")//km
        let floatingPanelHeight = floatingPanelController.surfaceView.frame.size.height
        if let center = specfiedCenter{
            let region = MKCoordinateRegion(center: center, latitudinalMeters: distance * 1000, longitudinalMeters: distance * 1000)
            mapView.setRegion(region, animated: false)
            if let _ = self.currentVC {
                mapView.setCenter(center, bottomPadding: floatingPanelHeight)
            }
            
        }else{
            let center = mapView.centerCoordinate
            let span = MKCoordinateSpan(latitudeDelta: distance * 1000 / 111000, longitudeDelta: distance * 1000 / (111000 * cos(mapView.centerCoordinate.latitude * .pi / 180)))
            let region = MKCoordinateRegion(center: mapView.centerCoordinate, span:span)
            mapView.setRegion(region, animated: true)
            if let _ = self.currentVC {
                print(floatingPanelHeight)
                mapView.setCenter(center, bottomPadding: floatingPanelHeight)
            }
           
        }
    }
    func setRegion(rect:MKMapRect) {
        let floatingPanelHeight = floatingPanelController.surfaceView.frame.size.height
        mapView.setVisibleMapRect(rect, animated: false)
        let center = mapView.centerCoordinate
        mapView.setCenter(center, bottomPadding: floatingPanelHeight)
        let distance = UserDefaults.standard.double(forKey: "distance")//km
        let region = MKCoordinateRegion(center: center, latitudinalMeters: distance * 1000, longitudinalMeters: distance * 1000)
        if mapView.region < region{
            self.setRegion(center: center, distance: nil)
        }
    }
    
    func addAnnotation(annotation: MKAnnotation,selected:Bool) {
        mapView.addAnnotation(annotation)
        if selected{
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    func getAnnotations() -> [MKAnnotation] {
        return mapView.annotations
    }
    func getCustomAnnotations() -> [CustomAnnotation] {
        // mapViewのannotationsを取得し、CustomAnnotationにダウンキャスト可能なものをフィルタリングする
        let customAnnotations = mapView.annotations.compactMap { $0 as? CustomAnnotation }
        return customAnnotations
    }
    func removeAnnotations(annotations:[MKAnnotation]){
        mapView.removeAnnotations(annotations)
    }
    func addPolyline(polyline: MKPolyline) {
        mapView.addOverlay(polyline)
    }
    func removePolylines(polylines: [MKPolyline]) {
        mapView.removeOverlays(polylines)
    }
    
}
extension ViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return CustomFloatingPanelLayout()
    }
}

extension ViewController:GADFullScreenContentDelegate,BaseVCDelegate{
    
    func loadInterstitial() {
        let isPurchased = UserDefaults.standard.bool(forKey: "removeAds")
        //let isPurchased = false
        if !isPurchased{
            let request = GADRequest()
            let id = "ca-app-pub-7338395880624421/5844528393"//本番
            //let id = "ca-app-pub-3940256099942544/1033173712"//テスト
            GADInterstitialAd.load(withAdUnitID: id, request: request) { [self] ad, error in
                if let error = error {
                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                    return
                }
                interstitial = ad
                interstitial?.fullScreenContentDelegate = self
            }
        }
    }

    func showInterstitial() {
        let isPurchased = UserDefaults.standard.bool(forKey: "removeAds")
        //let isPurchased = false
        if !isPurchased{
            if let interstitial = self.interstitial {
                interstitial.present(fromRootViewController: self)
            }
        }
    }
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if !self.children.contains(floatingPanelController) {
            // まだ追加されていない場合のみ追加します
            floatingPanelController.addPanel(toParent: self)
        }
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // 広告を再度読み込む
        if !self.children.contains(floatingPanelController) {
            // まだ追加されていない場合のみ追加します
            floatingPanelController.addPanel(toParent: self)
        }
        loadInterstitial()
    }
}

protocol BaseVCDelegate {
    func showSemiModalView(vc: UIViewController)
    func dismissSemiModalView()
    func getShowingRegion()->MKCoordinateRegion
    func setRegion(center:CLLocationCoordinate2D?,distance:CLLocationDistance?)
    func setRegion(rect:MKMapRect)
    func addAnnotation(annotation:MKAnnotation,selected:Bool)
    func getAnnotations()->[MKAnnotation]
    func removeAnnotations(annotations:[MKAnnotation])
    func addPolyline(polyline:MKPolyline)
    func removePolylines(polylines:[MKPolyline])
    func move(state:FloatingPanelState)
    func showItineraryVC(type:ItineraryType)
    func showInterstitial()
    func loadInterstitial()
}

