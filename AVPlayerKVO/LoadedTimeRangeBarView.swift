//
//  LoadedTimeRangeBarView.swift
//  AVPlayerKVO
//
//  Created by Ana Ma on 1/29/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit

class LoadedTimeRangeBarView: UIView {
    
    lazy var loadedTimeRangeIndicatorView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.purple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var indicatorToWidthPercentage: CGFloat = 0.1
    var indicatorWidth: CGFloat = 100.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.loadedTimeRangeIndicatorView)
        self.backgroundColor = UIColor.lightGray
        self.translatesAutoresizingMaskIntoConstraints = false

        let _ = [
        loadedTimeRangeIndicatorView.topAnchor.constraint(equalTo: self.topAnchor),
        loadedTimeRangeIndicatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        loadedTimeRangeIndicatorView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        loadedTimeRangeIndicatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        //loadedTimeRangeIndicatorView.widthAnchor.constraint(equalToConstant: indicatorWidth),
        //loadedTimeRangeIndicatorView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: indicatorToWidthPercentage),
        ].map{$0.isActive = true}
        
        print(indicatorWidth)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

    //var loadedTimeRangeBarView:
    //var loadedTimeRangeIndicatorView:
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
