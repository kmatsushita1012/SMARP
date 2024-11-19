//
//  Enum.swift
//  MapEX
//
//  Created by 松下和也 on 2024/05/02.
//

import MapKit

enum ItineraryType: Equatable{
    
    
    case Advanced
    case Direct(Destinations)
    static func == (lhs: ItineraryType, rhs: ItineraryType) -> Bool {
        switch (lhs, rhs) {
        case (.Advanced, .Advanced):
            return true
        case (.Direct(_), .Direct(_)):
            return true
        default:
            return false
        }
    }
}

enum EnumDate{
    case departure(Date)
    case arrive(Date)
    
    var date:Date{
        switch self {
        case .departure(let date):
            return date
        case .arrive(let date):
            return date
        }
    }
}

enum SearchMethod:Equatable{
    case fromDestinetions(Int,Int)
    case fromSearch
    case fromFeature(MKAnnotation)
    static func == (lhs: SearchMethod, rhs: SearchMethod) -> Bool {
        switch (lhs,rhs){
        case (.fromDestinetions(_, _),.fromDestinetions(_, _)):
            return true
        case (.fromSearch,.fromSearch):
            return true
        case(.fromFeature(_),.fromFeature(_)):
            return true
        default:
            return false
        }
    }
}
enum ExternalApp{
    case Google
    case Apple
    
    var text:String{
        switch self {
        case .Google:
            return "Google Map"
        case .Apple:
            return "マップ"
        }
    }
    
}

enum CoordinateType{
    case SomeWhere(CLLocationCoordinate2D)
    case MapCenter
    case Current
    
    static var mapView: MKMapView?
    static var locationManager: CLLocationManager?
    
    func getCoordinate()->CLLocationCoordinate2D{
        switch self {
        case .SomeWhere(let cLLocationCoordinate2D):
            return cLLocationCoordinate2D
        case .MapCenter:
            return CoordinateType.mapView!.centerCoordinate
        case .Current:
            return (CoordinateType.locationManager?.location!.coordinate)!
        }
    }
}
