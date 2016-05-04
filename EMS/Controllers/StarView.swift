//
//  StarView.swift
//  EMS
//
//  Created by Jobb on 02.10.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class StarView : UIView {
    
    @IBInspectable var starSize : CGFloat = 44.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var starColor : UIColor = UIColor.lightGrayColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var alwaysTint : Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var hidden : Bool {
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
        
        let frame = self.bounds
       
        let minFrame : CGFloat = min(frame.width, frame.height)
        
        let size = min(minFrame, starSize)
        
        let bezierPath = UIBezierPath()
        
        bezierPath.moveToPoint(CGPoint(x: frame.width/2.0, y: frame.height/2 - size/2))
        bezierPath.addLineToPoint(CGPoint(x: frame.width/2 + size * 0.3, y: frame.height/2 + size/2))
        bezierPath.addLineToPoint(CGPoint(x: frame.width/2 - size/2, y: frame.height/2 - size * 0.3 / 2))
        bezierPath.addLineToPoint(CGPoint(x: frame.width/2 + size/2, y: frame.height/2 - size * 0.3 / 2))
        bezierPath.addLineToPoint(CGPoint(x: frame.width/2 - size * 0.3, y: frame.height/2 + size/2))
        bezierPath.addLineToPoint(CGPoint(x: frame.width/2.0, y: frame.height/2 - size/2))
        
        if (alwaysTint) {
            tintColor.setFill()
        } else {
            starColor.setFill()
        }
        
        bezierPath.fill()
        
        super.drawRect(rect)
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: starSize, height: starSize)
    }
    
    override func prepareForInterfaceBuilder() {
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)
    }
  
}
