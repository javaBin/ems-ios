//
//  SessionLevelLineView.swift
//  EMS
//
//  Created by Jobb on 30.09.2015.
//  Copyright © 2015 Chris Searle. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class SessionLevelLineView : UIView {
    
    @IBInspectable var lineWidth: CGFloat = 2{
        didSet {
            setNeedsDisplay()
            if lineWidth % 2 != 0 {
                translation = 0.5
            }
        }
    }
    
    @IBInspectable var lineColor : UIColor = UIColor.blackColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var secondaryLineColor : UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var patternPhase : CGFloat = 5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var translation : CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
    }
    
    
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect);
        
        let context = UIGraphicsGetCurrentContext();
        
        CGContextSetLineWidth(context, lineWidth);
        
        let x = lineWidth / 2.0 + translation
        
        if let color = self.secondaryLineColor {
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            CGContextSetLineDash(context, 0, [self.bounds.height / self.patternPhase, self.bounds.height / self.patternPhase] , 2)
            CGContextMoveToPoint(context, x, 0.0); //start at this point
            CGContextAddLineToPoint(context, x, self.bounds.height); //draw to this point
            CGContextStrokePath(context);
            
            CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
            CGContextSetLineDash(context, self.bounds.height / self.patternPhase, [self.bounds.height / self.patternPhase, self.bounds.height / self.patternPhase] , 2)
            CGContextMoveToPoint(context, x, 0.0); //start at this point
            CGContextAddLineToPoint(context, x, self.bounds.height); //draw to this point
            CGContextStrokePath(context);
        } else {
            CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
            CGContextMoveToPoint(context, x, 0.0); //start at this point
            CGContextAddLineToPoint(context, x, self.bounds.height); //draw to this point
            CGContextStrokePath(context);
        }
        
        
        
    }
    
    override func intrinsicContentSize() -> CGSize {
        let size = CGSizeMake(lineWidth + translation, 0)
        return size
    }
    
    override func prepareForInterfaceBuilder() {
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
        setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Horizontal)
    }
}
