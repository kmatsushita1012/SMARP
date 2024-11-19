//
//  CustomFloatingPanelLayout.swift
//  MapEX
//
//  Created by 松下和也 on 2024/05/08.
//

import UIKit
import FloatingPanel

class CustomFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanel.FloatingPanelPosition{
        return .bottom
    }
    
    var initialState: FloatingPanel.FloatingPanelState{
        return .hidden
    }
    
    var anchors: [FloatingPanel.FloatingPanelState : FloatingPanel.FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 130.0, edge: .bottom, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: UIScreen.main.bounds.height/2+32, edge: .top, referenceGuide: .safeArea),
        ]
    }
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.0
    }

}

