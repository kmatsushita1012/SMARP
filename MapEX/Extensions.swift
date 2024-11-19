//
//  Extentions.swift
//  MapEX
//
//  Created by 松下和也 on 2024/05/02.
//

import Foundation
import MapKit

extension UIDataDetectorTypes{
    var text:String{
        switch self {
        case .address:
            return "住所"
        case .link:
            return "Webサイト"
        case .phoneNumber:
            return "電話番号"
        default:
            return ""
        }
    }
}
extension MKDirectionsTransportType{
    var text: String {
        switch self {
        case .transit:
            return "電車/バス"
        case .walking:
            return "徒歩"
        case .automobile:
            return "車"
        default:
            return "全て"
        }
    }
    var image: UIImage?{
        switch self {
        case .transit:
            return UIImage(systemName: "tram")
        case .walking:
            return UIImage(systemName: "figure.walk")
        case .automobile:
            return UIImage(systemName: "car")
        default:
            return UIImage(systemName: "car.2")
        }
    }
    var color: UIColor{
        switch self {
        case .transit:
            return .systemIndigo
        case .walking:
            return .systemCyan
        case .automobile:
            return .systemBlue
        default:
            return .systemBlue
        }
    }
    static var allCases: [MKDirectionsTransportType]{
        return [.any,.transit,.automobile,.walking]
    }
    init(text: String) {
        switch text {
        case "電車/バス":
            self = .transit
        case "徒歩":
            self =  .walking
        case "車":
            self =  .automobile
        default:
            self =  .any
        }
    }

    func encode() -> Data?{
        let encodedValue = self.rawValue
        if let data = try? JSONEncoder().encode(encodedValue){
            return data
        }else{
            return nil
        }
    }
    
    static func decode(data: Data) -> MKDirectionsTransportType? {
        do {
            let decodedValue = try JSONDecoder().decode(Int.self, from: data)
            return MKDirectionsTransportType(rawValue: UInt(decodedValue))
        } catch {
            print("Error decoding data: \(error)")
            return nil
        }
    }
}

extension Date {
    var textOfHHMM: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    var text: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d HH:mm"
        return formatter.string(from: self)
    }
}

extension UINavigationItem {
 
    func setTitleView(withTitle title: String, subTitile: String) {
 
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .black
 
        let stackView = UIStackView(arrangedSubviews: [titleLabel])
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical
 
        self.titleView = stackView
    }
}


extension CLLocation {
    static func += (location1: inout CLLocation, location2: CLLocation) {
        let newLatitude = location1.coordinate.latitude + location2.coordinate.latitude
        let newLongitude = location1.coordinate.longitude + location2.coordinate.longitude
        location1 = CLLocation(latitude: newLatitude, longitude: newLongitude)
    }
}
extension CLLocationCoordinate2D {
    var text:String{
        return "\(latitude),\(longitude)"
    }
    
    static func + (coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: coordinate1.latitude + coordinate2.latitude, longitude: coordinate1.longitude + coordinate2.longitude)
        
    }
    
    static func += (coordinate1: inout CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) {
        coordinate1.latitude += coordinate2.latitude
        coordinate1.longitude += coordinate2.longitude
    }
    static func div (coordinate: CLLocationCoordinate2D?, denominator: Int)->CLLocationCoordinate2D? {
        if let coordinate = coordinate{
            if denominator > 0{
                return CLLocationCoordinate2D(latitude: coordinate.latitude/Double(denominator), longitude: coordinate.longitude/Double(denominator))
            }
        }
        return coordinate
        
    }
    
}

extension MKPointOfInterestCategory{
    //TODO
    var image: UIImage?{
        switch self{
        case .airport:
            return UIImage(systemName: "airplane.departure")
        case .amusementPark:
            return UIImage(systemName: "figure.2.and.child.holdinghands")
        case .aquarium:
            return UIImage(systemName: "fish")
        case .atm:
            return UIImage(systemName: "yensign")
        case .bakery:
            return UIImage(systemName: "fork.knife")
        case .bank:
            return UIImage(systemName: "yensign")
        case .beach:
            return UIImage(systemName: "beach.umbrella.fill")
        case .brewery:
            return UIImage(systemName: "wineglass.fill")
        case .cafe:
            return UIImage(systemName: "cup.and.saucer.fill")
        case .campground:
            return UIImage(systemName: "tent.fill")
        case .carRental:
            return UIImage(systemName: "car.fill")
        case .evCharger:
            return UIImage(systemName: "ev.charger")
        case .foodMarket:
            return UIImage(systemName: "cart.fill")
        case .fireStation:
            return UIImage(systemName: "flame.fill")
        case .fitnessCenter:
            return UIImage(systemName: "dumbbell.fill")
        case .gasStation:
            return UIImage(systemName: "fuelpump.fill")
        case .hotel:
            return UIImage(systemName: "bed.double.fill")
        case .laundry:
            return UIImage(systemName: "washer.fill")
        case .library:
            return UIImage(systemName: "book.closed.fill")
        case .marina:
            return UIImage(systemName: "sailboat.fill")
        case .museum:
            return UIImage(systemName: "building.columns.fill")
        case .movieTheater:
            return UIImage(systemName: "movieclapper.fill")
        case .nightlife:
            return UIImage(systemName: "moon.fill")
        case .nationalPark:
            return UIImage(systemName: "tree.fill")
        case .park:
            return UIImage(systemName: "tree.fill")
        case .police:
            return UIImage(systemName: "")
        case .parking:
            return UIImage(systemName: "parkingsign")
        case .pharmacy:
            return UIImage(systemName: "capsule.lefthalf.filled")
        case .postOffice:
            return UIImage(systemName: "mail.fill")
        case .publicTransport:
            return UIImage(systemName: "tram")
        case .restroom:
            return UIImage(systemName: "toilet.fill")
        case .restaurant:
            return UIImage(systemName: "fork.knife")
        case .store:
            return UIImage(systemName: "storefront.fill")
        case .school:
            return UIImage(systemName: "figure.child")
        case .stadium:
            return UIImage(systemName: "")
        case .theater:
            return UIImage(named: "")
        case .university:
            return UIImage(named: "")
        case .winery:
            return UIImage(systemName: "wineglass.fill")
        case .zoo:
            return UIImage(named: "")
        default:
            return UIImage(systemName: "")
        }
    }
    //TODO
    var color: UIColor{
        switch self{
        case .airport:
            return UIColor(red: 35, green: 135, blue: 235, alpha: 1.0)
        case .amusementPark:
            return UIColor(red: 248, green: 82, blue: 156, alpha: 1.0)
        case .aquarium:
            return UIColor(red: 91, green: 94, blue: 255, alpha: 1.0)
        case .atm:
            return UIColor(red: 132, green: 132, blue: 132, alpha: 1.0)
        case .bakery:
            return UIColor(red: 252, green: 123, blue: 26, alpha: 1.0)
        case .bank:
            return UIColor(red: 132, green: 132, blue: 132, alpha: 1.0)
        case .beach:
            return UIColor(red: 22, green: 177, blue: 254, alpha: 1.0)
        case .brewery:
            return UIColor(red: 252, green: 123, blue: 26, alpha: 1.0)
        case .cafe:
            return UIColor(red: 252, green: 123, blue: 26, alpha: 1.0)
        case .campground:
            return UIColor(red: 35, green: 174, blue: 6, alpha: 1.0)
        case .carRental:
            return UIColor(red: 145, green: 140, blue: 140, alpha: 1.0)
        case .evCharger:
            return UIColor(red: 25, green: 201, blue: 88, alpha: 1.0)
        case .foodMarket:
            return UIColor(red: 252, green: 161, blue: 8, alpha: 1.0)
        case .fireStation:
            return UIColor(red: 251, green: 51, blue: 63, alpha: 1.0)
        case .fitnessCenter:
            return UIColor(red: 22, green: 177, blue: 254, alpha: 1.0)
        case .gasStation:
            return UIColor(red: 36, green: 115, blue: 254, alpha: 1.0)
        case .hotel:
            return UIColor(red: 149, green: 95, blue: 239, alpha: 1.0)
        case .laundry:
            return UIColor(red: 253, green: 161, blue: 8, alpha: 1.0)
        case .library:
            return UIColor(red: 159, green: 89, blue: 43, alpha: 1.0)
        case .marina:
            return UIColor(red: 22, green: 177, blue: 254, alpha: 1.0)
        case .museum:
            return UIColor(red: 252, green: 84, blue: 158, alpha: 1.0)
        case .movieTheater:
            return UIColor(red: 252, green: 84, blue: 158, alpha: 1.0)
        case .nightlife:
            return UIColor(red: 252, green: 84, blue: 158, alpha: 1.0)
        case .nationalPark:
            return UIColor(red: 35, green: 174, blue: 6, alpha: 1.0)
        case .park:
            return UIColor(red: 35, green: 174, blue: 6, alpha: 1.0)
        case .police:
            return UIColor(red: 145, green: 140, blue: 140, alpha: 1.0)
        case .parking:
            return UIColor(red: 36, green: 115, blue: 254, alpha: 1.0)
        case .pharmacy:
            return UIColor(red: 251, green: 51, blue: 63, alpha: 1.0)
        case .postOffice:
            return UIColor(red: 132, green: 132, blue: 132, alpha: 1.0)
        case .publicTransport:
            return UIColor(red: 36, green: 115, blue: 254, alpha: 1.0)
        case .restroom:
            return UIColor(red: 149, green:95, blue: 235, alpha: 1.0)
        case .restaurant:
            return UIColor(red: 252, green: 123, blue: 26, alpha: 1.0)
        case .store:
            return UIColor(red: 253, green: 161, blue: 8, alpha: 1.0)
        case .school:
            return UIColor(red: 159, green: 89, blue: 43, alpha: 1.0)
        case .stadium:
            return UIColor(red: 35, green: 174, blue: 6, alpha: 1.0)
        case .theater:
            return UIColor(red: 252, green: 84, blue: 158, alpha: 1.0)
        case .university:
            return UIColor(red: 159, green: 89, blue: 43, alpha: 1.0)
        case .winery:
            return UIColor(red: 252, green: 84, blue: 158, alpha: 1.0)
        case .zoo:
            return UIColor(red: 252, green: 84, blue: 158, alpha: 1.0)
        default:
            return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        }
    }
    static var defaultColor:UIColor{
        return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    convenience init(red: Int,green: Int,blue: Int,alpha:CGFloat) {
        self.init(red: CGFloat(Double(red) / 255.0), green: CGFloat(Double(green)/255.0), blue: CGFloat(Double(blue) / 255.0), alpha: alpha)
    }
}

extension TimeInterval {
    init(hour: Int, minute: Int) {
        let totalSeconds = hour * 3600 + minute * 60
        self = TimeInterval(totalSeconds)
    }
    var text: String {
        return String(format: "%02d:%02d", hours, minutes)
    }
    var hours:Int{
        return Int(self) / 3600
    }
    var minutes:Int{
        return Int(self) % 3600 / 60
    }
    
    func encode()->Data?{
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            return data
        } catch {
            print("Error encoding time: \(error)")
            return nil
        }
    }

    static func decode(data:Data) -> TimeInterval? {
        do {
            let decoder = JSONDecoder()
            let time = try decoder.decode(TimeInterval.self, from: data)
            return time
        } catch {
            print("Error decoding time: \(error)")
            return nil
        }
    }
    
}
extension MKCoordinateRegion {
    static func >(lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        let area1 = lhs.span.latitudeDelta * lhs.span.longitudeDelta
        let area2 = rhs.span.latitudeDelta * rhs.span.longitudeDelta
        return area1 > area2
    }
    static func <(lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        let area1 = lhs.span.latitudeDelta * lhs.span.longitudeDelta
        let area2 = rhs.span.latitudeDelta * rhs.span.longitudeDelta
        return area1 < area2
    }
}
extension MKCoordinateRegion {
    static func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else {
            return nil
        }
        
        var minLat = coordinates.first!.latitude
        var maxLat = coordinates.first!.latitude
        var minLng = coordinates.first!.longitude
        var maxLng = coordinates.first!.longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLng = min(minLng, coordinate.longitude)
            maxLng = max(maxLng, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.1, longitudeDelta: (maxLng - minLng) * 1.1)
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

extension MKMapView {
    
    private func latitudeBottomOffset(byPadding bottomPadding: CGFloat) -> CGFloat {
        guard bounds.height > 0 else { return 0 }
        let latitudeDelta = region.span.latitudeDelta
        let bottomOffset = (bottomPadding / 4) / bounds.height
        let latitudeOffset = bottomOffset * latitudeDelta
        return latitudeOffset
    }
    func setCenter(_ center: CLLocationCoordinate2D, bottomPadding: CGFloat, animated: Bool = false) {
        let latitudeOffset = latitudeBottomOffset(byPadding: bottomPadding)
        let offsetCenter = CLLocationCoordinate2D(latitude: center.latitude - latitudeOffset, longitude: center.longitude)
        setCenter(offsetCenter, animated: animated)
    }

    func center(offsetByBottomPadding bottomPadding: CGFloat) -> CLLocationCoordinate2D {
        let originalCenter = region.center
        let latitudeOffset = latitudeBottomOffset(byPadding: bottomPadding)
        let offsetCenter = CLLocationCoordinate2D(latitude: originalCenter.latitude + latitudeOffset, longitude: originalCenter.longitude)
        return offsetCenter
    }
}
