//
//  SectionTableViewCell.swift
//  MapEX
//
//  Created by 松下和也 on 2024/04/10.
//

import UIKit
import MapKit

class GuideTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var foreView: UIView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet var circleView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func config(step:StepProtocol,color:UIColor){
        if let step = step as? MKRoute.Step{
            titleLabel.text = step.instructions
            titleLabel.numberOfLines = 0
            timeLabel.isHidden = true
            foreView.isHidden = false
            backView.isHidden = false
        }else if let step = step as? EdgeStep{
            switch step.enumDate{
            case .departure(let date):
                switch step.isEstimated {
                case true:
                    titleLabel.text = "予想出発時刻"
                case false:
                    titleLabel.text = "出発"
                }
                
                foreView.isHidden = true
                backView.isHidden = false
                timeLabel.isHidden = false
                timeLabel.text = date.textOfHHMM
            case .arrive(let date):
                switch step.isEstimated{
                case true:
                    titleLabel.text = "予想到着時刻"
                case false:
                    titleLabel.text = "到着"
                }
                foreView.isHidden = false
                backView.isHidden = true
                timeLabel.isHidden = false
                timeLabel.text = date.textOfHHMM
            }
        }
        self.foreView.backgroundColor = color
        self.backView.backgroundColor = color
        self.circleView.backgroundColor = color
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }
}
