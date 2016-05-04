//
//  HairLineView.swift
//  EMS
//
//  Created by Jobb on 05.10.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class HairLineView : UIView {

    @IBInspectable var lineColor : UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }
    
    
    override func drawRect(rect: CGRect) {
        let bezierPath = UIBezierPath(rect: rect)
        
        lineColor.setFill()
        
        bezierPath.fill()
    }
    
    
    override func intrinsicContentSize() -> CGSize {
        let size = CGSizeMake(CGFloat(0.0), 1.0 / UIScreen.mainScreen().scale)
        return size
    }
    
    override func prepareForInterfaceBuilder() {
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }
}