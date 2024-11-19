//
//  TransportationTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/10.
//

import UIKit
import MapKit

class SectionTableViewCell: UITableViewCell,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toggleButton: UIButton!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    private var item: SectionItem?
    private var indexPath: IndexPath?
    private var delegate: ItineraryDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "GuideTableViewCell", bundle: nil), forCellReuseIdentifier: "GuideTableViewCell")
        tableView.register(UINib(nibName: "TransitTableViewCell", bundle: nil), forCellReuseIdentifier: "TransitTableViewCell")
        tableView.isScrollEnabled = false
        if item?.transportType == .transit{
            toggleButton.isHidden = true
            toggleButton.isEnabled = false
        }
    }
    
    func config(delegate: ItineraryDelegate,item:SectionItem,indexPath:IndexPath){
        self.delegate = delegate
        self.item = item
        self.indexPath = indexPath
        titleLabel.text = item.transportType.text
//        layoutIfNeeded()
        
        self.toggleButton.isHidden = (item.transportType == .transit)
        if item.isToggled{
            toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        }else{
            toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
        tableView.reloadData()
    }
    
    override func layoutSubviews() {
        if let item = item{
            heightConstraint.constant = CGFloat(44*item.steps.count)
        }
    }
    
    @IBAction func toggleButtonTapped(_ sender: UIButton) {
        item!.isToggled = !item!.isToggled
        if item!.isToggled{
            toggleButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        }else{
            toggleButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        }
        delegate!.reloadRow(at: indexPath!)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let item = item{
            if item.transportType == .transit{
                return 3
            }else if item.isToggled{
                return self.item!.steps.count
            }else{
                return 2
            }
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = item{
            if item.transportType == .transit{
                switch indexPath.item{
                case 0:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "GuideTableViewCell", for: indexPath) as! GuideTableViewCell
                    cell.config(step: item.steps.first!, color: (self.item?.transportType.color)!)
                    return cell
                case 1:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "TransitTableViewCell", for: indexPath) as! TransitTableViewCell
                    if let step = item.steps.first as? EdgeStep{
                        let directionParam = DirectionParam(origin: item.sourse.placemark.coordinate, destination: item.destination.placemark.coordinate, depatureTime: step.enumDate.date)
                        cell.config(delegate: self.delegate!, directionParam: directionParam)
                    }
                    return cell
                case 2:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "GuideTableViewCell", for: indexPath) as! GuideTableViewCell
                    cell.config(step: item.steps.last!, color: (self.item?.transportType.color)!)
                    return cell
                default:
                    break
                }
            }else if item.isToggled{
                let cell = tableView.dequeueReusableCell(withIdentifier: "GuideTableViewCell", for: indexPath) as! GuideTableViewCell
                cell.config(step: item.steps[indexPath.item], color: (self.item?.transportType.color)!)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "GuideTableViewCell", for: indexPath) as! GuideTableViewCell
                switch indexPath.item{
                case 0:
                    cell.config(step: item.steps.first!, color: (self.item?.transportType.color)!)
                case 1:
                    cell.config(step: item.steps.last!, color: (self.item?.transportType.color)!)
                default:
                    break
                }
                return cell
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "GuideTableViewCell", for: indexPath) as! GuideTableViewCell
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
    }
    
}
