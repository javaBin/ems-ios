//
//  TypeLabel.swift
//  EMS
//
//  Created by Jobb on 30.09.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class TypeLabel : UILabel {
    
    @IBInspectable var labelBackgroundColor: UIColor? = UIColor.lightGrayColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }
    
    override func drawRect(rect: CGRect) {
        let cornerRadius = self.bounds.height/4
        let bezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius)
        labelBackgroundColor?.setFill()
        bezierPath.fill()
        super.drawRect(rect)
    }
    
    override func intrinsicContentSize() -> CGSize {
        let size = super.intrinsicContentSize()
        return CGSize(width: size.width + size.height / 2, height: size.height + size.height / 4.0)
    }
    
    override func prepareForInterfaceBuilder() {
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }   
}