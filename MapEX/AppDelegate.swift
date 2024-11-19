//
//  AppDelegate.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/15.
//

import UIKit
import MapKit
import CoreLocation
import GoogleMobileAds
import StoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate{
    
    var destinations = Destinations()
    var favorites = Favorites()
    let locationManager = CLLocationManager()   
    
    let removeAdsId = "removeAds1"
    
    override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        CoordinateType.locationManager = locationManager
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        SKPaymentQueue.default().add(IAPManager.shared)
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if UserDefaults.standard.object(forKey: "clear") == nil{
            UserDefaults.standard.setValue(true, forKey: "clear")
        }
        if UserDefaults.standard.data(forKey: "staytime") == nil{
            let data = TimeInterval.init(hour: 0, minute: 5).encode()
            UserDefaults.standard.set(data, forKey: "staytime")
        }
        if UserDefaults.standard.data(forKey: "transport") == nil{
            let data = MKDirectionsTransportType.any.encode()
            UserDefaults.standard.set(data, forKey: "transport")
            
        }
        if UserDefaults.standard.double(forKey: "distance") == 0.0{
            UserDefaults.standard.set(Double(1.0), forKey: "distance")
        }
        if UserDefaults.standard.data(forKey: "sourse") == nil{
            Task{
                if let stayTimeData = UserDefaults.standard.data(forKey: "staytime"),
                   let stayTime = TimeInterval.decode(data: stayTimeData){
                    let item = SelectableItem(name: "現在地", stayTime: stayTime, pointOfInterestCategory: nil)
                    let data = item.encode()
                    UserDefaults.standard.set(data, forKey: "sourse")
                }
            }
        }
        initDestinations()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func getCurrentLocation()async throws ->CLLocationCoordinate2D {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            throw CustomError.notAuthorized
        }
        return await withUnsafeContinuation { continuation in
            Task {
                while true {
                    // 位置情報が利用可能なら取得して返す
                    if let location = locationManager.location {
                        continuation.resume(returning: location.coordinate)
                        break
                    }
                    // 位置情報が利用不可の場合は待機
                    await Task.sleep(100_000_000) // 0.1秒待機
                }
            }
        }
    }
    func initDestinations(){
        destinations = Destinations()
        let data = UserDefaults.standard.data(forKey: "transport")!
        let transportType = MKDirectionsTransportType.decode(data: data)
        if let data = UserDefaults.standard.data(forKey: "sourse"),
           let sourse = NilItem.decode(data: data){
            if sourse is NilItem{
                return
            }else{
                let block = Block(items: [sourse],transportType: transportType!)
                destinations.append(block: block)
            }
        }
    }
    //    func initSwiftyStorekit() {
    //           SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
    //               for purchase in purchases {
    //                   switch purchase.transaction.transactionState {
    //                   case .purchased, .restored:
    //                       if purchase.needsFinishTransaction {
    //                           SwiftyStoreKit.finishTransaction(purchase.transaction)
    //                       }
    //                   // Unlock content
    //                   case .failed, .purchasing, .deferred:
    //                       break // do nothing
    //                   }
    //               }
    //           }
    //       }
    //}
}
