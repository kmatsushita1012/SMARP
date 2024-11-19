//
//  LoadingAlert.swift
//  FesManaging
//
//  Created by 松下和也 on 2024/03/11.
//

import UIKit

class LoadingAlert: UIView {
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "処理中..."
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.systemGray5
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false // 影を表示するためにfalseに設定
                
        // 影の設定
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 2
        
        self.addSubview(activityIndicatorView)
        self.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10),
            messageLabel.topAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimating() {
        activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
    }
}

