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
    
    override func drawRect(rect: CGRect) {
        let bezierPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 3.0)
        labelBackgroundColor?.setFill()
        bezierPath.fill()
        super.drawRect(rect)
    }
    
    override func intrinsicContentSize() -> CGSize {
        let size = super.intrinsicContentSize()
        return CGSize(width: size.width + 4, height: size.height + 2)
    }
    
}