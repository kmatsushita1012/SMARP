//
//  Tools.swift
//  MapEX
//
//  Created by 松下和也 on 2024/03/15.
//

import Foundation
import MapKit



class Destinations{
    var blocks = [Block]()
    var enumDate: EnumDate = .departure(Date())
    
    var items:[ItemProtocol?]{
        var items = [ItemProtocol?]()
        for block in blocks{
            items.append(contentsOf: block.items)
        }
        return items
    }
    
    var itemsWithIndex:[(ItemProtocol?,Int,Int)]{
        var items = [(ItemProtocol?,Int,Int)]()
        for (i,block) in blocks.enumerated(){
            for (j,item) in block.items.enumerated(){
                items.append((item,i,j))
            }
        }
        return items
    }
    init(){}
    
    init(blocks:[Block]) {
        self.blocks.append(contentsOf: blocks)
    }
    
    var count: Int{
        return blocks.count
    }
    
    func insert(at index :Int,block: Block){
        if index == count{
            blocks.append(block)
        }else{
            blocks.insert(block, at: index)
        }
    }
    
    func append(block:Block){
        blocks.append(block)
    }
    
    func remove(at index:Int)->Block{
        return blocks.remove(at: index)
    }
    
    func removeItem(blockIndex:Int,itemIndex:Int)->ItemProtocol?{
        return get(at: blockIndex).remove(at: itemIndex)
    }
    
    func replace(block:Block,at index:Int){
        blocks[index] = block
    }
    
    func replaceItem(item:ItemProtocol,blockIndex:Int,itemIndex:Int){
        if blockIndex >= 0 && blockIndex < self.blocks.count && itemIndex >= 0 && itemIndex < self.get(at: blockIndex).count{
            self.get(at: blockIndex).replace(item: item, at: itemIndex)
        }
    }
    
    func get(at index: Int) -> Block{
        return blocks[index]
    }
    
    func firstIndex(block: Block)->Int{
        if let index =  blocks.firstIndex(where: {$0 === block}){
            return index
        }else{
            return -1
        }
    }
    
    func getItem(blockIndex:Int,itemIndex:Int) -> ItemProtocol?{
        return get(at: blockIndex).get(at:itemIndex)
    }
    
    func arrange()->Bool{
        for (i,block) in blocks.enumerated(){
            var flag = false
            for (j,item) in block.items.enumerated(){
                if item is NilItem{
                    _ = block.remove(at: j)
                }else{
                    flag = true
                }
            }
            if !flag{
                _ = remove(at: i)
            }
        }
        if count <= 1{
            return false
        }else{
            return true
        }
    }
    
    func ordered(currentCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)) async throws -> [RequestItem]{
        var bestItems:[RequestItem] = [RequestItem()]
        var bestDistance =  Double.infinity
        
        func recurse(distance preDistance: Double,index preIndex:Int = -1,storedItems:[RequestItem],stack:[ItemProtocol]) async throws{
            var index = preIndex
            var distance:Double = 0.0
            if storedItems.count >= 2{
                distance = MapTools.distanceBetween(mapItem1: storedItems[storedItems.count-2], mapItem2: storedItems.last!)! + preDistance
                if distance > bestDistance{
                    //超過
                    return
                }else if (index == self.count-1)&&(stack.count == 0){
                    //末端
                    bestDistance = distance
                    bestItems = storedItems
                    return
                }
            }
            
            if stack.count > 0 {
                //未消化があれば優先
                for (i,item) in stack.enumerated(){
                    if let selectableItem = item as? SelectableItem,
                       selectableItem.name != "現在地"{
                        //TODO
                        var leftstack = stack.map{$0}
                        leftstack.remove(at: i)
                        let span = MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
                        let region = MKCoordinateRegion(center: getCenter(at: index) ?? currentCoordinate, span: span)
                        var proposedItems = [MKMapItem]()
                        do{
                            proposedItems = try await MapTools.search(query: selectableItem.name!, region: region)
                        }catch{
                            throw error
                        }
                        if proposedItems.count == 0{
                            throw CustomError.notFound
                        }
                        for proposedItem in proposedItems{
                            var newItems = storedItems.map{ $0 }
                            let requestItem = RequestItem(mapItem: proposedItem, stayTime: selectableItem.stayTime!, transportType: self.get(at: index).transportType)
                            newItems.append(requestItem)
                            try await recurse(distance:distance,index: index, storedItems: newItems, stack: leftstack)
                        }
                    }else{
                        var fixedItem:FixedItem?
                        if let item = item as? SelectableItem{
                            fixedItem = item.fix(coordinate: currentCoordinate)
                        }else if let item = item as? FixedItem{
                            fixedItem = item
                        }
                        var leftstack = stack.map{$0}
                        leftstack.remove(at: i)
                        var newItems = storedItems.map{ $0 }
                        let requestItem = RequestItem(fixedItem: fixedItem!, transportType:self.get(at: index).transportType)
                        newItems.append(requestItem)
                        try await recurse(distance:distance,index: index, storedItems: newItems, stack: leftstack)
                    }
                }
            }else{
                index += 1
                let block = self.get(at: index)
                for (i,item) in block.items.enumerated(){
                    var fixedItem: FixedItem?
                    if let item = item as? SelectableItem{
                        fixedItem = item.fix(coordinate: currentCoordinate)
                    }else if let item = item as? FixedItem{
                        fixedItem = item
                    }
                    var leftstack = block.items.map{ $0 } as! [ItemProtocol]
                    leftstack.remove(at: i)
                    let requestItem = RequestItem(fixedItem: fixedItem!, transportType:block.transportType)
                    var newItems = storedItems.map{ $0 }
                    newItems.append(requestItem)
                    try await recurse(distance:distance,index: index, storedItems: newItems, stack: leftstack)
                    //TODO
                }
            }
        }
        do {
            try await recurse(distance: 0.0, storedItems: [RequestItem](), stack: [ItemProtocol]())
        } catch {
            throw error
        }
        return bestItems
    }
    func getCenter(at index:Int)->CLLocationCoordinate2D?{
        func getInnerCenter(block:Block)->CLLocationCoordinate2D?{
            var center :CLLocationCoordinate2D? =  nil
            for item in block.items {
                if item is SelectableItem{
                    
                }else if let item = item as? FixedItem{
                    if var center = center{
                        center += item.placemark.coordinate
                    }else{
                        center = item.placemark.coordinate
                    }
                }
            }
            return CLLocationCoordinate2D.div(coordinate: center, denominator: block.items.count)
            
        }
        var head = index
        var tail = index
        var center: CLLocationCoordinate2D?
        var headaverage = getInnerCenter(block: get(at: head))
        var tailaverage = getInnerCenter(block: get(at: tail))
        
        while( head>=0 && tail<self.count ){
            if headaverage == nil && tailaverage == nil{
                head -= 1
                tail += 1
                headaverage = getInnerCenter(block: get(at: head))
                tailaverage = getInnerCenter(block: get(at: tail))
                continue
            }else if headaverage == nil{
                head -= 1
                headaverage = getInnerCenter(block: get(at: head))
            }else if tailaverage == nil{
                tail += 1
                tailaverage = getInnerCenter(block: get(at: tail))
            }else{
                center = CLLocationCoordinate2D.div(coordinate: headaverage! + tailaverage!, denominator: 2)
                break
            }
        }
        if let center = center{
            return center
        }else if headaverage == nil && tailaverage == nil{
            return nil
        }else if headaverage == nil{
            return tailaverage
        }else if tailaverage == nil{
            return headaverage
        }
        return nil
    }
}

class Itinerary{
    private let requestItems:[RequestItem]
    var items = [ResultProtocol]()
    var enumDate:EnumDate = .departure(Date())
    let type:ItineraryType
    
    var count:Int{
        return items.count
    }
    var points:[RequestItem]{
        return requestItems
    }
    
    init(items requestItems:[RequestItem],type:ItineraryType){
        self.type = type
        self.requestItems = requestItems
    }
    func run() async throws{
        items = [ResultProtocol]()
        switch enumDate {
        case .departure(var date):
            var index = 1
            for i in 0..<self.requestItems.count-1{
                if self.requestItems[i].transportType == .transit{
                    let response:MKDirections.ETAResponse
                    do{
                        response = try await MapTools.getETA(sourse: self.requestItems[i], destination: self.requestItems[i+1], transportation:self.requestItems[i].transportType, date: .departure(date))
                    }catch{
                        throw error
                    }
                    let item = PointItem(item: self.requestItems[i] as FixedItem, index: index,isEnd: i == 0)
                    let timeDifference = response.expectedDepartureDate.timeIntervalSince(date)
                    item.stayTime! += timeDifference
                    date = response.expectedArrivalDate
                    items.append(item)
                    index += 1
                    let sectionItem = SectionItem(response: response)
                    date += self.requestItems[i+1].stayTime!
                    items.append(sectionItem)
                }else{
                    let route:MKRoute
                    do{
                        route = try await MapTools.getDirection(sourse: self.requestItems[i], destination: self.requestItems[i+1], transportation:self.requestItems[i].transportType, date: .departure(date))
                    }catch{
                        throw error
                    }
                    let sourseDate = date
                    date += route.expectedTravelTime
                    let item = PointItem(item: self.requestItems[i] as FixedItem, index: index,isEnd: i == 0)
                    items.append(item)
                    index += 1
                    let sectionItem = SectionItem(route: route, sourse: self.requestItems[i], destination: self.requestItems[i+1],sourseDate:sourseDate,destinationDate:date)
                    date += self.requestItems[i+1].stayTime!
                    items.append(sectionItem)
                }
            }
            if let last = self.requestItems.last{
                let item = PointItem(item: last as FixedItem, index: index,isEnd: true)
                items.append(item)
                index += 1
            }
        case .arrive(var date):
            var index = self.requestItems.count
            for i in (0..<self.requestItems.count-1).reversed(){
                if self.requestItems[i].transportType == .transit{
                    let response: MKDirections.ETAResponse
                    do{
                        response = try await MapTools.getETA(sourse: self.requestItems[i], destination: self.requestItems[i+1], transportation:self.requestItems[i].transportType, date: .arrive(date))
                    }catch{
                        throw error
                    }
                    let item = PointItem(item: self.requestItems[i+1] as FixedItem, index: index,isEnd: i == 0)
                    items.insert(item, at: 0)
                    let timeDifference = date.timeIntervalSince(response.expectedArrivalDate)
                    item.stayTime! += timeDifference
                    date = response.expectedDepartureDate
                    index -= 1
                    let sectionItem = SectionItem(response: response)
                    date -= self.requestItems[i].stayTime!
                    items.insert(sectionItem, at: 0)
                }else{
                    let route:MKRoute
                    do{
                        route = try await MapTools.getDirection(sourse: self.requestItems[i], destination: self.requestItems[i+1], transportation:self.requestItems[i].transportType, date: .arrive(date))
                    }catch{
                        throw error
                    }
                    let destinationDate = date
                    date -= route.expectedTravelTime
                    let item = PointItem(item: self.requestItems[i+1] as FixedItem, index: index)
                    items.insert(item, at: 0)
                    index -= 1
                    let sectionItem = SectionItem(route: route, sourse: self.requestItems[i], destination: self.requestItems[i+1],sourseDate:date,destinationDate:destinationDate)
                    date -= self.requestItems[i].stayTime!
                    items.insert(sectionItem, at: 0)
                }
            }
            if let first = self.requestItems.first{
                let item = PointItem(item: first as FixedItem, index: index)
                items.insert(item, at: 0)
                index -= 1
            }
        }
    }
}

class Block{
    var items=[ItemProtocol]()
    var transportType: MKDirectionsTransportType
    //view用
    var isOpened = false
    
    var count: Int{
        return items.count
    }
    var isFixed: Bool{
        return items.count <= 1
    }
    
    var first: ItemProtocol?{
        if let first = items.first{
            return first
        }else{
            return nil
        }
    }
    
    init(items:[ItemProtocol],transportType:MKDirectionsTransportType) {
        self.transportType = transportType
        self.items = items
        
    }
    func append(item:ItemProtocol){
        items.append(item)
    }
    func insert(item:ItemProtocol,at index: Int){
        items.insert(item, at: index)
    }
    
    func replace(item:ItemProtocol, at index:Int){
        items[index] = item
    }
    func get(at index: Int)->ItemProtocol{
        return items[index]
    }
    func firstIndex(item target: ItemProtocol?)->Int{
        for (i,item) in items.enumerated(){
            if let item = item as? FixedItem,
               let target = target as? FixedItem,
               target === item{
                return i
            }else if let item = item as? SelectableItem,
                     let target = target as? SelectableItem,
                     target === item{
                return i
            }else if let item = item as? NilItem,
                     let target = target as? NilItem,
                     target === item{
                return i
            }
        }
        return -1
    }
    func remove(at index:Int) ->ItemProtocol?{
        return items.remove(at: index)
    }
}

protocol ItemProtocol{
    var name: String? { get set }
    var stayTime: TimeInterval? { get set }
    var pointOfInterestCategory: MKPointOfInterestCategory? { get set }
    func encode()->Data?
}

extension ItemProtocol{
    static func decode(data: Data)->ItemProtocol?{
        if let codableItem = try? JSONDecoder().decode(CodableItem.self, from: data){
            if let codableCoordinate = codableItem.coordinate{
                let coordinate = CLLocationCoordinate2D(latitude: codableCoordinate.latitude, longitude: codableCoordinate.longitude)
                let item = FixedItem(coordinate: coordinate, name: codableItem.name, stayTime: codableItem.stayTime!)
                if let url = codableItem.url{
                    item.url = URL(string: url)
                }
                item.phoneNumber = codableItem.phoneNumber
                item.officialName = codableItem.officialName
                if let pointOfInterestCategory = codableItem.pointsOfInterestCategory{
                    item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: pointOfInterestCategory)
                }
                return item
            }else if let  name = codableItem.name{
                let item = SelectableItem(name: name, stayTime: codableItem.stayTime!)
                if let pointOfInterestCategory = codableItem.pointsOfInterestCategory{
                    item.pointOfInterestCategory = MKPointOfInterestCategory(rawValue: pointOfInterestCategory)
                }
                return item
            }else{
                let item = NilItem()
                return item
            }
        }else{
            return nil
        }
    }
}

class FixedItem: MKMapItem, ItemProtocol{
    var officialName: String?{
        get{
            return super.name
        }
        set{
            super.name = newValue
        }
    }
    private var nickName:String?
    override var name: String?{
        get{
            if let name = nickName{
                return name
            }else{
                return super.name
            }
        }
        set{
            if super.name == nil{
                super.name = newValue
            }
            self.nickName = newValue
        }
    }
    
    override var pointOfInterestCategory: MKPointOfInterestCategory?{
        get{
            return super.pointOfInterestCategory
        }
        set{
            super.pointOfInterestCategory = newValue
        }
    }
    var stayTime: TimeInterval?
    var coordinate:CLLocationCoordinate2D{
        return placemark.location!.coordinate
    }
    
    init(item: MKMapItem,stayTime:TimeInterval?) {
        super.init(placemark: item.placemark)
        self.stayTime = stayTime
        if let fixedItem = item as? FixedItem{
            self.officialName = fixedItem.officialName
            self.name = fixedItem.name
        }else{
            self.name = item.name
        }
        self.timeZone = item.timeZone
        self.url = item.url
        self.phoneNumber = item.phoneNumber
        self.pointOfInterestCategory = item.pointOfInterestCategory
    }
    init(placemark: MKPlacemark,name:String?,stayTime:TimeInterval?) {
        super.init(placemark: placemark)
        self.stayTime = stayTime
        self.name = name
    }
    init(coordinate: CLLocationCoordinate2D,name:String?,stayTime:TimeInterval?){
        let placemark = MKPlacemark(coordinate: coordinate)
        super.init(placemark: placemark)
        self.stayTime = stayTime
        self.name = name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(){
        super.init()
    }
    func encode()->Data?{
        let codableCoordinate = CodableItem.CodableCoordinate(latitude: self.placemark.coordinate.latitude, longitude: self.placemark.coordinate.longitude)
        let codableItem = CodableItem(coordinate: codableCoordinate, name: name, officialName: officialName, url: url?.absoluteString, phoneNumber: phoneNumber, pointsOfInterestCategory: pointOfInterestCategory?.rawValue, stayTime: stayTime)
        if let data = try? JSONEncoder().encode(codableItem) {
            return data
        }else{
            return nil
        }
    }
}
    
class SelectableItem:ItemProtocol{
    var name: String?
    var stayTime: TimeInterval?
    var pointOfInterestCategory: MKPointOfInterestCategory?
    init(name:String,stayTime:TimeInterval, pointOfInterestCategory:MKPointOfInterestCategory?=nil) {
        self.name = name
        self.stayTime = stayTime
        self.pointOfInterestCategory = pointOfInterestCategory
    }
    func fix(coordinate:CLLocationCoordinate2D)->FixedItem{
        let item = FixedItem(coordinate: coordinate, name: name, stayTime: stayTime)
        return item
    }
    func encode()->Data? {
        let codableItem =  CodableItem(name:name,pointsOfInterestCategory:pointOfInterestCategory?.rawValue,stayTime: stayTime)
        if let data = try? JSONEncoder().encode(codableItem) {
            return data
        }else{
            return nil
        }
    }
}

class NilItem:ItemProtocol{
    var name: String? = nil
    var stayTime: TimeInterval? = nil
    var pointOfInterestCategory: MKPointOfInterestCategory? = nil
    func encode()->Data?{
        let codableItem = CodableItem()
        if let data = try? JSONEncoder().encode(codableItem) {
            return data
        }else{
            return nil
        }
    }
}

class RequestItem:FixedItem{
    var transportType:MKDirectionsTransportType = .any
    
    init(fixedItem: FixedItem, transportType:MKDirectionsTransportType) {
        super.init(item: fixedItem, stayTime: fixedItem.stayTime)
        self.transportType = transportType
    }
    init(mapItem: MKMapItem,stayTime:TimeInterval, transportType:MKDirectionsTransportType) {
        super.init(item: mapItem, stayTime: stayTime)
        self.transportType = transportType
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(){
        super.init()
    }
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

protocol ResultProtocol{}

class PointItem:FixedItem, ResultProtocol{
    var index:Int = 0
    var isEnd:Bool = false
    init(item: FixedItem, index:Int,isEnd:Bool=false, stayTime:TimeInterval?=nil) {
        if let stayTime = stayTime{
            super.init(item: item, stayTime: stayTime)
        }else{
            super.init(item: item, stayTime: item.stayTime!)
        }
        self.index = index
        self.isEnd = isEnd
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(){
        super.init()
    }
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class SectionItem:ResultProtocol{
    let sourse:MKMapItem
    let destination:MKMapItem
    var isToggled: Bool = false
    var steps:[StepProtocol]
    var transportType:MKDirectionsTransportType
    
    init(route:MKRoute,sourse:MKMapItem,destination:MKMapItem,sourseDate:Date,destinationDate:Date) {
        self.sourse = sourse
        self.destination = destination
        self.transportType = route.transportType
        
        steps = [StepProtocol]()
        let firstStep = EdgeStep(name: sourse.name!, enumDate: .departure(sourseDate),isEstimated: false)
        steps.append(firstStep)
        steps.append(contentsOf: Array(route.steps[1..<route.steps.count]))
        let lastStep = EdgeStep(name: destination.name!, enumDate: .arrive(destinationDate),isEstimated: false)
        steps.append(lastStep)
    }
    
    init(response:MKDirections.ETAResponse) {
        self.sourse = response.source
        self.destination = response.destination
        self.transportType = response.transportType
        
        steps = [StepProtocol]()
        let firstStep = EdgeStep(name: sourse.name!, enumDate: .departure(response.expectedDepartureDate),isEstimated: true)
        steps.append(firstStep)
        //TODO
        let transitStep = TransitStep()
        steps.append(transitStep)
        let lastStep = EdgeStep(name: destination.name!, enumDate: .arrive(response.expectedArrivalDate),isEstimated: true)
        steps.append(lastStep)
    }
    
}
protocol StepProtocol {}
extension MKRoute.Step: StepProtocol{}

class EdgeStep:StepProtocol{
    let name: String
    let enumDate: EnumDate
    let isEstimated:Bool
    init(name:String,enumDate:EnumDate,isEstimated:Bool){
        self.name = name
        self.enumDate = enumDate
        self.isEstimated = isEstimated
    }
}
class TransitStep:StepProtocol{
    init(){
    }
}
class CodableItem:Codable{
    class CodableCoordinate:Codable{
        let latitude:Double
        let longitude:Double
        init(latitude:Double,longitude:Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    let coordinate:CodableCoordinate?
    let name:String?
    let officialName:String?
    let url:String?
    let phoneNumber:String?
    let pointsOfInterestCategory:String?
    let stayTime:TimeInterval?
    init(coordinate:CodableCoordinate?=nil,name:String?=nil,officialName:String?=nil, url:String?=nil,phoneNumber:String?=nil,pointsOfInterestCategory:String?=nil,stayTime:TimeInterval?=nil) {
        self.coordinate  = coordinate
        self.name = name
        self.officialName = officialName
        self.url = url
        self.phoneNumber = phoneNumber
        self.pointsOfInterestCategory = pointsOfInterestCategory
        self.stayTime = stayTime
        
    }
}

class Favorites{
    var items = [FixedItem]()
    var count: Int{
        return items.count
    }
    
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let codableItems = try? JSONDecoder().decode([CodableItem].self, from: data) {
            for codableItem in codableItems{
                let coordinate = CLLocationCoordinate2D(latitude: codableItem.coordinate!.latitude, longitude: codableItem.coordinate!.longitude)
                let item = FixedItem(coordinate: coordinate, name: codableItem.name, stayTime: codableItem.stayTime!)
                self.items.append(item)
            }
        }
    }
    func add(item:FixedItem){
        items.append(item)
        save()
    }
    func get(at index:Int)->FixedItem{
        return items[index]
    }
    func delete(item:FixedItem){
        if let index = self.firstIndex(item: item){
            items.remove(at: index)
        }
    }
    func remove(at index:Int){
        items.remove(at: index)
        save()
    }
    func changeOrder(from:Int,to:Int){
        let item = items.remove(at: from)
        items.insert(item, at: to)
        save()
    }
    func firstIndex(item:MKMapItem)->Int?{
        return items.firstIndex(where: {($0.coordinate.latitude == item.placemark.coordinate.latitude)&&($0.coordinate.longitude == item.placemark.coordinate.longitude)})
    }
    
    func save(){
        var codableItems = [CodableItem]()
        for item in items{
            let codableCoordinate = CodableItem.CodableCoordinate(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            let codableItem = CodableItem(coordinate: codableCoordinate, name: item.name!, officialName: item.officialName, url: item.url?.absoluteString, phoneNumber: item.phoneNumber, pointsOfInterestCategory: item.pointOfInterestCategory?.rawValue, stayTime: item.stayTime!)
            codableItems.append(codableItem)
        }
        
        if let data = try? JSONEncoder().encode(codableItems) {
            UserDefaults.standard.set(data, forKey: "favorites")
        }
    }
}



class MapTools{
    enum Result<T> {
        case success(T)
        case failure(Error)
    }
    static func getDirection(sourse: MKMapItem, destination: MKMapItem, transportation:MKDirectionsTransportType,date customDate:EnumDate) async throws -> MKRoute
    {
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourse
        directionRequest.destination = destination
        switch customDate {
        case .departure(let date):
            directionRequest.departureDate = date
        case .arrive(let date):
            directionRequest.arrivalDate = date
        }
        directionRequest.transportType = transportation
        let directions = MKDirections(request: directionRequest)
        do {
            let directionResponse = try await directions.calculate()
            return directionResponse.routes[0]
            // directionResponseを使用する
        } catch {
            let customError = CustomError.fromGeneralError(description: error.localizedDescription)
            throw customError
        }
    }
    static func getETA(sourse: MKMapItem, destination: MKMapItem, transportation:MKDirectionsTransportType,date customDate:EnumDate) async throws -> MKDirections.ETAResponse
    {
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourse
        directionRequest.destination = destination
        switch customDate {
        case .departure(let date):
            directionRequest.departureDate = date
        case .arrive(let date):
            directionRequest.arrivalDate = date
        }
        directionRequest.transportType = transportation
        let directions = MKDirections(request: directionRequest)
        do {
            return try await directions.calculateETA()
            // directionResponseを使用する
        } catch {
            let customError = CustomError.fromGeneralError(description: error.localizedDescription)
            throw customError
        }
    }
    
    static func distanceBetween(mapItem1: FixedItem, mapItem2: FixedItem) -> CLLocationDistance? {
        let location1 = CLLocation(latitude: mapItem1.placemark.coordinate.latitude, longitude: mapItem1.placemark.coordinate.longitude)
        let location2 = CLLocation(latitude: mapItem2.placemark.coordinate.latitude, longitude: mapItem2.placemark.coordinate.longitude)
        
        return location1.distance(from: location2)
    }
    
    static func search(query: String, region: MKCoordinateRegion) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems
        } catch {
            let customError = CustomError.fromGeneralError(description: error.localizedDescription)
            throw customError
        }
    }
    
    static func getAddress(from mapItem: MKMapItem) async throws -> String {
        guard let location = mapItem.placemark.location else {
            throw CustomError.any
        }

        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let postalCode = placemark.postalCode ?? ""
                let administrativeArea = placemark.administrativeArea ?? ""
                let locality = placemark.locality ?? ""
                let thoroughfare = placemark.thoroughfare ?? ""
                let subThoroughfare = placemark.subThoroughfare ?? ""
                
                // 改行を含む住所文字列を作成
                let address = "\(postalCode)\n\(administrativeArea)\(locality)\n\(thoroughfare)\(subThoroughfare)"
                return address
            } else {
                throw CustomError.notFound
            }
        } catch {
            let customError = CustomError.fromGeneralError(description: error.localizedDescription)
            throw customError
        }
    }
}



class CustomAnnotation: MKPointAnnotation {
    let glyphText: String?
    let image: UIImage?
    let color:UIColor

    init(coordinate: CLLocationCoordinate2D, title: String?, glyphText: String?, category:MKPointOfInterestCategory?) {
        self.glyphText = glyphText
        if let category = category{
            self.image = category.image
            self.color = category.color
        }else{
            self.image = nil
            self.color = MKPointOfInterestCategory.defaultColor
        }
        super.init()
        self.coordinate = coordinate
        self.title = title
            
    }
    init(coordinate: CLLocationCoordinate2D, title: String?, glyphText: String?, image:UIImage?,color:UIColor?) {
        self.glyphText = glyphText
        self.image = image
        if let color = color{
            self.color = color
        }else{
            self.color = UIColor.systemPink
        }
        super.init()
        self.coordinate = coordinate
        self.title = title
    }
}

class CustomPolyline:MKPolyline{
    var color:UIColor = .tintColor
}

enum CustomError: Error {
    case notAuthorized
    case tooManyRequest
    case offLine
    case notFound
    case any
    case notAvailable
    
    var text:String{
        switch self {
        case .notAuthorized:
            return "位置情報の利用が許可されていません。iPhoneの\"設定\"から位置情報の利用を許可してください。"
        case .tooManyRequest:
            return "検索回数が上限に達しました。時間をおいて再度検索してください。\"設定\"から\"検索のサジェスト\"をオフにすると改善される可能性があります。"
        case .offLine:
            return "インターネットへの接続に問題があります。iPhoneの\"設定\"から\"Wi-Fi\"もしくは\"モバイルデータ通信\"をご確認ください。"
        case .notFound:
            return "該当する情報が存在しません。"
        case .notAvailable:
            return "経路情報を取得できません。まだ対応していない日付の可能性があります。"
        case .any:
            return ""
        }
    }
    static func fromGeneralError(description:String)->CustomError{
        if description == "The operation couldn’t be completed. (MKErrorDomain error 3.)"{
            return .tooManyRequest
        }else if description=="The operation couldn’t be completed. (MKErrorDomain error 4.)"{
            return .tooManyRequest
        }else if description=="Directions Not Available"{
            return .notAvailable
        }else if (description=="インターネット接続がオフラインのようです。" )||( description=="リクエストがタイムアウトになりました。"){
            return .offLine
        }else{
            return .any
        }
    }
}
struct DirectionParam {
    let origin:CLLocationCoordinate2D
    let destination:CLLocationCoordinate2D
    let depatureTime:Date
}
